import 'package:flutter/material.dart';
import 'package:tracking_app/models/location_model.dart';
import 'package:tracking_app/utils/theme.dart';
import 'package:tracking_app/utils/helpers.dart';

class LocationTile extends StatelessWidget {
  final LocationModel location;
  final VoidCallback? onTap;

  const LocationTile({super.key, required this.location, this.onTap});

  @override
  Widget build(BuildContext context) {
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
            // 🟢 Location Icon
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
            // 📍 Location Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.locationName ?? 'Unknown Location',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location.address ?? location.locationString,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.greyLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.greyMedium,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        Helpers.formatDateTime(location.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.greyMedium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (location.speed != null)
                        Row(
                          children: [
                            Icon(
                              Icons.speed,
                              size: 14,
                              color: AppTheme.greyMedium,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${location.speed!.toStringAsFixed(1)} km/h',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.greyMedium,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // 🥇 Gold Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.gold.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
