import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tracking_app/providers/attendance_provider.dart';
import 'package:tracking_app/models/tech_hours_summary.dart';
import 'package:tracking_app/utils/theme.dart';

class AdminHoursHistoryScreen extends StatefulWidget {
  const AdminHoursHistoryScreen({super.key});

  @override
  State<AdminHoursHistoryScreen> createState() =>
      _AdminHoursHistoryScreenState();
}

class _AdminHoursHistoryScreenState extends State<AdminHoursHistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  List<TechHoursSummary> _summaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHoursForDate(_selectedDate);
  }

  Future<void> _loadHoursForDate(DateTime date) async {
    setState(() => _isLoading = true);
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    final records = await attendanceProvider.getAllAttendanceByDate(date);
    final summaries = attendanceProvider.calculateDailyHours(records);
    if (mounted) {
      setState(() {
        _summaries = summaries;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.gold,
              onPrimary: AppTheme.black,
              surface: AppTheme.blackCard,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadHoursForDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        title:
            const Text('Hours History', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: AppTheme.gold),
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.blackCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: AppTheme.gold, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('EEEE, d MMMM yyyy')
                                  .format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_drop_down, color: AppTheme.gold),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Technician Hours',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child:
                              CircularProgressIndicator(color: AppTheme.gold))
                      : _summaries.isEmpty
                          ? const Center(
                              child: Text('No attendance records for this date',
                                  style: TextStyle(color: AppTheme.greyMedium)),
                            )
                          : ListView.builder(
                              itemCount: _summaries.length,
                              itemBuilder: (context, index) {
                                final summary = _summaries[index];
                                final isTop = index == 0;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.blackCard,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isTop
                                          ? AppTheme.gold.withOpacity(0.5)
                                          : AppTheme.gold.withOpacity(0.1),
                                      width: isTop ? 1.2 : 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isTop
                                              ? AppTheme.gold
                                              : AppTheme.blackLight,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isTop
                                                  ? AppTheme.black
                                                  : Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          summary.userName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        summary.formattedHours,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isTop
                                              ? AppTheme.gold
                                              : AppTheme.greyLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
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
