import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tracking_app/providers/auth_provider.dart';
import 'package:tracking_app/providers/location_provider.dart';
import 'package:tracking_app/providers/attendance_provider.dart';
import 'package:tracking_app/widgets/custom_button.dart';
import 'package:tracking_app/utils/theme.dart';
import 'package:tracking_app/utils/helpers.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _sessionRestored = false;
  AuthProvider? _authProviderRef;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _authProviderRef = Provider.of<AuthProvider>(context, listen: false);
      _tryRestoreSession();
      _authProviderRef!.addListener(_tryRestoreSession);
    });
  }

  Future<void> _tryRestoreSession() async {
    if (_sessionRestored) return;
    final authProvider = _authProviderRef;
    if (authProvider == null || authProvider.userId.isEmpty) return;

    _sessionRestored = true;
    authProvider.removeListener(_tryRestoreSession);
    if (!mounted) return;

    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);

    await attendanceProvider.restoreSession(authProvider.userId);

    Fluttertoast.showToast(
      msg: attendanceProvider.isPunchedIn
          ? '✅ Session restored: Punched In'
          : 'ℹ️ No active session found',
    );

    if (attendanceProvider.isPunchedIn) {
      await locationProvider.startTracking(
        authProvider.userId,
        authProvider.userName,
        sessionId: attendanceProvider.currentSessionId,
      );
    }
  }

  @override
  void dispose() {
    _authProviderRef?.removeListener(_tryRestoreSession);
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
        return _buildHomeTab(
            authProvider, locationProvider, attendanceProvider);
      case 1:
        return _buildHistoryTab(authProvider);
      case 2:
        return _buildProfileTab(authProvider);
      default:
        return _buildHomeTab(
            authProvider, locationProvider, attendanceProvider);
    }
  }

  Widget _buildHomeTab(
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
              // 🥇 Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${authProvider.userName}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Welcome back to TechTracker',
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
                      child: Text(
                        authProvider.userName.isNotEmpty
                            ? authProvider.userName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 🎯 Attendance Status Card
              _buildStatusCard(attendanceProvider),

              const SizedBox(height: 24),

              // 📍 Location Card
              _buildLocationCard(locationProvider, authProvider),

              const SizedBox(height: 24),

              // 🚀 Quick Action Buttons
              _buildQuickActions(context, attendanceProvider, locationProvider),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showLocationDisclosureDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.black,
        title: const Text(
          'Location Access',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'TechTracker collects your location, including in the background '
          'when the app is closed or not in use, to enable live tracking of '
          'field technicians and accurate attendance records. This data is '
          'used only for attendance and service tracking purposes and is '
          'not shared with third parties.',
          style: TextStyle(color: AppTheme.greyLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Deny', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Allow', style: TextStyle(color: AppTheme.gold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildStatusCard(AttendanceProvider attendanceProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: attendanceProvider.isPunchedIn
              ? [AppTheme.success.withOpacity(0.2), AppTheme.blackCard]
              : [AppTheme.error.withOpacity(0.2), AppTheme.blackCard],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: attendanceProvider.isPunchedIn
              ? AppTheme.success.withOpacity(0.3)
              : AppTheme.error.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (attendanceProvider.isPunchedIn
                    ? AppTheme.success
                    : AppTheme.error)
                .withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: attendanceProvider.isPunchedIn
                      ? AppTheme.success
                      : AppTheme.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (attendanceProvider.isPunchedIn
                              ? AppTheme.success
                              : AppTheme.error)
                          .withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                attendanceProvider.isPunchedIn
                    ? '🟢 Currently Active'
                    : '🔴 Currently Offline',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusItem(
                'Status',
                attendanceProvider.isPunchedIn ? 'Punched In' : 'Punched Out',
                attendanceProvider.isPunchedIn
                    ? AppTheme.success
                    : AppTheme.error,
              ),
              _buildStatusItem(
                'Time',
                attendanceProvider.isPunchedIn &&
                        attendanceProvider.currentSession != null
                    ? Helpers.formatTime(
                        attendanceProvider.currentSession!.timestamp)
                    : '--:--',
                AppTheme.gold,
              ),
              _buildStatusItem(
                'Duration',
                attendanceProvider.isPunchedIn
                    ? attendanceProvider.getPunchDuration() ?? '0h 0m'
                    : '0h 0m',
                AppTheme.greyLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.greyMedium,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(
      LocationProvider locationProvider, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.blackCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.gold.withOpacity(0.15),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withOpacity(0.05),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on,
              color: AppTheme.black,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locationProvider.currentLocationName ??
                      'Fetching location...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  locationProvider.currentAddress ?? '📍 Tap to get location',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.greyLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: locationProvider.isLoading
                ? null
                : () async {
                    bool allowed = await _showLocationDisclosureDialog(context);
                    if (!allowed) return;
                    bool success = await locationProvider.getCurrentLocation();
                    if (success && mounted) {
                      await locationProvider.saveCurrentLocation(
                        authProvider.userId,
                        authProvider.userName,
                      );
                      Fluttertoast.showToast(
                        msg: 'ðŸ“ Location updated',
                        backgroundColor: AppTheme.gold,
                        textColor: AppTheme.black,
                      );
                    }
                  },
            icon: locationProvider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
                    ),
                  )
                : Icon(
                    Icons.refresh,
                    color: AppTheme.gold,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
      BuildContext context,
      AttendanceProvider attendanceProvider,
      LocationProvider locationProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: attendanceProvider.isPunchedIn ? 'PUNCH OUT' : 'PUNCH IN',
                backgroundColor: attendanceProvider.isPunchedIn
                    ? AppTheme.error
                    : AppTheme.success,
                onPressed: attendanceProvider.isLoading
                    ? null
                    : () {
                        Navigator.pushNamed(context, '/punch');
                      },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'HISTORY',
                isOutlined: true,
                onPressed: () {
                  Navigator.pushNamed(context, '/history');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryTab(AuthProvider authProvider) {
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
                'Attendance History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: AppTheme.gold.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No history available yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.greyMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomButton(
                        text: 'VIEW FULL HISTORY',
                        onPressed: () {
                          Navigator.pushNamed(context, '/history');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
                'Profile',
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
                        child: Text(
                          authProvider.userName.isNotEmpty
                              ? authProvider.userName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.black,
                          ),
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
                      child: Text(
                        authProvider.isAdmin ? 'Administrator' : 'Technician',
                        style: const TextStyle(
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
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
