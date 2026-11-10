import 'package:meta/meta.dart';

/// Who measured the test and where the traffic entered the network.
@immutable
final class NetworkInfo {
  /// Creates the connection description.
  const new({
    this.ip,
    this.city,
    this.country,
    this.colo,
    this.organization,
    this.provider,
  });

  /// Reads a server description from the speed test metadata payload.
  ///
  /// Unknown or missing fields are ignored, so a partial payload still
  /// produces a usable description.
  // A factory constructor must repeat the class name, so the analyzer's
  // unnecessary_type_name_in_constructor hint is a false positive here.
  // ignore: unnecessary_type_name_in_constructor
  factory NetworkInfo.fromJson(Map<Object?, Object?> json) {
    String? read(String key) {
      final value = json[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    return NetworkInfo(
      ip: read('ip'),
      city: read('city'),
      country: read('country'),
      colo: read('colo'),
      organization: read('asOrganization'),
      provider: read('provider'),
    );
  }

  /// The public IP address of this machine, when reported.
  final String? ip;

  /// The city closest to the measuring endpoint, when reported.
  final String? city;

  /// The country of the measuring endpoint, when reported.
  final String? country;

  /// The Cloudflare data center code, for example `FRA`.
  final String? colo;

  /// The autonomous system that carries the traffic, when reported.
  final String? organization;

  /// The measurement network that supplied the target, for example `Fast.com`.
  final String? provider;

  /// A human-readable location, or `null` when the city is unknown.
  String? get location {
    final parts = [city, country].whereType<String>().toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  /// The JSON representation persisted with a result.
  Map<String, Object?> toJson() => <String, Object?>{
    'ip': ip,
    'city': city,
    'country': country,
    'colo': colo,
    'organization': organization,
    'provider': provider,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkInfo &&
          other.ip == ip &&
          other.city == city &&
          other.country == country &&
          other.colo == colo &&
          other.organization == organization &&
          other.provider == provider;

  @override
  int get hashCode =>
      Object.hash(ip, city, country, colo, organization, provider);

  @override
  String toString() =>
      'NetworkInfo($location, $colo, $organization, $provider)';
}
