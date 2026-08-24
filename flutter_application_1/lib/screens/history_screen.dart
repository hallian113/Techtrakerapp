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

  Future<void> _showRecordDetails(
      BuildContext context, AttendanceModel record) async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final locations = await locationProvider.getLocationsForDay(
      record.userId,
      record.timestamp,
    );
    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.blackCard,
        title: Text(
          '${record.userName} - ${record.punchTypeDisplayName}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: SizedBox(
          width: 420,
          height: 360,
          child: locations.isEmpty
              ? const Center(
                  child: Text(
                    'No location records for this day',
                    style: TextStyle(color: AppTheme.greyMedium),
                  ),
                )
              : ListView(
                  children: [
                    _detailRow(
                        'Punch time', Helpers.formatDateTime(record.timestamp)),
                    _detailRow('Punch location',
                        record.locationName ?? 'Unknown location'),
                    _detailRow('Address', record.address ?? 'Unknown address'),
                    const Divider(color: AppTheme.greyDark),
                    const Text(
                      'Location journey',
                      style: TextStyle(
                          color: AppTheme.gold, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...locations.map(_locationRow),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppTheme.gold),
                        ),
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
