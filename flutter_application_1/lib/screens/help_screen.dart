import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tracking_app/utils/theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  final List<Map<String, String>> _faqs = const [
    {
      'q': 'How do I punch in or out?',
      'a':
          'Go to Home, tap the PUNCH IN / PUNCH OUT button, allow location access if asked, and confirm.',
    },
    {
      'q': 'Why does the app need my location?',
      'a':
          'Location is used to record where you punched in/out and to track your work journey while punched in, for accurate attendance and field reporting.',
    },
    {
      'q':
          'My punch-in session didn\'t save after restarting the app. What do I do?',
      'a':
          'Make sure you have an internet connection when punching in/out. The app automatically restores your session when the app reopens, using your latest record on the server.',
    },
    {
      'q': 'Can I see my past attendance?',
      'a':
          'Yes — go to History from the bottom navigation to see your attendance records by date, including your location journey for each session.',
    },
    {
      'q': 'I forgot to punch out. What should I do?',
      'a':
          'Punch out as soon as you remember. If the time recorded is incorrect, contact your admin to review or correct the record.',
    },
    {
      'q': 'Who can see my location data?',
      'a':
          'Only your company admin can see your location and attendance data. It is used solely for attendance and field-tracking purposes.',
    },
  ];

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@cargent.ca',
      query: 'subject=TechTracker Support',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.gold),
        title: const Text(
          'Help',
          style: TextStyle(color: Colors.white, fontSize: 18),
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'FREQUENTLY ASKED QUESTIONS',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.greyMedium,
                ),
              ),
              const SizedBox(height: 12),
              ..._faqs.map(
                (faq) => _FaqTile(question: faq['q']!, answer: faq['a']!),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.blackCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.gold.withOpacity(0.15)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.support_agent, color: AppTheme.gold, size: 36),
                    const SizedBox(height: 12),
                    const Text(
                      'Still need help?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reach out to your admin or contact support.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.greyLight, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _contactSupport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        foregroundColor: AppTheme.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.email_outlined, size: 18),
                      label: const Text('Email Support'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.blackCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold.withOpacity(0.12)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (v) => setState(() => _expanded = v),
          iconColor: AppTheme.gold,
          collapsedIconColor: AppTheme.greyMedium,
          title: Text(
            widget.question,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: _expanded ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.answer,
              style: TextStyle(
                color: AppTheme.greyLight,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
