class TechHoursSummary {
  final String userId;
  final String userName;
  final Duration totalDuration;

  TechHoursSummary({
    required this.userId,
    required this.userName,
    required this.totalDuration,
  });

  String get formattedHours {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}
