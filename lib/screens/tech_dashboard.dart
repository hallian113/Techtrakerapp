import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import 'package:flutter/foundation.dart'; // Yeh kIsWeb ke liye zaroori hai

class TechDashboard extends StatefulWidget {
  final String techId;
  final String techName;

  const TechDashboard({
    super.key,
    required this.techId,
    required this.techName,
  });

  @override
  State<TechDashboard> createState() => _TechDashboardState();
}

class _TechDashboardState extends State<TechDashboard> {
  final LocationService _locationService = LocationService();
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  bool isPunchedIn = false;
  int secondsElapsed = 0;
  Timer? timer;
  StreamSubscription<Position>? positionStream;

  // Timer Start Karne Ka Function
  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        secondsElapsed++;
      });
    });
  }

  void stopTimer() {
    timer?.cancel();
  }

  // Format Time (00:00:00)
  String getFormattedTime() {
    int hours = secondsElapsed ~/ 3600;
    int minutes = (secondsElapsed % 3600) ~/ 60;
    int secs = secondsElapsed % 60;
    return "${hours.toString().padLeft(2, '0')} : ${minutes.toString().padLeft(2, '0')} : ${secs.toString().padLeft(2, '0')}";
  }

  // PUNCH IN Function
  void punchIn() async {
    // Agar Web/Desktop par hai toh GPS check nahi karna
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Web/Desktop par GPS tracking support nahi hai. Sirf timer chalega.",
          ),
          backgroundColor: Colors.orange,
        ),
      );

      await _dbService.punchIn(widget.techId);
      setState(() {
        isPunchedIn = true;
        secondsElapsed = 0;
      });
      startTimer();

      // Dummy location save karna taake admin dashboard par marker show ho
      _dbService.updateLiveLocation(
        widget.techId,
        43.6532, // Toronto dummy lat
        -79.3832, // Toronto dummy lng
        "Toronto, Canada (Web Test)",
      );
      return;
    }

    // Agar Mobile par hai toh asli GPS check karna
    bool hasPermission = await _locationService.checkAndRequestPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("GPS Permission Denied! App cannot track without it."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 1. Firebase mein Punch In save karna
    await _dbService.punchIn(widget.techId);

    // 2. Timer Start karna
    setState(() {
      isPunchedIn = true;
      secondsElapsed = 0;
    });
    startTimer();

    // 3. Live GPS Tracking Start karna
    positionStream = _locationService.getLiveLocationStream().listen((
      Position position,
    ) async {
      // Location ka address nikalna
      String address = await _locationService.getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      // Firebase mein save karna
      _dbService.updateLiveLocation(
        widget.techId,
        position.latitude,
        position.longitude,
        address,
      );
    });
  }

  // PUNCH OUT Function
  void punchOut() async {
    // 1. GPS Stream stop karna
    positionStream?.cancel();

    // 2. Firebase mein Punch Out save karna
    await _dbService.punchOut(widget.techId);

    // 3. Timer stop karna
    setState(() {
      isPunchedIn = false;
    });
    stopTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tech Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              if (isPunchedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please Punch Out before logging out!"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              await _authService.logout();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey.shade900],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Welcome, ${widget.techName}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 40),

                // Timer Circle / Display
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD4AF37),
                      width: 4,
                    ),
                    color: Colors.black54,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    getFormattedTime(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Status Text
                Text(
                  isPunchedIn ? "STATUS: WORKING" : "STATUS: OFF DUTY",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isPunchedIn ? Colors.green : Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Punch In / Out Button
                CustomButton(
                  text: isPunchedIn ? 'PUNCH OUT' : 'PUNCH IN',
                  isPunchIn:
                      !isPunchedIn, // Agar true (Punch In) hai toh green, warna red
                  onPressed: isPunchedIn ? punchOut : punchIn,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
