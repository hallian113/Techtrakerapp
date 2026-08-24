import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tracking_app/providers/auth_provider.dart';
import 'package:tracking_app/providers/location_provider.dart';
import 'package:tracking_app/providers/attendance_provider.dart';
import 'package:tracking_app/widgets/custom_button.dart';
import 'package:tracking_app/widgets/custom_textfield.dart';
import 'package:tracking_app/utils/theme.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PunchInScreen extends StatefulWidget {
  const PunchInScreen({super.key});

  @override
  State<PunchInScreen> createState() => _PunchInScreenState();
}

class _PunchInScreenState extends State<PunchInScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        title: Text(
          attendanceProvider.isPunchedIn ? 'Punch Out' : 'Punch In',
        ),
        backgroundColor: AppTheme.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.gold),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
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
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: attendanceProvider.isPunchedIn
                              ? const LinearGradient(
                                  colors: [AppTheme.error, AppTheme.error])
                              : AppTheme.goldGradient,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Icon(
                          attendanceProvider.isPunchedIn
                              ? Icons.logout
                              : Icons.login,
                          size: 40,
                          color: AppTheme.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        attendanceProvider.isPunchedIn
                            ? 'Punch Out'
                            : 'Punch In',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        attendanceProvider.isPunchedIn
                            ? 'You are currently punched in'
                            : 'Ready to start your shift',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.greyLight,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 📍 Location Card
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
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppTheme.gold,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locationProvider.currentLocationName ??
                                  '📍 Location not available',
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
                              locationProvider.currentAddress ??
                                  'Please enable GPS',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.greyLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 📝 Note Field
                CustomTextField(
                  controller: _noteController,
                  label: 'Note (Optional)',
                  hint: 'Add a note for this punch',
                  prefixIcon: Icons.note,
                  maxLines: 3,
                ),

                const SizedBox(height: 30),

                // 🚀 Punch Button
                CustomButton(
                  text: _isProcessing
                      ? 'Processing...'
                      : attendanceProvider.isPunchedIn
                          ? 'PUNCH OUT'
                          : 'PUNCH IN',
                  backgroundColor: attendanceProvider.isPunchedIn
                      ? AppTheme.error
                      : AppTheme.success,
                  onPressed: _isProcessing
                      ? null
                      : () async {
                          if (locationProvider.currentPosition == null) {
                            Fluttertoast.showToast(
                              msg: '📍 Please get location first',
                              backgroundColor: AppTheme.error,
                            );
                            return;
                          }

                          setState(() {
                            _isProcessing = true;
                          });

                          bool success;

                          if (attendanceProvider.isPunchedIn) {
                            // Punch Out
                            success = await attendanceProvider.punchOut(
                              userId: authProvider.userId,
                              userName: authProvider.userName,
                              latitude:
                                  locationProvider.currentPosition!.latitude,
                              longitude:
                                  locationProvider.currentPosition!.longitude,
                              locationName:
                                  locationProvider.currentLocationName ??
                                      'Unknown',
                              address:
                                  locationProvider.currentAddress ?? 'Unknown',
                              note: _noteController.text.isNotEmpty
                                  ? _noteController.text
                                  : null,
                            );
                          } else {
                            // Punch In
                            success = await attendanceProvider.punchIn(
                              userId: authProvider.userId,
                              userName: authProvider.userName,
                              latitude:
                                  locationProvider.currentPosition!.latitude,
                              longitude:
                                  locationProvider.currentPosition!.longitude,
                              locationName:
                                  locationProvider.currentLocationName ??
                                      'Unknown',
                              address:
                                  locationProvider.currentAddress ?? 'Unknown',
                              note: _noteController.text.isNotEmpty
                                  ? _noteController.text
                                  : null,
                            );
                          }

                          if (success) {
                            await locationProvider.saveCurrentLocation(
                              authProvider.userId,
                              authProvider.userName,
                            );
                          }

                          setState(() {
                            _isProcessing = false;
                          });

                          if (success && mounted) {
                            _noteController.clear();
                            Navigator.pop(context);
                          }
                        },
                ),

                const SizedBox(height: 20),

                // ℹ️ Info Text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.gold.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.gold,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your location will be tracked while you are punched in',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.greyLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
