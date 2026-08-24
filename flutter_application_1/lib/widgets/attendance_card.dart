import 'package:flutter/material.dart';
import 'package:tracking_app/models/attendance_model.dart';
import 'package:tracking_app/utils/theme.dart';
import 'package:tracking_app/utils/helpers.dart';

class AttendanceCard extends StatelessWidget {
  final AttendanceModel attendance;
  final bool showUserInfo;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const AttendanceCard({
    super.key,
    required this.attendance,
    this.showUserInfo = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final punchColor =
        attendance.punchType == 'in' ? AppTheme.success : AppTheme.error;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: punchColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: punchColor.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  attendance.punchType == 'in' ? 'IN' : 'OUT',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: punchColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showUserInfo)
                    Text(
                      attendance.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  if (showUserInfo) const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: AppTheme.greyMedium),
                      const SizedBox(width: 4),
                      Text(
                        Helpers.formatDateTime(attendance.timestamp),
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.greyLight),
                      ),
                    ],
                  ),
                  if (attendance.locationName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: AppTheme.greyMedium),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            attendance.locationName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.greyMedium),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                attendance.punchTypeDisplayName,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.black,
                ),
              ),
            ),
            if (onDelete != null)
              IconButton(
                tooltip: 'Delete record',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: AppTheme.error),
              )
            else
              const Icon(Icons.chevron_right, color: AppTheme.greyMedium),
          ],
        ),
      ),
    );
  }
}
