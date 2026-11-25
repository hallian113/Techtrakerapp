// ignore_for_file: duplicate_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tracking_app/providers/auth_provider.dart';
import 'package:tracking_app/utils/theme.dart';
import 'package:tracking_app/utils/page_transitions.dart';
import 'package:tracking_app/screens/admin_hours_history_screen.dart';
import 'package:tracking_app/screens/whos_working_screen.dart';
import 'package:tracking_app/utils/page_transitions.dart';
import 'package:tracking_app/screens/crew_screen.dart';
import 'package:tracking_app/screens/settings_screen.dart';
import 'package:tracking_app/screens/help_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.black, AppTheme.blackLight],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
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
                        authProvider.userName.isNotEmpty
                            ? authProvider.userName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          authProvider.isAdmin ? 'Administrator' : 'Technician',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.greyDark, height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _MoreTile(
                    icon: Icons.groups_outlined,
                    label: 'Crew',
                    onTap: () {
                      Navigator.push(
                        context,
                        slideFadeRoute(const CrewScreen()),
                      );
                    },
                  ),
                  _MoreTile(
                    icon: Icons.map_outlined,
                    label: "Who's working",
                    onTap: () {
                      Navigator.push(
                        context,
                        slideFadeRoute(const WhosWorkingScreen()),
                      );
                    },
                  ),
                  _MoreTile(
                    icon: Icons.people_alt_outlined,
                    label: 'My team',
                    onTap: () {
                      Navigator.push(
                        context,
                        slideFadeRoute(const CrewScreen()),
                      );
                    },
                  ),
                  _MoreTile(
                    icon: Icons.assignment_outlined,
                    label: 'Manage customers',
                    onTap: () => _comingSoon(context, 'Manage customers'),
                  ),
                  _MoreTile(
                    icon: Icons.pie_chart_outline,
                    label: 'Hours by team member',
                    onTap: () {
                      Navigator.push(
                        context,
                        slideFadeRoute(const AdminHoursHistoryScreen()),
                      );
                    },
                  ),
                  _MoreTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () => _comingSoon(context, 'Notifications'),
                  ),
                  _MoreTile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        slideFadeRoute(const SettingsScreen()),
                      );
                    },
                  ),
                  _MoreTile(
                    icon: Icons.help_outline,
                    label: 'Help',
                    onTap: () {
                      Navigator.push(context, slideFadeRoute(HelpScreen()));
                    },
                  ),
                  const Divider(color: AppTheme.greyDark, height: 32),
                  _MoreTile(
                    icon: Icons.logout,
                    label: 'Logout',
                    iconColor: AppTheme.error,
                    textColor: AppTheme.error,
                    onTap: () async {
                      await authProvider.logout();
                      if (context.mounted) {
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
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    Fluttertoast.showToast(msg: '$feature — coming soon');
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _MoreTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppTheme.greyLight, size: 24),
      title: Text(
        label,
        style: TextStyle(fontSize: 16, color: textColor ?? Colors.white),
      ),
      onTap: onTap,
    );
  }
}
