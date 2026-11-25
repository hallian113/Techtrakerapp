import 'package:flutter/material.dart';
import 'package:tracking_app/models/user_model.dart';
import 'package:tracking_app/services/database_service.dart';
import 'package:tracking_app/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:tracking_app/providers/auth_provider.dart';
import 'package:tracking_app/screens/register_screen.dart';

class CrewScreen extends StatefulWidget {
  const CrewScreen({super.key});

  @override
  State<CrewScreen> createState() => _CrewScreenState();
}

class _CrewScreenState extends State<CrewScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final users = await _databaseService.getAllUsers();
      // Sort: admins first, then alphabetical by name
      users.sort((a, b) {
        if (a.role != b.role) {
          return a.role == 'admin' ? -1 : 1;
        }
        return a.name.compareTo(b.name);
      });
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmRemove(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.blackCard,
        title: const Text('Remove team member?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '${user.name} will lose access and be removed from the crew list. Their attendance history will be kept.',
          style: TextStyle(color: AppTheme.greyLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child:
                const Text('Remove', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deactivateUser(user.id);
        _load();
      } catch (e) {
        // Silent fail - could show a toast here if desired
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.gold),
        title: const Text('Crew',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      floatingActionButton: authProvider.isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.gold,
              foregroundColor: AppTheme.black,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Tech'),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
                _load(); // refresh list after adding
              },
            )
          : null,
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
                : _users.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 120),
                          Icon(Icons.groups_outlined,
                              size: 64, color: AppTheme.gold.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Center(
                            child: Text('No crew members found',
                                style: TextStyle(color: AppTheme.greyMedium)),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final isAdmin = user.role == 'admin';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.blackCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppTheme.gold.withOpacity(0.15)),
                            ),
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
                                      user.initials,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.black,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user.email,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.greyLight,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isAdmin
                                        ? AppTheme.gold.withOpacity(0.15)
                                        : AppTheme.success.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    user.roleDisplayName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isAdmin
                                          ? AppTheme.gold
                                          : AppTheme.success,
                                    ),
                                  ),
                                ),
                                if (authProvider.isAdmin &&
                                    user.id != authProvider.userId) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.person_remove,
                                        color: AppTheme.error, size: 20),
                                    onPressed: () => _confirmRemove(user),
                                  ),
                                ],
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
