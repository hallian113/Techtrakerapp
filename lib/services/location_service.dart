import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // GPS permission check aur request karne ka function
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Live location stream start karna (Har 50 meter move karne par update aayega)
  Stream<Position> getLiveLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // 50 meter bad hi update aaye taake battery save ho
      ),
    );
  }

  // Lat/Lng ko Human-Readable Address mein convert karna (Reverse Geocoding - FREE)
  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return "${place.street}, ${place.locality}, ${place.administrativeArea}";
      }
    } catch (e) {
      print("Geocoding Error: $e");
    }
    return "Unknown Location";
  }
}
