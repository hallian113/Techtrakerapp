import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tracking_app/providers/auth_provider.dart';
import 'package:tracking_app/providers/location_provider.dart';
import 'package:tracking_app/providers/attendance_provider.dart';
import 'package:tracking_app/widgets/custom_button.dart';
import 'package:tracking_app/utils/theme.dart';
import 'package:tracking_app/utils/helpers.dart';
import 'package:tracking_app/screens/history_screen.dart';
import 'package:tracking_app/models/attendance_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAdminData();
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _loadAdminData();
    });
  }

  Future<void> _loadAdminData() async {
    if (!mounted) return;
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    await Future.wait([
      locationProvider.getAllLatestLocations(),
      attendanceProvider.getAllAttendanceHistory(),
    ]);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: _buildBody(authProvider, locationProvider, attendanceProvider),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBody(
      AuthProvider authProvider,
      LocationProvider locationProvider,
      AttendanceProvider attendanceProvider) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab(
            authProvider, locationProvider, attendanceProvider);
      case 1:
        return const HistoryScreen();
      case 2:
        return _buildTrackingTab(locationProvider);
      case 3:
        return _buildProfileTab(authProvider);
      default:
        return _buildDashboardTab(
            authProvider, locationProvider, attendanceProvider);
    }
  }

  Widget _buildDashboardTab(
      AuthProvider authProvider,
      LocationProvider locationProvider,
      AttendanceProvider attendanceProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.black, AppTheme.blackLight],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🥇 Admin Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppTheme.goldGradient.createShader(bounds),
                        child: const Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Welcome, ${authProvider.userName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.greyLight,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.admin_panel_settings,
                        color: AppTheme.black,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 📊 Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Techs',
                      _getTechCount(locationProvider),
                      Icons.people,
                      AppTheme.gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Active Now',
                      _getActiveCount(locationProvider),
                      Icons.circle,
                      AppTheme.success,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Today\'s Punch',
                      _getTodayPunchCount(attendanceProvider),
                      Icons.login,
                      AppTheme.goldLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Late Arrivals',
                      '0',
                      Icons.warning,
                      AppTheme.warning,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 📍 Live Tracking
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.blackCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.gold.withOpacity(0.15),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppTheme.gold,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Live Tracking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppTheme.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Live',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildLocationMap(locationProvider),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 📋 Recent Activity
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.blackCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.gold.withOpacity(0.15),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (attendanceProvider.attendanceHistory.isEmpty)
                      const Text(
                        'No attendance activity yet',
                        style: TextStyle(color: AppTheme.greyMedium),
                      )
                    else
                      ...attendanceProvider.attendanceHistory
                          .take(5)
                          .map(_buildActivityItemFromRecord),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.blackCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.greyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _getTechCount(LocationProvider locationProvider) {
    return locationProvider.totalTechs.toString();
  }

  String _getActiveCount(LocationProvider locationProvider) {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 15));
    return locationProvider.locationHistory
        .where((location) => location.timestamp.isAfter(cutoff))
        .length
        .toString();
  }

  String _getTodayPunchCount(AttendanceProvider attendanceProvider) {
    final now = DateTime.now();
    return attendanceProvider.attendanceHistory
        .where((record) =>
            record.timestamp.year == now.year &&
            record.timestamp.month == now.month &&
            record.timestamp.day == now.day)
        .length
        .toString();
  }

  Widget _buildActivityItemFromRecord(AttendanceModel record) {
    return _buildActivityItem(
      record.userName,
      record.punchType == 'in' ? 'Punched In' : 'Punched Out',
      Helpers.formatTime(record.timestamp),
    );
  }

  Widget _buildActivityItem(String name, String action, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.gold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            action,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.goldLight,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.greyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingTab(LocationProvider locationProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.black, AppTheme.blackLight],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Live Tracking',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.blackCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.gold.withOpacity(0.15),
                      width: 0.5,
                    ),
                  ),
                  child: _buildLocationMap(locationProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationMap(LocationProvider locationProvider) {
    final locations = locationProvider.locationHistory;
    if (locations.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'No technician locations yet',
            style: TextStyle(color: AppTheme.greyMedium),
          ),
        ),
      );
    }

    final firstLocation = locations.first;
    return SizedBox(
      height: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter:
                LatLng(firstLocation.latitude, firstLocation.longitude),
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.flutter_application_1',
            ),
            MarkerLayer(
              markers: locations
                  .map(
                    (location) => Marker(
                      point: LatLng(location.latitude, location.longitude),
                      width: 120,
                      height: 70,
                      child: Column(
                        children: [
                          const Icon(Icons.location_on,
                              color: AppTheme.error, size: 34),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            color: AppTheme.black,
                            child: Text(
                              location.userName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(AuthProvider authProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.black, AppTheme.blackLight],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.admin_panel_settings,
                          color: AppTheme.black,
                          size: 50,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      authProvider.userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      authProvider.userEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.greyLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Administrator',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    CustomButton(
                      text: 'LOGOUT',
                      backgroundColor: AppTheme.error,
                      onPressed: () async {
                        await authProvider.logout();
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.location_on),
          label: 'Tracking',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
