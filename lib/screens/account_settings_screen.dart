// lib/screens/account_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fouta_app/main.dart'; // Import APP_ID

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _cityController = TextEditingController();
  String? _message;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccountData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _cityController.dispose();
    super.dispose();
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

  Future<void> _loadAccountData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('You must be logged in to view account settings.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _firstNameController.text = userData['firstName'] ?? '';
        _lastNameController.text = userData['lastName'] ?? '';
        _phoneNumberController.text = userData['phoneNumber'] ?? '';
        _cityController.text = userData['city'] ?? '';
      }
    } on FirebaseException catch (e) {
      _showMessage('Failed to load account data: ${e.message}');
    } catch (e) {
      _showMessage('An unexpected error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAccountData() async {
    setState(() {
      _message = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('You must be logged in to save account settings.');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(user.uid).update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'displayName': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'phoneNumber': _phoneNumberController.text.trim(),
        'city': _cityController.text.trim(),
      });

      final userPostsQuery = FirebaseFirestore.instance
          .collection('artifacts/$APP_ID/public/data/posts')
          .where('authorId', isEqualTo: user.uid);

      final userPostsSnapshot = await userPostsQuery.get();
      for (final postDoc in userPostsSnapshot.docs) {
        await postDoc.reference.update({
          'authorDisplayName': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        });
      }

      _showMessage('Account settings saved successfully!');
    } on FirebaseException catch (e) {
      _showMessage('Failed to save account settings: ${e.message}');
    } catch (e) {
      _showMessage('An unexpected error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
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
                      'Personal Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        hintText: 'Your first name',
                        helperText: 'This will be part of your display name.',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        hintText: 'Your last name',
                        helperText: 'This will be part of your display name.',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Optional: Your contact number',
                        helperText: 'Only visible to you unless shared.',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        hintText: 'Optional: Your current city',
                        helperText: 'Helps others find you.',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveAccountData,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save Account Settings'),
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
