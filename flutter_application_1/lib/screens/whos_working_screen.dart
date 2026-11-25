import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tracking_app/providers/attendance_provider.dart';
import 'package:tracking_app/providers/location_provider.dart';
import 'package:tracking_app/utils/theme.dart';
import 'package:tracking_app/utils/helpers.dart';

class WhosWorkingScreen extends StatefulWidget {
  const WhosWorkingScreen({super.key});

  @override
  State<WhosWorkingScreen> createState() => _WhosWorkingScreenState();
}

class _WhosWorkingScreenState extends State<WhosWorkingScreen> {
  bool _isLoading = true;
  List<_WorkingTech> _workingTechs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);

    final history = await attendanceProvider.getAllAttendanceHistory();
    await locationProvider.getAllLatestLocations();

    // Find who is currently punched-in: latest record per user is "in"
    final Map<String, List<dynamic>> byUser = {};
    for (var record in history) {
      byUser.putIfAbsent(record.userId, () => []).add(record);
    }

    final List<_WorkingTech> working = [];
    byUser.forEach((userId, records) {
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final latest = records.first;
      if (latest.punchType == 'in') {
        final matchingLocation = locationProvider.locationHistory
            .where((l) => l.userId == userId)
            .toList();
        working.add(_WorkingTech(
          userId: userId,
          userName: latest.userName,
          punchInTime: latest.timestamp,
          locationName: matchingLocation.isNotEmpty
              ? matchingLocation.first.locationName
              : null,
        ));
      }
    });

    working.sort((a, b) => a.punchInTime.compareTo(b.punchInTime));

    if (mounted) {
      setState(() {
        _workingTechs = working;
        _isLoading = false;
      });
    }
  }

  String _durationSince(DateTime start) {
    final diff = DateTime.now().difference(start);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.gold),
        title: const Text("Who's Working",
            style: TextStyle(color: Colors.white, fontSize: 18)),
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
          child: RefreshIndicator(
            color: AppTheme.gold,
            backgroundColor: AppTheme.blackCard,
            onRefresh: _load,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.gold))
                : _workingTechs.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: 120),
                          Icon(Icons.nights_stay_outlined,
                              size: 64, color: AppTheme.gold.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Center(
                            child: Text('No one is currently working',
                                style: TextStyle(color: AppTheme.greyMedium)),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _workingTechs.length,
                        itemBuilder: (context, index) {
                          final tech = _workingTechs[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.blackCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppTheme.success.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.goldGradient,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          tech.userName.isNotEmpty
                                              ? tech.userName[0].toUpperCase()
                                              : 'T',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: AppTheme.success,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: AppTheme.blackCard,
                                              width: 2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tech.userName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Since ${Helpers.formatTime(tech.punchInTime)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.greyLight,
                                        ),
                                      ),
                                      if (tech.locationName != null) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on,
                                                size: 12,
                                                color: AppTheme.greyMedium),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                tech.locationName!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.greyMedium,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _durationSince(tech.punchInTime),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.gold,
                                      ),
                                    ),
                                    Text(
                                      'elapsed',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.greyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }
}

class _WorkingTech {
  final String userId;
  final String userName;
  final DateTime punchInTime;
  final String? locationName;

  _WorkingTech({
    required this.userId,
    required this.userName,
    required this.punchInTime,
    this.locationName,
  });
}
