import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../services/seed_service.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SeedService _seedService = SeedService();
  bool _isSeeding = false;

  Future<void> _seedDatabase() async {
    setState(() => _isSeeding = true);
    try {
      final service = Provider.of<FirebaseService>(context, listen: false);
      await _seedService.seedDatabase(service.user?.uid ?? 'unknown');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database seeded with sample items and matches!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error seeding: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  Future<void> _editProfile(UserProfile? profile) async {
    if (profile == null) return;
    
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _EditProfileDialog(initialName: profile.displayName ?? ''),
    );
    
    if (newName != null && newName.isNotEmpty && mounted) {
      try {
        final service = Provider.of<FirebaseService>(context, listen: false);
        await service.updateUserProfile(profile.id, displayName: newName);
        
        // Clear cache to force refresh
        service.clearProfileCache();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile updated!'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          );
          // Refresh the screen
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);
    final userId = firebaseService.user?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FutureBuilder<UserProfile?>(
          future: firebaseService.getUserProfile(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final profile = snapshot.data;
            final trustScore = profile?.trustScore ?? 5.0;
            final completedTrades = profile?.completedTrades ?? 0;
            final totalRatings = profile?.totalRatings ?? 0;

            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                  const SizedBox(height: 20),
                  // Profile Header
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(Icons.person, size: 60, color: Theme.of(context).scaffoldBackgroundColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '> ${(profile?.displayName ?? 'SURVIVOR').toUpperCase()}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${userId.substring(0, 8).toUpperCase()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Stats Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Trust Score',
                            trustScore.toStringAsFixed(1),
                            Icons.star,
                            _getTrustColor(trustScore),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard('Trades', completedTrades.toString(), Icons.swap_horiz, Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard('Ratings', totalRatings.toString(), Icons.rate_review, Colors.orange),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Settings List
                  _buildSettingsTile(icon: Icons.person_outline, title: 'Edit Profile', onTap: () => _editProfile(profile)),
                  _buildSettingsTile(
                    icon: Icons.location_on_outlined,
                    title: 'Location Settings',
                    subtitle: 'Montreal, QC',
                    onTap: () {},
                  ),
                  _buildSettingsTile(icon: Icons.notifications_outlined, title: 'Notifications', onTap: () {}),
                  _buildSettingsTile(icon: Icons.security_outlined, title: 'Privacy & Safety', onTap: () {}),
                  _buildSettingsTile(icon: Icons.help_outline, title: 'Help & Support', onTap: () {}),
                  _buildSettingsTile(icon: Icons.info_outline, title: 'About', subtitle: 'Bartr v1.0.0', onTap: () {}),
                  const SizedBox(height: 16),
                  _buildSettingsTile(
                    icon: _isSeeding ? Icons.hourglass_empty : Icons.science,
                    title: 'Seed Database',
                    subtitle: 'Add sample items for testing',
                    iconColor: Theme.of(context).colorScheme.secondary,
                    onTap: _isSeeding ? () {} : _seedDatabase,
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsTile(
                    icon: Icons.logout,
                    title: 'Change User',
                    subtitle: 'Sign out and create new account',
                    iconColor: Theme.of(context).colorScheme.secondary,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          title: Text('Change User', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                          content: Text(
                            'Sign out and create a new anonymous account with a fresh starter item?',
                            style: TextStyle(color: Theme.of(context).colorScheme.primary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.secondary,
                              ),
                              child: const Text('Change User'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        await firebaseService.signOut();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Signed out! Restart app to create new user.'),
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                            ),
                          );
                        }
                      }
                    },
                  ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
          ),
          subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])) : null,
          trailing: Icon(Icons.chevron_right, color: Colors.grey[700]),
          onTap: onTap,
        ),
      ),
    );
  }

  Color _getTrustColor(double score) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.orange;
    return Colors.red;
  }
}

class _EditProfileDialog extends StatefulWidget {
  final String initialName;

  const _EditProfileDialog({required this.initialName});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text('Edit Profile', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        autocorrect: false,
        keyboardType: TextInputType.name,
        decoration: InputDecoration(
          labelText: 'Display Name',
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
          border: OutlineInputBorder(),
        ),
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            Navigator.of(context).pop(value.trim());
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ),
        TextButton(
          onPressed: () {
            final newName = _controller.text.trim();
            if (newName.isNotEmpty) {
              Navigator.of(context).pop(newName);
            }
          },
          child: Text('Save', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
        ),
      ],
    );
  }
}
