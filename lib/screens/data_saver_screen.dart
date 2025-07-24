// lib/screens/data_saver_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/main.dart';

class DataSaverScreen extends StatelessWidget {
  const DataSaverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Data Saver Mode')),
        body: const Center(
          child: Text('You must be logged in to change this setting.'),
        ),
      );
    }

    final userDocRef = FirebaseFirestore.instance
        .collection('artifacts/$APP_ID/public/data/users')
        .doc(user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Saver Mode'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userDocRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final bool isDataSaverOn = userData?['dataSaver'] ?? true;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: SwitchListTile(
                  title: const Text('Enable Data Saver', style: TextStyle(fontWeight: FontWeight.bold)),
                  value: isDataSaverOn,
                  onChanged: (bool value) {
                    userDocRef.update({'dataSaver': value});
                  },
                  secondary: const Icon(Icons.data_saver_on),
                  activeColor: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'When enabled, Data Saver helps reduce your mobile data usage. Videos will not play automatically in your feed, and other data-saving measures may be applied.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}