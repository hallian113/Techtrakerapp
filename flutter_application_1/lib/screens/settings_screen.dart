import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracking_app/providers/auth_provider.dart';
import 'package:tracking_app/utils/theme.dart';
import 'package:tracking_app/utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notificationsEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.gold),
        title: const Text('Settings',
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionLabel('ACCOUNT'),
              _card(
                child: Column(
                  children: [
                    _infoRow('Name', authProvider.userName),
                    const Divider(color: AppTheme.greyDark, height: 20),
                    _infoRow('Email', authProvider.userEmail),
                    const Divider(color: AppTheme.greyDark, height: 20),
                    _infoRow('Role',
                        authProvider.isAdmin ? 'Administrator' : 'Technician'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _sectionLabel('PREFERENCES'),
              _card(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Notifications',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 15)),
                          SizedBox(height: 2),
                          Text('Receive punch and activity alerts',
                              style: TextStyle(
                                  color: AppTheme.greyMedium, fontSize: 12)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _notificationsEnabled,
                      activeColor: AppTheme.gold,
                      onChanged: _toggleNotifications,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _sectionLabel('ABOUT'),
              _card(
                child: Column(
                  children: [
                    _infoRow('App Version', AppConstants.appVersion),
                    const Divider(color: AppTheme.greyDark, height: 20),
                    _infoRow('App Name', AppConstants.appName),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w600,
          color: AppTheme.greyMedium,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.blackCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withOpacity(0.15)),
      ),
      child: child,
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppTheme.greyLight, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
