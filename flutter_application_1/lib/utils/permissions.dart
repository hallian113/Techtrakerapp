import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PermissionHandler {
  static Future<bool> requestAllPermissions() async {
    try {
      // 1. Location Permission (Foreground)
      PermissionStatus locationStatus = await Permission.location.request();
      if (locationStatus.isDenied) {
        Fluttertoast.showToast(msg: 'Location permission is required');
        return false;
      }

      // 2. Location Permission (Background)
      PermissionStatus backgroundStatus = await Permission.locationAlways
          .request();
      if (backgroundStatus.isDenied) {
        Fluttertoast.showToast(
          msg: 'Background location permission is required',
        );
        return false;
      }

      // 3. Ignore Battery Optimization
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }

      return true;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error requesting permissions');
      return false;
    }
  }

  static Future<bool> arePermissionsGranted() async {
    bool locationGranted = await Permission.location.isGranted;
    bool backgroundGranted = await Permission.locationAlways.isGranted;
    return locationGranted && backgroundGranted;
  }
}
