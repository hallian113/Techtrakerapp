import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:tracking_app/models/location_model.dart';
import 'package:tracking_app/services/database_service.dart';

class LocationService {
  final DatabaseService _databaseService = DatabaseService();

  Position? _currentPosition;
  String? _currentAddress;
  String? _currentLocationName;

  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  String? get currentLocationName => _currentLocationName;

  // ✅ Get Current Location
  Future<bool> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;
      await _getAddressFromLatLng(position);

      return true;
    } catch (e) {
      return false;
    }
  }

  // ✅ Get Address from Coordinates
  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        _currentAddress =
            '${place.street}, ${place.locality}, ${place.country}';
        _currentLocationName =
            place.name ?? place.locality ?? 'Unknown Location';
      } else {
        _currentAddress = 'Unknown Address';
        _currentLocationName = 'Unknown Location';
      }
    } catch (e) {
      _currentAddress = 'Unable to get address';
      _currentLocationName = 'Unknown Location';
    }
  }

  // ✅ Save Location to Database
  Future<void> saveLocation(String userId, String userName) async {
    if (_currentPosition == null) return;

    LocationModel location = LocationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      userName: userName,
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      timestamp: DateTime.now(),
      locationName: _currentLocationName,
      address: _currentAddress,
      speed: _currentPosition!.speed,
      accuracy: _currentPosition!.accuracy,
      isSynced: false,
    );

    await _databaseService.saveLocation(location);
  }

  // ✅ Get Distance Between Two Locations
  double getDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // ✅ Format Distance
  String formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    } else {
      return '${meters.toStringAsFixed(0)} m';
    }
  }
}
