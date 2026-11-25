// ignore_for_file: unused_element, unused_import
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tracking_app/providers/auth_provider.dart';
import 'package:tracking_app/providers/attendance_provider.dart';
import 'package:tracking_app/widgets/attendance_card.dart';
import 'package:tracking_app/widgets/custom_button.dart';
import 'package:tracking_app/utils/theme.dart';
import 'package:tracking_app/utils/helpers.dart';
import 'package:tracking_app/providers/location_provider.dart';
import 'package:tracking_app/models/attendance_model.dart';
import 'package:tracking_app/models/location_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tracking_app/utils/constants.dart';
import 'package:tracking_app/screens/location_journey_screen.dart';
import 'package:tracking_app/utils/page_transitions.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool _sameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  // ✅ Determine if a punch-in session is still ongoing, purely from data
  // (not from the current device's local session state).
  bool _isRecordStillOngoing(
      AttendanceProvider attendanceProvider, AttendanceModel record) {
    if (record.punchType != AppConstants.punchIn) return false;

    final userRecords = attendanceProvider.attendanceHistory
        .where((r) => r.userId == record.userId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (userRecords.isEmpty) return false;

    final latest = userRecords.last;
    // Ongoing only if THIS record is the user's most recent record overall
    // and it's still a punch-in (no punch-out after it yet).
    return latest.id == record.id;
  }

  Future<void> _showRecordDetails(
      BuildContext context, AttendanceModel record) async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);

    final sessionId = record.sessionId ?? record.id;
    List<LocationModel> locations = [];
    try {
      locations = await locationProvider.getLocationsBySession(sessionId);

      // 🔄 Fallback for OLD records saved before sessionId tracking existed
      if (locations.isEmpty && record.sessionId == null) {
        locations = await _getFallbackLocationsForOldRecord(
            attendanceProvider, locationProvider, record);
      }
    } catch (e) {
      debugPrint('History details error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading locations: $e')),
        );
      }
    }

    if (!context.mounted) return;

    final isLive = _isRecordStillOngoing(attendanceProvider, record);

    Navigator.push(
      context,
      slideFadeRoute(
        LocationJourneyScreen(
          record: record,
          locations: locations,
          isLive: isLive,
        ),
      ),
    );
  }

  // 🔄 Best-effort location lookup for records saved BEFORE sessionId existed
  Future<List<LocationModel>> _getFallbackLocationsForOldRecord(
    AttendanceProvider attendanceProvider,
    LocationProvider locationProvider,
    AttendanceModel record,
  ) async {
    try {
      final sameDayRecords = attendanceProvider.attendanceHistory
          .where((r) =>
              r.userId == record.userId &&
              _sameDate(r.timestamp, record.timestamp))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      DateTime rangeStart;
      DateTime rangeEnd;

      if (record.punchType == AppConstants.punchIn) {
        rangeStart = record.timestamp;
        final matchingOut = sameDayRecords.firstWhere(
          (r) =>
              r.punchType == AppConstants.punchOut &&
              r.timestamp.isAfter(record.timestamp),
          orElse: () => record,
        );
        rangeEnd =
            matchingOut == record ? DateTime.now() : matchingOut.timestamp;
      } else {
        rangeEnd = record.timestamp;
        final matchingIn = sameDayRecords.lastWhere(
          (r) =>
              r.punchType == AppConstants.punchIn &&
              r.timestamp.isBefore(record.timestamp),
          orElse: () => record,
        );
        rangeStart = matchingIn == record
            ? record.timestamp.subtract(const Duration(hours: 8))
            : matchingIn.timestamp;
      }

      final dayLocations = await locationProvider.getLocationsForDay(
          record.userId, record.timestamp);

      final filtered = dayLocations
          .where((loc) =>
              !loc.timestamp.isBefore(rangeStart) &&
              !loc.timestamp.isAfter(rangeEnd))
          .toList();

      filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return filtered;
    } catch (e) {
      return [];
    }
  }

  Future<void> _deleteRecord(
      BuildContext context, AttendanceModel record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.blackCard,
        title: const Text('Delete attendance record?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This attendance record will be permanently removed.',
          style: TextStyle(color: AppTheme.greyLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child:
                const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    await attendanceProvider.deleteAttendance(record.id);
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: AppTheme.greyLight, fontSize: 13),
      ),
    );
  }

  Widget _locationRow(LocationModel location) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.location_on, color: AppTheme.gold),
      title: Text(
        Helpers.formatDateTime(location.timestamp),
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      subtitle: Text(
        '${location.locationName ?? 'Unknown'}\n${location.address ?? location.locationString}',
        style: const TextStyle(color: AppTheme.greyMedium, fontSize: 12),
      ),
    );
  }

  Widget _shimmerCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: AppTheme.blackCard,
        highlightColor: AppTheme.blackLight,
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            color: AppTheme.blackCard,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    if (authProvider.isAdmin) {
      await attendanceProvider.getAllAttendanceHistory();
    } else {
      await attendanceProvider.getAttendanceHistory(authProvider.userId);
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        title: const Text('Attendance History'),
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
          child: Column(
            children: [
              // 📅 Date Selector
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedDate =
                              _selectedDate.subtract(const Duration(days: 1));
                        });
                      },
                      icon: Icon(Icons.arrow_left,
                          color: AppTheme.gold, size: 32),
                    ),
                    Expanded(
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              Helpers.formatDate(_selectedDate),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedDate.day == DateTime.now().day &&
                                      _selectedDate.month ==
                                          DateTime.now().month &&
                                      _selectedDate.year == DateTime.now().year
                                  ? 'Today'
                                  : 'Select Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.greyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedDate =
                              _selectedDate.add(const Duration(days: 1));
                        });
                      },
                      icon: Icon(Icons.arrow_right,
                          color: AppTheme.gold, size: 32),
                    ),
                  ],
                ),
              ),

              const Divider(color: AppTheme.gold, thickness: 0.5),

              // 📋 History List
              Expanded(
                child: _isLoading
                    ? ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 5,
                        itemBuilder: (context, index) => _shimmerCard(),
                      )
                    : attendanceProvider.attendanceHistory
                            .where((record) =>
                                _sameDate(record.timestamp, _selectedDate))
                            .isEmpty
                        ? Center(
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
                                  'No attendance records found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.greyMedium,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                CustomButton(
                                  text: 'Refresh',
                                  onPressed: _loadHistory,
                                  width: 150,
                                  height: 40,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: attendanceProvider.attendanceHistory
                                .where((record) =>
                                    _sameDate(record.timestamp, _selectedDate))
                                .length,
                            itemBuilder: (context, index) {
                              final records = attendanceProvider
                                  .attendanceHistory
                                  .where((record) => _sameDate(
                                      record.timestamp, _selectedDate))
                                  .toList();
                              final record = records[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AttendanceCard(
                                  attendance: record,
                                  showUserInfo: authProvider.isAdmin,
                                  onTap: () =>
                                      _showRecordDetails(context, record),
                                  onDelete: authProvider.isAdmin
                                      ? () => _deleteRecord(context, record)
                                      : null,
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
