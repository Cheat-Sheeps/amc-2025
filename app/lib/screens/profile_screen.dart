import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                  _buildSettingsTile(icon: Icons.person_outline, title: 'Edit Profile', onTap: () {}),
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
                    icon: Icons.logout,
                    title: 'Sign Out',
                    iconColor: Colors.red,
                    titleColor: Colors.red,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Sign Out'),
                          content: const Text('Are you sure you want to sign out?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        // Sign out logic would go here
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out')));
                      }
                    },
                  ),
                  const SizedBox(height: 40),
                ],
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
