// lib/screens/unified_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fouta_app/main.dart';
import 'package:fouta_app/screens/account_settings_screen.dart';
import 'package:fouta_app/screens/data_saver_screen.dart';
import 'package:fouta_app/screens/privacy_settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:fouta_app/services/theme_provider.dart';
import 'package:fouta_app/utils/snackbar.dart';

class UnifiedSettingsScreen extends StatefulWidget {
  const UnifiedSettingsScreen({super.key});

  @override
  State<UnifiedSettingsScreen> createState() => _UnifiedSettingsScreenState();
}

class _UnifiedSettingsScreenState extends State<UnifiedSettingsScreen> {
  final _newPasswordController = TextEditingController();

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

    showDialog(
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

    showDialog(
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
          
          _buildSectionHeader('APP'),

          // Theme mode selection using ThemeProvider.
          Builder(
            builder: (context) {
              return Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return ListTile(
                    leading: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Theme Mode'),
                    subtitle: const Text('Auto, Light, or Dark'),
                    trailing: DropdownButton<ThemeMode>(
                      value: themeProvider.themeMode,
                      onChanged: (mode) {
                        if (mode != null) {
                          themeProvider.setThemeMode(mode);
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: ThemeMode.system, child: Text('Auto')),
                        DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                      ],
                    ),
                  );
                },
              );
            },
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