// lib/screens/unified_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fouta_app/main.dart';
import 'package:fouta_app/screens/account_settings_screen.dart';
import 'package:fouta_app/screens/data_saver_screen.dart';
import 'package:fouta_app/screens/privacy_settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:fouta_app/theme/theme_controller.dart';
import 'package:fouta_app/utils/snackbar.dart';
import 'package:fouta_app/screens/report_bug_screen.dart';
import 'package:fouta_app/utils/overlays.dart';
import 'package:fouta_app/services/push_notification_service.dart';
import 'package:fouta_app/utils/firestore_paths.dart';

class UnifiedSettingsScreen extends StatefulWidget {
  const UnifiedSettingsScreen({super.key});

  @override
  State<UnifiedSettingsScreen> createState() => _UnifiedSettingsScreenState();
}

class _UnifiedSettingsScreenState extends State<UnifiedSettingsScreen> {
  final _newPasswordController = TextEditingController();
  bool _pushEnabled = false;
  Map<String, bool> _notifPrefs = {
    'follows': true,
    'comments': true,
    'likes': true,
    'reposts': true,
    'mentions': true,
    'messages': true,
  };

  @override
  void initState() {
    super.initState();
    _loadPushPref();
    _loadNotificationPrefs();
  }

  Future<void> _loadPushPref() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection(FirestorePaths.users())
        .doc(uid)
        .collection('meta')
        .doc('token')
        .get();
    if (mounted) {
      setState(() => _pushEnabled = doc.exists);
    }
  }

  Future<void> _loadNotificationPrefs() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection(FirestorePaths.users())
        .doc(uid)
        .collection('settings')
        .doc('notifications')
        .get();
    if (doc.exists && mounted) {
      final data = doc.data() ?? {};
      setState(() {
        for (final entry in data.entries) {
          _notifPrefs[entry.key] = entry.value == true;
        }
      });
    }
  }

  Future<void> _updateNotificationPref(String key, bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _notifPrefs[key] = value);
    await FirebaseFirestore.instance
        .collection(FirestorePaths.users())
        .doc(uid)
        .collection('settings')
        .doc('notifications')
        .set({key: value}, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
      ),
    );

  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('You must be logged in to change your password.', isError: true);
      return;
    }

    showFoutaDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: TextField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New Password'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                _newPasswordController.clear();
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Change'),
              onPressed: () async {
                final newPassword = _newPasswordController.text.trim();
                if (newPassword.length < 6) {
                  _showMessage('Password must be at least 6 characters.', isError: true);
                  return;
                }
                try {
                  await user.updatePassword(newPassword);
                  _showMessage('Password changed successfully!');
                  _newPasswordController.clear();
                  Navigator.of(context).pop();
                } on FirebaseAuthException catch (e) {
                  String errorMessage = 'Failed to change password: ${e.message}';
                  if (e.code == 'requires-recent-login') {
                    errorMessage = 'This is a sensitive operation. Please log out and log back in before changing your password.';
                  }
                  _showMessage(errorMessage, isError: true);
                } catch (e) {
                  _showMessage('An unexpected error occurred: $e', isError: true);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('You must be logged in to delete your account.', isError: true);
      return;
    }

    showFoutaDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('Are you sure you want to delete your account? This action cannot be undone and will delete your profile, posts, and all associated data.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
              onPressed: () async {
                try {
                  // This is a sensitive operation, so we close the dialog first
                  Navigator.of(context).pop(); 
                  _showMessage('Deleting account...');

                  await FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(user.uid).delete();
                  await user.delete();

                  _showMessage('Account deleted successfully.');
                  // Pop all routes until the first one (AuthWrapper)
                  if(mounted) Navigator.of(context).popUntil((route) => route.isFirst);
                } on FirebaseAuthException catch (e) {
                  String errorMessage = 'Failed to delete account: ${e.message}';
                  if (e.code == 'requires-recent-login') {
                    errorMessage = 'This is a sensitive operation. Please log out and log back in before deleting your account.';
                  }
                  _showMessage(errorMessage, isError: true);
                } catch (e) {
                  _showMessage('An unexpected error occurred: $e', isError: true);
                }
              },
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('ACCOUNT'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Personal Information'),
            subtitle: const Text('Update your name, phone, city'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountSettingsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            onTap: _changePassword,
          ),

          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Settings'),
            subtitle: const Text('Control who sees your profile and posts'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.data_saver_on_outlined),
            title: const Text('Data Saver'),
            subtitle: const Text('Manage video autoplay settings'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DataSaverScreen()));
            },
          ),
          _buildSectionHeader('PRIVACY & DATA'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Settings'),
            subtitle: const Text('Control who sees your profile and posts'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.data_saver_on_outlined),
            title: const Text('Data Saver'),
            subtitle: const Text('Manage video autoplay settings'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DataSaverScreen()));
            },
          ),

          // TODO: Re-enable AR Camera once integrated into marketplace furniture placement
          // if (const bool.fromEnvironment('AR_EXPERIMENTAL'))
          //   ListTile(
          //     leading: const Icon(Icons.auto_awesome_outlined),
          //     title: const Text('AR Camera'),
          //     onTap: () {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(builder: (_) => const ArCameraScreen()),
          //       );
          //     },
          //   ),

          _buildSectionHeader('APP'),

          SwitchListTile(
            title: const Text('Push notifications (opt in)'),
            value: _pushEnabled,
            onChanged: (value) async {
              setState(() => _pushEnabled = value);
              if (value) {
                await PushNotificationService.enablePush();
              } else {
                await PushNotificationService.disablePush();
              }
            },
          ),

          _buildSectionHeader('NOTIFICATIONS'),
          SwitchListTile(
            title: const Text('Follows'),
            value: _notifPrefs['follows'] ?? true,
            onChanged: (v) => _updateNotificationPref('follows', v),
          ),
          SwitchListTile(
            title: const Text('Comments'),
            value: _notifPrefs['comments'] ?? true,
            onChanged: (v) => _updateNotificationPref('comments', v),
          ),
          SwitchListTile(
            title: const Text('Likes'),
            value: _notifPrefs['likes'] ?? true,
            onChanged: (v) => _updateNotificationPref('likes', v),
          ),
          SwitchListTile(
            title: const Text('Reposts'),
            value: _notifPrefs['reposts'] ?? true,
            onChanged: (v) => _updateNotificationPref('reposts', v),
          ),
          SwitchListTile(
            title: const Text('Mentions'),
            value: _notifPrefs['mentions'] ?? true,
            onChanged: (v) => _updateNotificationPref('mentions', v),
          ),
          SwitchListTile(
            title: const Text('Messages'),
            value: _notifPrefs['messages'] ?? true,
            onChanged: (v) => _updateNotificationPref('messages', v),
          ),

          // Theme mode selection using ThemeController.
          Consumer<ThemeController>(
            builder: (context, controller, _) {
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Theme: Auto'),
                    trailing: controller.themeMode == ThemeMode.system
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => controller.setMode(ThemeMode.system),
                  ),
                  ListTile(
                    leading: const SizedBox(width: 24),
                    title: const Text('Theme: Light'),
                    trailing: controller.themeMode == ThemeMode.light
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => controller.setMode(ThemeMode.light),
                  ),
                  ListTile(
                    leading: const SizedBox(width: 24),
                    title: const Text('Theme: Dark'),
                    trailing: controller.themeMode == ThemeMode.dark
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => controller.setMode(ThemeMode.dark),
                  ),
                ],
              );
            },
            ),

            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Report a Bug'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportBugScreen()),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Fouta'),
              onTap: () {
                 _showMessage('Fouta App v1.9.0');
              },
            ),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
            title: Text('Delete Account', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: _deleteAccount,
          ),
        ],
      ),
    );
  }
}