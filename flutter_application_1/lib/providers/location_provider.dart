import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:tracking_app/models/location_model.dart';
import 'package:tracking_app/services/database_service.dart';
import 'package:tracking_app/utils/constants.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  String? _currentAddress;
  String? _currentLocationName;
  bool _isTracking = false;
  List<LocationModel> _locationHistory = [];
  int _totalTechs = 0;
  bool _isLoading = false;

  final DatabaseService _databaseService = DatabaseService();

  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  String? get currentLocationName => _currentLocationName;
  bool get isTracking => _isTracking;
  List<LocationModel> get locationHistory => _locationHistory;
  bool get isLoading => _isLoading;
  int get totalTechs => _totalTechs;

  // ✅ Get Current Location
  Future<bool> getCurrentLocation() async {
    _setLoading(true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Fluttertoast.showToast(msg: 'Please enable location services');
        _setLoading(false);
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Fluttertoast.showToast(msg: 'Location permission denied');
          _setLoading(false);
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(msg: 'Location permission permanently denied');
        _setLoading(false);
        return false;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;
      await _getAddressFromLatLng(position);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      Fluttertoast.showToast(msg: 'Error getting location: $e');
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
      notifyListeners();
    } catch (e) {
      _currentAddress = 'Unable to get address';
      _currentLocationName = 'Unknown Location';
      notifyListeners();
    }
  }

  // ✅ Start Tracking (Background)
  Future<void> startTracking(String userId, String userName) async {
    if (_isTracking) return;

    _isTracking = true;
    notifyListeners();

    // Start periodic location updates
    _startPeriodicLocationUpdates(userId, userName);
  }

  // ✅ Stop Tracking
  Future<void> stopTracking() async {
    _isTracking = false;
    notifyListeners();
  }

  // ✅ Periodic Location Updates
  void _startPeriodicLocationUpdates(String userId, String userName) {
    // This will be called every 10 seconds
    // Actual implementation will use background service
    Future.delayed(Duration(seconds: AppConstants.locationUpdateInterval), () {
      if (_isTracking) {
        saveCurrentLocation(userId, userName);
        _startPeriodicLocationUpdates(userId, userName);
      }
    });
  }

  // ✅ Save Current Location to Database
  Future<void> saveCurrentLocation(String userId, String userName) async {
    try {
      bool hasLocation = await getCurrentLocation();
      if (!hasLocation || _currentPosition == null) return;

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

      // Save to local database
      await _databaseService.saveLocation(location);
      await _databaseService.syncLocation(location);

      // Add to history
      _locationHistory.add(location);
      notifyListeners();
    } catch (e) {
      // Silent fail
    }
  }

  Future<List<LocationModel>> getAllLatestLocations() async {
    _setLoading(true);
    try {
      _totalTechs = (await _databaseService.getTechUsers()).length;
      final locations = await _databaseService.getAllLatestLocations();
      _locationHistory = locations;
      _setLoading(false);
      return locations;
    } catch (e) {
      _setLoading(false);
      return [];
    }
  }

  // ✅ Get Location History for User
  Future<List<LocationModel>> getLocationHistory(
      String userId, DateTime date) async {
    _setLoading(true);
    try {
      List<LocationModel> history =
          await _databaseService.getLocationsByDate(userId, date);
      _locationHistory = history;
      _setLoading(false);
      return history;
    } catch (e) {
      _setLoading(false);
      return [];
    }
  }

  Future<List<LocationModel>> getLocationsForDay(String userId, DateTime date) {
    return _databaseService.getLocationsForDay(userId, date);
  }

  // ✅ Clear History
  void clearHistory() {
    _locationHistory.clear();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
