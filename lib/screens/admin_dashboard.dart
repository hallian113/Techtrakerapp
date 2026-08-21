// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/auth_service.dart';
import 'add_tech_screen.dart'; // Nayi screen ka import add kiya hai

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Control Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      // YEH NAYA BUTTON ADD HUA HAI TECH ADD KARNE KE LIYE
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD4AF37), // Gold color
        foregroundColor: Colors.black, // Black icon
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTechScreen()),
          );
        },
        child: const Icon(Icons.person_add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Sirf un tech ko listen karna jo Punch In hain
        stream: _db
            .collection('technicians')
            .where('isPunchedIn', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No technicians are currently active.",
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            );
          }

          var activeTechs = snapshot.data!.docs;
          List<Marker> markers = [];

          // Map par markers lagana
          for (var tech in activeTechs) {
            var data = tech.data() as Map<String, dynamic>;
            double lat = data['currentLat'] ?? 0.0;
            double lng = data['currentLng'] ?? 0.0;

            if (lat != 0.0 && lng != 0.0) {
              markers.add(
                Marker(
                  point: LatLng(lat, lng),
                  width: 60,
                  height: 60,
                  child: GestureDetector(
                    onTap: () {
                      // Marker par click karne par tech ki details show hogi
                      _showTechDetails(tech.id, data);
                    },
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFFD4AF37), // Gold color marker
                      size: 40,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 5,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          }

          return Stack(
            children: [
              // PREMIUM DARK MAP (Free OpenStreetMap Dark Tiles)
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: markers.isNotEmpty
                      ? markers.first.point
                      : LatLng(43.6532, -79.3832), // Default: Toronto, Canada
                  initialZoom: 12.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),

              // Neeche Active Techs ki List (Slide up panel jesa design)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.all(10),
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withOpacity(0.5),
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    scrollDirection: Axis.horizontal,
                    itemCount: activeTechs.length,
                    itemBuilder: (context, index) {
                      var techData =
                          activeTechs[index].data() as Map<String, dynamic>;
                      String name = techData['name'] ?? 'Unknown';
                      String address =
                          techData['currentAddress'] ?? 'Locating...';

                      return GestureDetector(
                        onTap: () {
                          // List par click karne par map us tech par focus karega
                          double lat = techData['currentLat'] ?? 0.0;
                          double lng = techData['currentLng'] ?? 0.0;
                          if (lat != 0.0 && lng != 0.0) {
                            _mapController.move(LatLng(lat, lng), 15.0);
                          }
                          _showTechDetails(activeTechs[index].id, techData);
                        },
                        child: Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.work_history,
                                    color: Colors.green,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      techData['currentStatus'] ?? 'Working',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Expanded(
                                child: Text(
                                  address,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Tech ki details aur History dekhne ka Popup
  void _showTechDetails(String techId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['name'] ?? 'Unknown',
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Status: ${data['currentStatus'] ?? 'N/A'}",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 5),
              Text(
                "Location: ${data['currentAddress'] ?? 'N/A'}",
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // History Check karne ka button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.history),
                  label: const Text("View Today's History"),
                  onPressed: () {
                    Navigator.pop(context); // Bottom sheet band karo
                    _showHistory(techId, data['name']);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // History dekhne ka function (Firestore se locations fetch karna)
  void _showHistory(String techId, String? techName) {
    String todayDate = DateTime.now().toUtc().toIso8601String().split(
      'T',
    )[0]; // Aaj ki date

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            "Today's Route: $techName",
            style: const TextStyle(color: Color(0xFFD4AF37)),
          ),
          content: SizedBox(
            height: 300,
            child: FutureBuilder<QuerySnapshot>(
              future: _db
                  .collection('technicians')
                  .doc(techId)
                  .collection('history')
                  .doc(todayDate)
                  .collection('locations')
                  .orderBy('timestamp', descending: false)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                  );
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No history found for today.",
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var loc =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(
                        Icons.location_history,
                        color: Color(0xFFD4AF37),
                      ),
                      title: Text(
                        loc['address'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        loc['timestamp'] != null
                            ? (loc['timestamp'] as Timestamp)
                                  .toDate()
                                  .toString()
                            : 'Time N/A',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Close",
                style: TextStyle(color: Color(0xFFD4AF37)),
              ),
            ),
          ],
        );
      },
    );
  }
}
