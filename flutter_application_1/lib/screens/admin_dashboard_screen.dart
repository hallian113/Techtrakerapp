// ignore_for_file: unused_element

import 'dart:async';
import 'package:shimmer/shimmer.dart';
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
import 'package:tracking_app/models/tech_hours_summary.dart';
import 'package:tracking_app/screens/admin_hours_history_screen.dart';
import 'package:intl/intl.dart';
import 'package:tracking_app/utils/page_transitions.dart';
import 'package:tracking_app/screens/more_screen.dart';
import 'package:timezone/timezone.dart' as tz;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  Timer? _refreshTimer;
  int _totalsTabIndex = 0; // 0 = Day, 1 = Week, 2 = Pay Period
  int _summaryTabIndex = 0; // 0 = Week, 1 = Pay Period
  Duration _totalCompanyHours = Duration.zero;
  List<TechHoursSummary> _rangeSummaries = [];
  bool _loadingTotals = false;
  bool _loadingSummary = false;
  List<TechHoursSummary> _customerSummaries = [];
  bool _loadingCustomerSummary = false;
  Timer? _clockTimer;
  String _currentTimeText = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAdminData();
      _loadTotalsForTab();
      _loadSummaryForTab();
      _loadCustomerSummary();
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _loadAdminData();
    });
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateClock();
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

  Future<void> _loadTotalsForTab() async {
    if (!mounted) return;
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    setState(() => _loadingTotals = true);
    DateTimeRange range;
    if (_totalsTabIndex == 0) {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));
      range = DateTimeRange(start: start, end: end);
    } else if (_totalsTabIndex == 1) {
      range = attendanceProvider.getCurrentWeekRange();
    } else {
      range = attendanceProvider.getCurrentPayPeriodRange();
    }
    final total = await attendanceProvider.getTotalCompanyHoursForRange(range);
    if (!mounted) return;
    setState(() {
      _totalCompanyHours = total;
      _loadingTotals = false;
    });
  }

  Future<void> _loadSummaryForTab() async {
    if (!mounted) return;
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    setState(() => _loadingSummary = true);
    final range = _summaryTabIndex == 0
        ? attendanceProvider.getCurrentWeekRange()
        : attendanceProvider.getCurrentPayPeriodRange();
    final summaries = await attendanceProvider.calculateHoursForRange(range);
    if (!mounted) return;
    setState(() {
      _rangeSummaries = summaries;
      _loadingSummary = false;
    });
  }

  Future<void> _loadCustomerSummary() async {
    if (!mounted) return;
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    setState(() => _loadingCustomerSummary = true);
    final range = attendanceProvider.getCurrentWeekRange();
    final summaries =
        await attendanceProvider.calculateCustomerHoursForRange(range);
    if (!mounted) return;
    setState(() {
      _customerSummaries = summaries;
      _loadingCustomerSummary = false;
    });
  }

  void _updateClock() {
    if (!mounted) return;
    try {
      final toronto = tz.getLocation('America/Toronto');
      final now = tz.TZDateTime.now(toronto);
      final hour = now.hour;
      final minute = now.minute.toString().padLeft(2, '0');
      final second = now.second.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      setState(() {
        _currentTimeText = '$hour12:$minute:$second $ampm';
      });
    } catch (e) {
      // Silent fail - clock just won't update
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  Widget _shimmerBox({double height = 60, double? width}) {
    return Shimmer.fromColors(
      baseColor: AppTheme.blackCard,
      highlightColor: AppTheme.blackLight,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.blackCard,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _clockTimer?.cancel();
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
        return _buildTrackingTab(locationProvider, attendanceProvider);
      case 3:
        return const MoreScreen();
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
                  Expanded(
                    child: Column(
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
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
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
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule,
                              size: 12, color: AppTheme.greyMedium),
                          const SizedBox(width: 4),
                          Text(
                            _currentTimeText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.greyLight,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Toronto, ON',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.greyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              _buildTotalsRingCard(attendanceProvider),

              const SizedBox(height: 20),

              _buildTeamHoursSummaryCard(attendanceProvider),

              const SizedBox(height: 20),

              _buildTeamWeekSummaryCard(),

              const SizedBox(height: 30),

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
                      _getActiveCount(attendanceProvider),
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

              const SizedBox(height: 20),

              _buildTodayHoursSection(attendanceProvider),

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
                    _buildLocationMap(locationProvider, attendanceProvider),
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

  Widget _buildTodayHoursSection(AttendanceProvider attendanceProvider) {
    final now = DateTime.now();
    final todayRecords = attendanceProvider.attendanceHistory
        .where((r) =>
            r.timestamp.year == now.year &&
            r.timestamp.month == now.month &&
            r.timestamp.day == now.day)
        .toList();

    final summaries = attendanceProvider.calculateDailyHours(todayRecords);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.blackCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withOpacity(0.15), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: AppTheme.gold, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Today's Hours",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    slideFadeRoute(const AdminHoursHistoryScreen()),
                  );
                },
                child: const Row(
                  children: [
                    Text('View History',
                        style: TextStyle(fontSize: 12, color: AppTheme.gold)),
                    Icon(Icons.arrow_forward_ios,
                        size: 12, color: AppTheme.gold),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (summaries.isEmpty)
            const Text('No hours recorded today',
                style: TextStyle(color: AppTheme.greyMedium))
          else
            ...summaries.asMap().entries.map((entry) {
              return _buildHoursRow(entry.key + 1, entry.value);
            }),
        ],
      ),
    );
  }

  Widget _buildTotalsRingCard(AttendanceProvider attendanceProvider) {
    final labels = ['Day Total', 'Week Total', 'Pay Period'];
    final target = _totalsTabIndex == 0
        ? const Duration(hours: 8)
        : _totalsTabIndex == 1
            ? const Duration(hours: 40)
            : const Duration(hours: 80);
    final progress = target.inMinutes == 0
        ? 0.0
        : (_totalCompanyHours.inMinutes / target.inMinutes).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.blackCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withOpacity(0.15), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(labels.length, (index) {
              final isSelected = _totalsTabIndex == index;
              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _totalsTabIndex = index);
                    _loadTotalsForTab();
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labels[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.success
                              : AppTheme.greyLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isSelected)
                        Container(
                            height: 2, width: 60, color: AppTheme.success),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: _loadingTotals ? null : progress,
                  strokeWidth: 6,
                  backgroundColor: AppTheme.blackLight,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.gold),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _loadingTotals
                          ? 'Loading...'
                          : _formatDuration(_totalCompanyHours),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'of ${target.inHours} hours (all techs)',
                      style:
                          TextStyle(fontSize: 12, color: AppTheme.greyMedium),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamHoursSummaryCard(AttendanceProvider attendanceProvider) {
    final range = _summaryTabIndex == 0
        ? attendanceProvider.getCurrentWeekRange()
        : attendanceProvider.getCurrentPayPeriodRange();
    final rangeLabel =
        '${DateFormat('MMM d').format(range.start)} - ${DateFormat('MMM d, yyyy').format(range.end)}';

    Duration totalAll = Duration.zero;
    for (var s in _rangeSummaries) {
      totalAll += s.totalDuration;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.blackCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withOpacity(0.15), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOURS BY TEAM MEMBER SUMMARY',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.5,
              color: AppTheme.greyMedium,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => _summaryTabIndex = 0);
                  _loadSummaryForTab();
                },
                child: Text(
                  'Week',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: _summaryTabIndex == 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _summaryTabIndex == 0
                        ? AppTheme.success
                        : AppTheme.greyLight,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () {
                  setState(() => _summaryTabIndex = 1);
                  _loadSummaryForTab();
                },
                child: Text(
                  'Pay Period',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: _summaryTabIndex == 1
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _summaryTabIndex == 1
                        ? AppTheme.success
                        : AppTheme.greyLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(rangeLabel,
              style: TextStyle(fontSize: 13, color: AppTheme.greyLight)),
          const SizedBox(height: 8),
          Text(
            _loadingSummary ? '...' : _formatDuration(totalAll),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text('Total hours',
              style: TextStyle(fontSize: 12, color: AppTheme.greyMedium)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniStat('REG', totalAll.inHours.toString()),
              const SizedBox(width: 24),
              _buildMiniStat('PTO', '0'),
              const SizedBox(width: 24),
              _buildMiniStat('1.5x', '0'),
              const SizedBox(width: 24),
              _buildMiniStat('2x', '0'),
            ],
          ),
          const Divider(height: 24),
          if (_loadingSummary)
            Column(
              children: [
                _shimmerBox(height: 50),
                const SizedBox(height: 8),
                _shimmerBox(height: 50),
                const SizedBox(height: 8),
                _shimmerBox(height: 50),
              ],
            )
          else if (_rangeSummaries.isEmpty)
            const Text('No hours recorded for this period',
                style: TextStyle(color: AppTheme.greyMedium))
          else
            ..._rangeSummaries.asMap().entries.map((entry) {
              return _buildHoursRow(entry.key + 1, entry.value);
            }),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                slideFadeRoute(const AdminHoursHistoryScreen()),
              );
            },
            child: const Text('View report',
                style: TextStyle(fontSize: 13, color: Colors.lightBlueAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamWeekSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.blackCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withOpacity(0.15), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TEAM WEEK SUMMARY',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.5,
              color: AppTheme.greyMedium,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Weekly customers',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (_loadingCustomerSummary)
            Column(
              children: [
                _shimmerBox(height: 40),
                const SizedBox(height: 8),
                _shimmerBox(height: 40),
              ],
            )
          else if (_customerSummaries.isEmpty)
            const Text('No customer hours this week',
                style: TextStyle(color: AppTheme.greyMedium))
          else
            ..._customerSummaries.map((summary) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          summary.userName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          summary.formattedHours,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.greyLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Divider(color: AppTheme.gold.withOpacity(0.1), height: 1),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.greyMedium)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ],
    );
  }

  Widget _buildHoursRow(int rank, TechHoursSummary summary) {
    final isTop = rank == 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isTop ? AppTheme.gold : AppTheme.blackLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isTop ? AppTheme.black : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              summary.userName,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white),
            ),
          ),
          Text(
            summary.formattedHours,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isTop ? AppTheme.gold : AppTheme.greyLight,
            ),
          ),
        ],
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

  String _getActiveCount(AttendanceProvider attendanceProvider) {
    final Map<String, dynamic> latestByUser = {};
    for (var record in attendanceProvider.attendanceHistory) {
      final existing = latestByUser[record.userId];
      if (existing == null || record.timestamp.isAfter(existing.timestamp)) {
        latestByUser[record.userId] = record;
      }
    }
    final activeCount =
        latestByUser.values.where((r) => r.punchType == 'in').length;
    return activeCount.toString();
  }

  Set<String> _getActiveUserIds(AttendanceProvider attendanceProvider) {
    final Map<String, dynamic> latestByUser = {};
    for (var record in attendanceProvider.attendanceHistory) {
      final existing = latestByUser[record.userId];
      if (existing == null || record.timestamp.isAfter(existing.timestamp)) {
        latestByUser[record.userId] = record;
      }
    }
    return latestByUser.entries
        .where((e) => e.value.punchType == 'in')
        .map((e) => e.key)
        .toSet();
  }

  String _getTodayPunchCount(AttendanceProvider attendanceProvider) {
    final now = DateTime.now();
    return attendanceProvider.attendanceHistory
        .where((record) =>
            record.timestamp.year == now.year &&
            record.timestamp.month == now.month &&
            record.timestamp.day == now.day &&
            record.punchType == 'in')
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

  Widget _buildTrackingTab(LocationProvider locationProvider,
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
                  child:
                      _buildLocationMap(locationProvider, attendanceProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationMap(LocationProvider locationProvider,
      AttendanceProvider attendanceProvider) {
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

    final activeUserIds = _getActiveUserIds(attendanceProvider);
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
            ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                -0.9,
                0,
                0,
                0,
                255,
                0,
                -0.9,
                0,
                0,
                255,
                0,
                0,
                -0.9,
                0,
                255,
                0,
                0,
                0,
                1,
                0,
              ]),
              child: TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.cargent.techtracker',
              ),
            ),
            MarkerLayer(
              markers: locations.map((location) {
                final isActive = activeUserIds.contains(location.userId);
                return Marker(
                  point: LatLng(location.latitude, location.longitude),
                  width: 130,
                  height: 76,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.black.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (isActive
                                    ? AppTheme.success
                                    : AppTheme.greyMedium)
                                .withOpacity(0.4),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              location.userName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              isActive ? 'Live' : 'Last location',
                              style: TextStyle(
                                color: isActive
                                    ? AppTheme.success
                                    : AppTheme.greyMedium,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color:
                              isActive ? AppTheme.success : AppTheme.blackCard,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isActive ? Colors.white : AppTheme.greyMedium,
                            width: 2,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppTheme.success.withOpacity(0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          isActive ? Icons.my_location : Icons.location_off,
                          color: isActive ? Colors.white : AppTheme.greyMedium,
                          size: 15,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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
          icon: Icon(Icons.more_horiz),
          label: 'More',
        ),
      ],
    );
  }
}
