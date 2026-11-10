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

/// Measures throughput on Fast.com's Netflix Open Connect network.
///
/// Fast.com first asks `api.fast.com` for a set of nearby Open Connect
/// appliances, then moves bytes directly to the fastest one. Because those
/// appliances sit inside or next to the user's ISP, this is the measurement
/// that produces results comparable to fast.com itself. Every run picks the
/// lowest-latency target from the returned list instead of trusting the
/// server order.
@immutable
final class FastSpeedTestDataSource implements SpeedTestRemoteDataSource {
  /// Creates the data source.
  ///
  /// The API endpoint and client factory are injectable for tests and
  /// alternative deployments; the defaults target Fast.com's public service.
  new({Uri? apiUri, HttpClient Function()? clientFactory})
    : _apiUri = apiUri ?? _defaultApiUri,
      _clientFactory = clientFactory ?? HttpClient.new;

  /// Fast.com's public bootstrap token, published in its web client bundle.
  /// It is not a user credential and no account is involved.
  static const String _publicToken = 'YXNkZmFzZGxmbnNkYWZoYXNkZmhrYWxm';

  static final Uri _defaultApiUri = Uri.https(
    'api.fast.com',
    '/netflix/speedtest/v2',
    const <String, String>{
      'https': 'true',
      'token': _publicToken,
      'urlCount': '5',
    },
  );

  /// The size of the object every Open Connect target serves.
  static const int _targetObjectBytes = 25 * 1024 * 1024;

  /// A block the ranged download endpoint serves reliably.
  static const int _downloadChunkBytes = 5000000;

  /// A body size the upload endpoint accepts reliably.
  static const int _uploadChunkBytes = 5000000;

  /// The payload sub-chunk written per socket flush.
  static const int _payloadChunkBytes = 64 * 1024;

  /// The longest a candidate probe may take while picking the server.
  static const Duration _probeTimeout = Duration(seconds: 3);

  /// The bootstrap call should fail fast so Cloudflare can take over.
  static const Duration _bootstrapTimeout = Duration(seconds: 8);

  final Uri _apiUri;
  final HttpClient Function() _clientFactory;

  @override
  Stream<SpeedTestProgress> runTest(SpeedTestConfig config) async* {
    final client = _clientFactory()
      ..connectionTimeout = config.timeout
      ..maxConnectionsPerHost = math.max(config.connections, 2);
    try {
      final session = await _loadSession(client);
      yield SpeedTestProgress(
        phase: SpeedTestPhase.connecting,
        progress: 0.01,
        server: session.serverFor(session.targets.first),
      );

      final target = await _selectFastestTarget(
        client,
        config,
        session.targets,
      );
      if (target == null) {
        throw const ServerFailure();
      }
      final server = session.serverFor(target);
      yield SpeedTestProgress(
        phase: SpeedTestPhase.latency,
        progress: 0.02,
        server: server,
      );

      var latency = 0.0;
      var jitter = 0.0;
      await for (final progress in _measureLatency(
        client,
        config,
        target,
        server,
      )) {
        latency = progress.latencyMs ?? latency;
        jitter = progress.jitterMs ?? jitter;
        yield progress;
      }

      var download = 0.0;
      await for (final progress in _measureDownload(
        client,
        config,
        target,
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
        target,
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

  Future<_FastSession> _loadSession(HttpClient client) async {
    final request = await client.getUrl(_apiUri).timeout(_bootstrapTimeout);
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/json')
      ..set(HttpHeaders.cacheControlHeader, 'no-store');
    final response = await request.close().timeout(_bootstrapTimeout);
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw ServerFailure(statusCode: response.statusCode);
    }
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(_bootstrapTimeout);
    final decoded = jsonDecode(body);
    if (decoded is! Map<Object?, Object?>) {
      throw const ServerFailure();
    }

    final targetsJson = decoded['targets'];
    if (targetsJson is! List<Object?>) {
      throw const ServerFailure();
    }
    final targets = <_FastTarget>[];
    for (final item in targetsJson) {
      if (item is! Map<Object?, Object?>) {
        continue;
      }
      final url = item['url'];
      if (url is! String) {
        continue;
      }
      final uri = Uri.tryParse(url);
      if (uri == null || uri.scheme != 'https') {
        continue;
      }
      final location = item['location'];
      final locationJson = location is Map<Object?, Object?>
          ? location
          : const <Object?, Object?>{};
      targets.add(
        _FastTarget(
          uri: uri,
          city: _read(locationJson, 'city'),
          country: _read(locationJson, 'country'),
        ),
      );
    }
    if (targets.isEmpty) {
      throw const ServerFailure();
    }

    final clientJson = decoded['client'];
    final clientInfo = clientJson is Map<Object?, Object?>
        ? clientJson
        : const <Object?, Object?>{};
    return _FastSession(
      clientIp: _read(clientInfo, 'ip'),
      isp: _read(clientInfo, 'isp'),
      targets: targets,
    );
  }

  /// Probes every target once and keeps the one with the lowest round trip.
  Future<_FastTarget?> _selectFastestTarget(
    HttpClient client,
    SpeedTestConfig config,
    List<_FastTarget> targets,
  ) async {
    _FastTarget? best;
    var bestMs = double.infinity;
    for (final target in targets) {
      try {
        final sample = await _ping(
          client,
          target,
          config,
          timeout: _probeTimeout,
        );
        if (sample < bestMs) {
          bestMs = sample;
          best = target;
        }
      } on Object {
        // A single unreachable appliance should not fail the whole run.
        continue;
      }
    }
    return best;
  }

  /// Streams latency samples from the chosen target.
  Stream<SpeedTestProgress> _measureLatency(
    HttpClient client,
    SpeedTestConfig config,
    _FastTarget target,
    NetworkInfo server,
  ) async* {
    // The first request pays for TLS setup and says nothing about latency.
    await _ping(client, target, config);
    final samples = <double>[];
    for (var attempt = 0; attempt < config.latencySamples; attempt++) {
      samples.add(await _ping(client, target, config));
      yield SpeedTestProgress(
        phase: SpeedTestPhase.latency,
        progress: 0.02 + 0.16 * samples.length / config.latencySamples,
        latencyMs: _median(samples),
        jitterMs: _jitter(samples),
        server: server,
      );
    }
  }

  Future<double> _ping(
    HttpClient client,
    _FastTarget target,
    SpeedTestConfig config, {
    Duration? timeout,
  }) async {
    final limit = timeout ?? config.timeout;
    final stopwatch = Stopwatch()..start();
    try {
      final request = await client.postUrl(target.uri).timeout(limit);
      request
        ..contentLength = 0
        ..headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      final response = await request.close().timeout(limit);
      await response.drain<void>().timeout(limit);
      if (response.statusCode < HttpStatus.ok ||
          response.statusCode >= HttpStatus.multipleChoices) {
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

  /// Downloads ranged blocks from the target on several connections.
  Stream<SpeedTestProgress> _measureDownload(
    HttpClient client,
    SpeedTestConfig config,
    _FastTarget target,
    NetworkInfo server, {
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
              target: target,
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
    required _FastTarget target,
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
      final response = await _openRange(
        client,
        target.uri,
        _rangeFor(index),
        config,
      );
      await for (final chunk in response.timeout(config.timeout)) {
        if (isCancelled()) {
          return;
        }
        onBytes(chunk.length);
      }
    }
  }

  /// A range inside the 25 MiB object every target serves. Offsets wrap so a
  /// long run never asks for bytes past the end.
  static String _rangeFor(int index) {
    const span = _targetObjectBytes - _downloadChunkBytes + 1;
    final start = (index * _downloadChunkBytes) % span;
    return 'bytes=$start-${start + _downloadChunkBytes - 1}';
  }

  Future<HttpClientResponse> _openRange(
    HttpClient client,
    Uri uri,
    String range,
    SpeedTestConfig config,
  ) async {
    final request = await client.getUrl(uri).timeout(config.timeout);
    request.headers
      ..set(HttpHeaders.rangeHeader, range)
      ..set(HttpHeaders.cacheControlHeader, 'no-store');
    final response = await request.close().timeout(config.timeout);
    if (response.statusCode != HttpStatus.partialContent &&
        response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw ServerFailure(statusCode: response.statusCode);
    }
    return response;
  }

  /// Uploads blocks to the target on several connections.
  Stream<SpeedTestProgress> _measureUpload(
    HttpClient client,
    SpeedTestConfig config,
    _FastTarget target,
    NetworkInfo server, {
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
              target: target,
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
    required _FastTarget target,
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
        target: target,
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
    required _FastTarget target,
    required int bytes,
    required Uint8List payload,
    required void Function(int bytes) onBytes,
    required bool Function() isCancelled,
  }) async {
    final request = await client.postUrl(target.uri).timeout(config.timeout);
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

  static String? _read(Map<Object?, Object?> json, String key) {
    final value = json[key];
    return value is String && value.isNotEmpty ? value : null;
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

/// One round of API metadata: the client network and nearby targets.
@immutable
final class _FastSession {
  const new({required this.clientIp, required this.isp, required this.targets});

  final String? clientIp;
  final String? isp;
  final List<_FastTarget> targets;

  NetworkInfo serverFor(_FastTarget target) => NetworkInfo(
    ip: clientIp,
    city: target.city,
    country: target.country,
    colo: target.colo,
    organization: isp,
    provider: 'Fast.com',
  );
}

/// A Netflix Open Connect appliance that serves the test object.
@immutable
final class _FastTarget {
  const new({required this.uri, this.city, this.country});

  static final RegExp _airportCode = RegExp(
    r'(?:^|[.-])([a-z]{3})\d{3}(?:[.-]|$)',
  );

  final Uri uri;
  final String? city;
  final String? country;

  /// The Netflix facility code, for example `BOM` for Mumbai.
  String? get colo =>
      _airportCode.firstMatch(uri.host.toLowerCase())?.group(1)?.toUpperCase();
}
