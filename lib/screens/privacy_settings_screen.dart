// lib/screens/privacy_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fouta_app/main.dart'; // Import APP_ID

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  String? _message;
  bool _isDiscoverable = true;
  String _postVisibility = 'everyone';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    setState(() {
      _message = msg;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: msg.contains('successful') ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _loadPrivacySettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('You must be logged in to view privacy settings.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _isDiscoverable = userData['isDiscoverable'] ?? true;
          _postVisibility = userData['postVisibility'] ?? 'everyone';
        });
      }
    } on FirebaseException catch (e) {
      _showMessage('Failed to load privacy settings: ${e.message}');
    } catch (e) {
      _showMessage('An unexpected error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePrivacySettings() async {
    setState(() {
      _message = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('You must be logged in to save privacy settings.');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(user.uid).update({
        'isDiscoverable': _isDiscoverable,
        'postVisibility': _postVisibility,
      });
      _showMessage('Privacy settings saved successfully!');
    } on FirebaseException catch (e) {
      _showMessage('Failed to save privacy settings: ${e.message}');
    } catch (e) {
      _showMessage('An unexpected error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Privacy Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_message != null)
              Container(
                padding: const EdgeInsets.all(8.0),
                color: _message!.contains('successful') ? Colors.green[100] : Colors.red[100],
                child: Center(
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _message!.contains('successful') ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
              ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visibility',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Appear in People tab'),
                      subtitle: const Text('Allow other users to find you in the "People" tab.'),
                      trailing: Switch(
                        value: _isDiscoverable,
                        onChanged: (bool value) {
                          setState(() {
                            _isDiscoverable = value;
                          });
                        },
                        activeColor: Theme.of(context).appBarTheme.backgroundColor,
                      ),
                    ),
                    const Divider(),
                    const Text(
                      'Who can see your posts?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    RadioListTile<String>(
                      title: const Text('Everyone'),
                      value: 'everyone',
                      groupValue: _postVisibility,
                      onChanged: (String? value) {
                        setState(() {
                          _postVisibility = value!;
                        });
                      },
                      subtitle: const Text('Your posts will be visible to all users.'),
                    ),
                    RadioListTile<String>(
                      title: const Text('Only Followers'),
                      value: 'followers',
                      groupValue: _postVisibility,
                      onChanged: (String? value) {
                        setState(() {
                          _postVisibility = value!;
                        });
                      },
                      subtitle: const Text('Only users who follow you can see your posts.'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _savePrivacySettings,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save Privacy Settings'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
