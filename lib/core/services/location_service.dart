import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class DeviceLocationResult {
  const DeviceLocationResult({
    required this.city,
    required this.country,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String city;
  final String country;
  final String address;
  final double latitude;
  final double longitude;
}

class LocationService {
  const LocationService();

  Future<LocationPermission> requestPermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  Future<DeviceLocationResult> detectCurrentLocation() async {
    final permission = await requestPermission();
    if (permission == LocationPermission.denied) {
      throw const LocationPermissionDeniedException();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionPermanentlyDeniedException();
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    final placemark = placemarks.isNotEmpty ? placemarks.first : null;
    final city = _firstNonEmpty([
      placemark?.locality,
      placemark?.subAdministrativeArea,
      placemark?.administrativeArea,
    ]);
    final country = _firstNonEmpty([
      placemark?.country,
      placemark?.isoCountryCode,
    ]);
    final address = _firstNonEmpty([
      placemark?.street,
      placemark?.subLocality,
      placemark?.locality,
      placemark?.administrativeArea,
      placemark?.country,
    ]);

    return DeviceLocationResult(
      city: city ?? '',
      country: country ?? '',
      address: address ?? '',
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}

class LocationServiceDisabledException implements Exception {
  const LocationServiceDisabledException();
}

class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException();
}

class LocationPermissionPermanentlyDeniedException implements Exception {
  const LocationPermissionPermanentlyDeniedException();
}
