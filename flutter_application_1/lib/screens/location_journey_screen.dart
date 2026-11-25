import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tracking_app/models/attendance_model.dart';
import 'package:tracking_app/models/location_model.dart';
import 'package:tracking_app/utils/theme.dart';
import 'package:tracking_app/utils/helpers.dart';

class LocationJourneyScreen extends StatefulWidget {
  final AttendanceModel record;
  final List<LocationModel> locations;
  final bool isLive;

  const LocationJourneyScreen({
    super.key,
    required this.record,
    required this.locations,
    this.isLive = false,
  });

  @override
  State<LocationJourneyScreen> createState() => _LocationJourneyScreenState();
}

class _LocationJourneyScreenState extends State<LocationJourneyScreen> {
  final MapController _mapController = MapController();
  int _currentStopIndex = -1; // -1 = no stop selected yet (showing full route)
  bool _showStopsList = false;
  List<LatLng> get _points =>
      widget.locations.map((l) => LatLng(l.latitude, l.longitude)).toList();

  void _goToStop(int index) {
    if (widget.locations.isEmpty) return;
    setState(() {
      _currentStopIndex = index;
    });
    final point = _points[index];
    _mapController.move(point, 16);
  }

  void _nextStop() {
    if (widget.locations.isEmpty) return;
    final next = (_currentStopIndex + 1) % widget.locations.length;
    _goToStop(next);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.locations.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.black,
        appBar: AppBar(
          backgroundColor: AppTheme.black,
          iconTheme: const IconThemeData(color: AppTheme.gold),
          title: Text(
            '${widget.record.userName} — ${widget.record.punchTypeDisplayName}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        body: Center(
          child: Text(
            'No location records for this session',
            style: TextStyle(color: AppTheme.greyMedium),
          ),
        ),
      );
    }

    final points = _points;

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: points[points.length ~/ 2],
              initialZoom: 14,
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
              _AnimatedRoute(points: points),
              MarkerLayer(markers: _buildMarkers(points)),
            ],
          ),
          _buildTopBar(context),
          _buildStopsListPanel(context),
          _buildBottomStats(context),
          Positioned(
            right: 10,
            bottom: 96,
            child: Text(
              '© OpenStreetMap contributors',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(List<LatLng> points) {
    final markers = <Marker>[];
    for (int i = 0; i < points.length; i++) {
      final isFirst = i == 0;
      final isLast = i == points.length - 1;
      final isSelected = i == _currentStopIndex;
      Color color;
      Widget icon;
      double size = 32;

      if (isFirst) {
        color = AppTheme.success;
        icon = const Icon(Icons.check, color: Colors.white, size: 16);
        size = 36;
      } else if (isLast) {
        if (widget.isLive) {
          color = AppTheme.gold;
          icon = const Icon(Icons.my_location, color: AppTheme.black, size: 16);
        } else {
          color = AppTheme.error;
          icon = const Icon(Icons.flag, color: Colors.white, size: 14);
        }
        size = 36;
      } else {
        color = AppTheme.blackCard;
        icon = Text(
          '$i',
          style: const TextStyle(
              color: AppTheme.gold, fontSize: 10, fontWeight: FontWeight.bold),
        );
        size = 22;
      }

      if (isSelected) size += 8;

      markers.add(
        Marker(
          point: points[i],
          width: size,
          height: size,
          child: GestureDetector(
            onTap: () => _goToStop(i),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.gold : Colors.white,
                  width: isSelected ? 3 : (isFirst || isLast ? 2 : 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: isSelected ? 12 : 8,
                    spreadRadius:
                        (widget.isLive && isLast) || isSelected ? 3 : 0,
                  ),
                ],
              ),
              child: Center(child: icon),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          right: 12,
          bottom: 24,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.black.withOpacity(0.95), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: AppTheme.blackCard, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back,
                    color: AppTheme.gold, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.record.userName} — ${widget.record.punchTypeDisplayName}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    Helpers.formatDateTime(widget.record.timestamp),
                    style: TextStyle(color: AppTheme.greyLight, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (widget.isLive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          color: AppTheme.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    const Text('Live',
                        style:
                            TextStyle(color: AppTheme.success, fontSize: 10)),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _showStopsList = !_showStopsList),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _showStopsList ? AppTheme.gold : AppTheme.blackCard,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.list_alt,
                  color: _showStopsList ? AppTheme.black : AppTheme.gold,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopsListPanel(BuildContext context) {
    if (!_showStopsList) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      right: 12,
      child: Container(
        width: 240,
        constraints: const BoxConstraints(maxHeight: 340),
        decoration: BoxDecoration(
          color: AppTheme.blackCard.withOpacity(0.97),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Stops',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  Text(
                    '${widget.locations.length} total',
                    style: TextStyle(color: AppTheme.greyMedium, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.greyDark, height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: widget.locations.length,
                itemBuilder: (context, index) {
                  final loc = widget.locations[index];
                  final isSelected = index == _currentStopIndex;
                  final isFirst = index == 0;
                  final isLast = index == widget.locations.length - 1;
                  return InkWell(
                    onTap: () {
                      _goToStop(index);
                      setState(() => _showStopsList = false);
                    },
                    child: Container(
                      color: isSelected
                          ? AppTheme.gold.withOpacity(0.12)
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isFirst
                                  ? AppTheme.success
                                  : isLast
                                      ? AppTheme.error
                                      : AppTheme.blackLight,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.locationName ?? 'Unknown location',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                                Text(
                                  loc.timeString,
                                  style: TextStyle(
                                      color: AppTheme.greyMedium, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomStats(BuildContext context) {
    final duration = widget.isLive
        ? DateTime.now().difference(widget.record.timestamp)
        : (widget.locations.length > 1
            ? widget.locations.last.timestamp
                .difference(widget.locations.first.timestamp)
            : Duration.zero);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [AppTheme.black, Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stopsStatChip(),
            _statChip(Icons.timer, '${hours}h ${minutes}m', 'Duration'),
            _statChip(Icons.flag_circle, widget.isLive ? 'Ongoing' : 'Ended',
                'Status'),
          ],
        ),
      ),
    );
  }

  // 👆 Tappable stops chip — cycles through each stop on tap
  Widget _stopsStatChip() {
    final label = _currentStopIndex == -1
        ? '${widget.locations.length}'
        : 'Stop ${_currentStopIndex + 1}/${widget.locations.length}';

    return GestureDetector(
      onTap: _nextStop,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.blackCard.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _currentStopIndex == -1
                ? AppTheme.gold.withOpacity(0.2)
                : AppTheme.gold,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.pin_drop, color: AppTheme.gold, size: 16),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text('Tap to visit',
                style: TextStyle(color: AppTheme.greyMedium, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.blackCard.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.gold, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label,
              style: TextStyle(color: AppTheme.greyMedium, fontSize: 10)),
        ],
      ),
    );
  }
}

// 🎬 Animates the route line drawing itself progressively
class _AnimatedRoute extends StatefulWidget {
  final List<LatLng> points;
  const _AnimatedRoute({required this.points});

  @override
  State<_AnimatedRoute> createState() => _AnimatedRouteState();
}

class _AnimatedRouteState extends State<_AnimatedRoute>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900 + widget.points.length * 120),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<LatLng> _visiblePoints(double t) {
    if (widget.points.length < 2) return widget.points;
    final totalSegments = widget.points.length - 1;
    final progress = t * totalSegments;
    final fullSegments = progress.floor().clamp(0, totalSegments);
    final segmentT = progress - fullSegments;
    final result = widget.points.sublist(0, fullSegments + 1);
    if (fullSegments < totalSegments) {
      final start = widget.points[fullSegments];
      final end = widget.points[fullSegments + 1];
      final lat = start.latitude + (end.latitude - start.latitude) * segmentT;
      final lng =
          start.longitude + (end.longitude - start.longitude) * segmentT;
      result.add(LatLng(lat, lng));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final pts = _visiblePoints(_animation.value);
        return PolylineLayer(
          polylines: [
            Polyline(points: pts, color: AppTheme.gold, strokeWidth: 4),
          ],
        );
      },
    );
  }
}
