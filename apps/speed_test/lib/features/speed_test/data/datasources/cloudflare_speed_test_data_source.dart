import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:speed_test/features/speed_test/data/datasources/measurement_support.dart';
import 'package:speed_test/features/speed_test/data/datasources/speed_test_remote_data_source.dart';
import 'package:speed_test/features/speed_test/domain/entities/network_info.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_config.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_progress.dart';
import 'package:speed_test/features/speed_test/domain/failures.dart';

/// Measures throughput against Cloudflare's public speed test endpoints.
///
/// The download endpoint returns as many bytes as requested, the upload
/// endpoint accepts a request body, and the metadata endpoint describes the
/// edge and client network. Cloudflare's anycast routing already sends every
/// request to the closest data center; the parallel streams and sustained-rate
/// sampling here measure peak throughput on that edge instead of the ramp-up
/// of a single TCP connection.
@immutable
final class CloudflareSpeedTestDataSource implements SpeedTestRemoteDataSource {
  /// Creates the data source.
  ///
  /// The endpoints and client factory are injectable for tests and alternative
  /// deployments; the defaults target Cloudflare's global network.
  new({
    Uri? downloadUri,
    Uri? uploadUri,
    Uri? metaUri,
    HttpClient Function()? clientFactory,
  }) : _downloadUri = downloadUri ?? _defaultDownloadUri,
       _uploadUri = uploadUri ?? _defaultUploadUri,
       _metaUri = metaUri ?? _defaultMetaUri,
       _clientFactory = clientFactory ?? HttpClient.new;

  static final Uri _defaultDownloadUri = Uri.https(
    'speed.cloudflare.com',
    '/__down',
  );
  static final Uri _defaultUploadUri = Uri.https(
    'speed.cloudflare.com',
    '/__up',
  );
  static final Uri _defaultMetaUri = Uri.https('speed.cloudflare.com', '/meta');
  static final Uri _defaultTraceUri = Uri.https(
    'speed.cloudflare.com',
    '/cdn-cgi/trace',
  );

  /// A block size the download endpoint serves reliably.
  ///
  /// Cloudflare rejects some arbitrary sizes with HTTP 403 (for example
  /// 12.5 MB), so every request is made in known-good blocks.
  static const int _downloadChunkBytes = 5000000;

  /// A block size the upload endpoint accepts reliably.
  static const int _uploadChunkBytes = 5000000;

  /// The payload sub-chunk written per socket flush.
  static const int _payloadChunkBytes = 64 * 1024;

  final Uri _downloadUri;
  final Uri _uploadUri;
  final Uri _metaUri;
  final Uri _traceUri = _defaultTraceUri;
  final HttpClient Function() _clientFactory;

  @override
  Stream<SpeedTestProgress> runTest(SpeedTestConfig config) async* {
    final client = _clientFactory()
      ..connectionTimeout = config.timeout
      ..maxConnectionsPerHost = config.connections;
    try {
      final server = await _readNetworkInfo(client, config);
      yield SpeedTestProgress(
        phase: SpeedTestPhase.connecting,
        progress: 0.01,
        server: server,
      );

      var latency = 0.0;
      var jitter = 0.0;
      await for (final progress in _measureLatency(client, config, server)) {
        latency = progress.latencyMs ?? latency;
        jitter = progress.jitterMs ?? jitter;
        yield progress;
      }

      var download = 0.0;
      await for (final progress in _measureDownload(
        client,
        config,
        server,
        latency: latency,
        jitter: jitter,
      )) {
        download = progress.downloadBps ?? download;
        yield progress;
      }

      var upload = 0.0;
      await for (final progress in _measureUpload(
        client,
        config,
        server,
        latency: latency,
        jitter: jitter,
      )) {
        upload = progress.uploadBps ?? upload;
        yield progress;
      }

      yield SpeedTestProgress(
        phase: SpeedTestPhase.completed,
        progress: 1,
        liveBps: download,
        downloadBps: download,
        uploadBps: upload,
        latencyMs: latency,
        jitterMs: jitter,
        server: server,
      );
    } on SpeedTestFailure {
      rethrow;
    } on TimeoutException {
      throw const SpeedTestTimeoutFailure();
    } on Object catch (error) {
      throw NetworkFailure(details: '$error');
    } finally {
      client.close(force: true);
    }
  }

  /// Streams latency updates, discarding the first (handshake) round trip.
  Stream<SpeedTestProgress> _measureLatency(
    HttpClient client,
    SpeedTestConfig config,
    NetworkInfo? server,
  ) async* {
    final samples = <double>[];
    for (var attempt = 0; attempt <= config.latencySamples; attempt++) {
      final sample = await _ping(client, config);
      if (attempt == 0) {
        continue;
      }
      samples.add(sample);
      yield SpeedTestProgress(
        phase: SpeedTestPhase.latency,
        progress: 0.02 + 0.16 * samples.length / config.latencySamples,
        latencyMs: _median(samples),
        jitterMs: _jitter(samples),
        server: server,
      );
    }
    if (samples.isEmpty) {
      throw const NetworkFailure(details: 'No latency samples were collected.');
    }
  }

  Future<double> _ping(HttpClient client, SpeedTestConfig config) async {
    final uri = _downloadUri.replace(
      queryParameters: const <String, String>{'bytes': '0'},
    );
    final stopwatch = Stopwatch()..start();
    try {
      final request = await client.getUrl(uri).timeout(config.timeout);
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      final response = await request.close().timeout(config.timeout);
      await response.drain<void>().timeout(config.timeout);
      if (response.statusCode != HttpStatus.ok) {
        throw ServerFailure(statusCode: response.statusCode);
      }
      stopwatch.stop();
      return stopwatch.elapsedMicroseconds / 1000;
    } on SpeedTestFailure {
      rethrow;
    } on TimeoutException {
      throw const SpeedTestTimeoutFailure();
    } on Object catch (error) {
      throw NetworkFailure(details: '$error');
    }
  }

  /// Downloads on several connections at once and reports the combined rate.
  Stream<SpeedTestProgress> _measureDownload(
    HttpClient client,
    SpeedTestConfig config,
    NetworkInfo? server, {
    required double latency,
    required double jitter,
  }) {
    final totalBytes = config.downloadBytes;
    final chunkCount = math.max(1, (totalBytes / _downloadChunkBytes).ceil());
    final expectedBytes = chunkCount * _downloadChunkBytes;
    final connections = math.max(1, math.min(config.connections, chunkCount));
    final sampler = ThroughputSampler();
    late final StreamController<SpeedTestProgress> controller;
    var received = 0;
    var cancelled = false;
    var lastReportMicros = 0;
    Timer? ticker;

    void emit({required bool finalReport}) {
      if (controller.isClosed || cancelled) {
        return;
      }
      final micros = sampler.elapsedMicros;
      if (!finalReport && micros - lastReportMicros < reportIntervalMicros) {
        return;
      }
      final smoothed =
          sampler.sample(received, force: finalReport) ?? sampler.smoothedBps;
      final sustained = sampler.sustainedBps;
      final bps = finalReport && sustained > 0
          ? sustained
          : sampler.averageBps(received);
      final fraction = (received / expectedBytes).clamp(0.0, 1.0);
      controller.add(
        SpeedTestProgress(
          phase: SpeedTestPhase.download,
          progress: 0.18 + 0.42 * fraction,
          liveBps: smoothed,
          downloadBps: bps,
          latencyMs: latency,
          jitterMs: jitter,
          server: server,
        ),
      );
      lastReportMicros = micros;
    }

    Future<void> run() async {
      sampler.start();
      lastReportMicros = sampler.elapsedMicros;
      ticker = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => emit(finalReport: false),
      );
      try {
        final workers = <Future<void>>[];
        for (var index = 0; index < connections; index++) {
          workers.add(
            _downloadWorker(
              client: client,
              config: config,
              chunkCount: chunkCount,
              connections: connections,
              offset: index,
              onBytes: (count) => received += count,
              isCancelled: () => cancelled,
            ),
          );
        }
        await Future.wait(workers);
        ticker?.cancel();
        if (cancelled) {
          await controller.close();
          return;
        }
        sampler.stop();
        if (received == 0) {
          throw const NetworkFailure(details: 'The download returned no data.');
        }
        emit(finalReport: true);
        await controller.close();
      } on Object catch (error, stackTrace) {
        cancelled = true;
        ticker?.cancel();
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
          await controller.close();
        }
      }
    }

    controller = StreamController<SpeedTestProgress>(
      onListen: () => unawaited(run()),
      onCancel: () {
        cancelled = true;
        ticker?.cancel();
      },
    );
    return controller.stream;
  }

  Future<void> _downloadWorker({
    required HttpClient client,
    required SpeedTestConfig config,
    required int chunkCount,
    required int connections,
    required int offset,
    required void Function(int bytes) onBytes,
    required bool Function() isCancelled,
  }) async {
    for (var index = offset; index < chunkCount; index += connections) {
      if (isCancelled()) {
        return;
      }
      final uri = _downloadUri.replace(
        queryParameters: <String, String>{'bytes': '$_downloadChunkBytes'},
      );
      final response = await _openWithRetry(client, uri, config);
      await for (final chunk in response.timeout(config.timeout)) {
        if (isCancelled()) {
          return;
        }
        onBytes(chunk.length);
      }
    }
  }

  Future<HttpClientResponse> _openWithRetry(
    HttpClient client,
    Uri uri,
    SpeedTestConfig config,
  ) async {
    try {
      return await _open(client, uri, config);
    } on ServerFailure {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return await _open(client, uri, config);
    }
  }

  /// Uploads on several connections at once and reports the combined rate.
  Stream<SpeedTestProgress> _measureUpload(
    HttpClient client,
    SpeedTestConfig config,
    NetworkInfo? server, {
    required double latency,
    required double jitter,
  }) {
    final totalBytes = config.uploadBytes;
    final chunkCount = math.max(1, (totalBytes / _uploadChunkBytes).ceil());
    final expectedBytes = chunkCount * _uploadChunkBytes;
    final connections = math.max(1, math.min(config.connections, chunkCount));
    final sampler = ThroughputSampler();
    late final StreamController<SpeedTestProgress> controller;
    var sent = 0;
    var cancelled = false;
    var lastReportMicros = 0;
    Timer? ticker;

    void emit({required bool finalReport}) {
      if (controller.isClosed || cancelled) {
        return;
      }
      final micros = sampler.elapsedMicros;
      if (!finalReport && micros - lastReportMicros < reportIntervalMicros) {
        return;
      }
      final smoothed =
          sampler.sample(sent, force: finalReport) ?? sampler.smoothedBps;
      final sustained = sampler.sustainedBps;
      final bps = finalReport && sustained > 0
          ? sustained
          : sampler.averageBps(sent);
      final fraction = (sent / expectedBytes).clamp(0.0, 1.0);
      controller.add(
        SpeedTestProgress(
          phase: SpeedTestPhase.upload,
          progress: 0.6 + 0.38 * fraction,
          liveBps: smoothed,
          uploadBps: bps,
          latencyMs: latency,
          jitterMs: jitter,
          server: server,
        ),
      );
      lastReportMicros = micros;
    }

    Future<void> run() async {
      sampler.start();
      lastReportMicros = sampler.elapsedMicros;
      ticker = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => emit(finalReport: false),
      );
      try {
        final payload = randomPayload(_payloadChunkBytes);
        final workers = <Future<void>>[];
        for (var index = 0; index < connections; index++) {
          workers.add(
            _uploadWorker(
              client: client,
              config: config,
              chunkCount: chunkCount,
              connections: connections,
              offset: index,
              payload: payload,
              onBytes: (count) => sent += count,
              isCancelled: () => cancelled,
            ),
          );
        }
        await Future.wait(workers);
        ticker?.cancel();
        if (cancelled) {
          await controller.close();
          return;
        }
        sampler.stop();
        if (sent == 0) {
          throw const NetworkFailure(details: 'The upload sent no data.');
        }
        emit(finalReport: true);
        await controller.close();
      } on Object catch (error, stackTrace) {
        cancelled = true;
        ticker?.cancel();
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
          await controller.close();
        }
      }
    }

    controller = StreamController<SpeedTestProgress>(
      onListen: () => unawaited(run()),
      onCancel: () {
        cancelled = true;
        ticker?.cancel();
      },
    );
    return controller.stream;
  }

  Future<void> _uploadWorker({
    required HttpClient client,
    required SpeedTestConfig config,
    required int chunkCount,
    required int connections,
    required int offset,
    required Uint8List payload,
    required void Function(int bytes) onBytes,
    required bool Function() isCancelled,
  }) async {
    for (var index = offset; index < chunkCount; index += connections) {
      if (isCancelled()) {
        return;
      }
      await _uploadChunk(
        client: client,
        config: config,
        bytes: _uploadChunkBytes,
        payload: payload,
        onBytes: onBytes,
        isCancelled: isCancelled,
      );
    }
  }

  Future<void> _uploadChunk({
    required HttpClient client,
    required SpeedTestConfig config,
    required int bytes,
    required Uint8List payload,
    required void Function(int bytes) onBytes,
    required bool Function() isCancelled,
  }) async {
    final request = await client.postUrl(_uploadUri).timeout(config.timeout);
    request
      ..headers.contentType = ContentType.binary
      ..headers.set(HttpHeaders.cacheControlHeader, 'no-store')
      ..contentLength = bytes;

    var written = 0;
    try {
      while (written < bytes) {
        if (isCancelled()) {
          request.abort();
          return;
        }
        final size = math.min(payload.length, bytes - written);
        request.add(
          size == payload.length
              ? payload
              : Uint8List.sublistView(payload, 0, size),
        );
        written += size;
        onBytes(size);
        await request.flush().timeout(config.timeout);
      }
    } on Object {
      request.abort();
      rethrow;
    }
    if (isCancelled()) {
      request.abort();
      return;
    }

    final response = await request.close().timeout(config.timeout);
    await response.drain<void>().timeout(config.timeout);
    if (response.statusCode < HttpStatus.ok ||
        response.statusCode >= HttpStatus.multipleChoices) {
      throw ServerFailure(statusCode: response.statusCode);
    }
  }

  Future<HttpClientResponse> _open(
    HttpClient client,
    Uri uri,
    SpeedTestConfig config,
  ) async {
    final request = await client.getUrl(uri).timeout(config.timeout);
    request.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    final response = await request.close().timeout(config.timeout);
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw ServerFailure(statusCode: response.statusCode);
    }
    return response;
  }

  /// Reads the data center and client network, tolerating any failure.
  ///
  /// `/meta` is the rich payload, but it is blocked for some clients; the
  /// lightweight `/cdn-cgi/trace` endpoint then supplies the data-center code
  /// and client IP so the UI can still show the edge in use.
  Future<NetworkInfo?> _readNetworkInfo(
    HttpClient client,
    SpeedTestConfig config,
  ) async {
    return await _readMeta(client, config) ?? await _readTrace(client, config);
  }

  Future<NetworkInfo?> _readMeta(
    HttpClient client,
    SpeedTestConfig config,
  ) async {
    try {
      final request = await client.getUrl(_metaUri).timeout(config.timeout);
      final response = await request.close().timeout(config.timeout);
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        return null;
      }
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(config.timeout);
      final decoded = jsonDecode(body);
      if (decoded is! Map<Object?, Object?>) {
        return null;
      }
      return NetworkInfo.fromJson(decoded);
    } on Object {
      return null;
    }
  }

  Future<NetworkInfo?> _readTrace(
    HttpClient client,
    SpeedTestConfig config,
  ) async {
    try {
      final request = await client.getUrl(_traceUri).timeout(config.timeout);
      final response = await request.close().timeout(config.timeout);
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        return null;
      }
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(config.timeout);
      final values = <String, String>{};
      for (final line in body.split('\n')) {
        final separator = line.indexOf('=');
        if (separator > 0) {
          values[line.substring(0, separator)] = line.substring(separator + 1);
        }
      }
      if (values.isEmpty) {
        return null;
      }
      return NetworkInfo(
        ip: values['ip'],
        country: values['loc'],
        colo: values['colo'],
      );
    } on Object {
      return null;
    }
  }

  static double _median(List<double> samples) {
    final sorted = [...samples]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[middle];
    }
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  static double _jitter(List<double> samples) {
    if (samples.length < 2) {
      return 0;
    }
    var total = 0.0;
    for (var index = 1; index < samples.length; index++) {
      total += (samples[index] - samples[index - 1]).abs();
    }
    return total / (samples.length - 1);
  }
}
