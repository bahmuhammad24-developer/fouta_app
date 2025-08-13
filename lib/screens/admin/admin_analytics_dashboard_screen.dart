import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

class AdminAnalyticsDashboardScreen extends StatelessWidget {
  const AdminAnalyticsDashboardScreen({super.key});

  bool _isAdmin(User? user) {
    const admins = {'test-admin-uid'}; // Replace with custom claims check.
    return user != null && admins.contains(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (!_isAdmin(user)) {
      return const Scaffold(body: Center(child: Text('Not authorized')));
    }
    final date = DateTime.now().toUtc();
    final key = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final doc = FirebaseFirestore.instance
        .collection('artifacts')
        .doc(APP_ID)
        .collection('public')
        .doc('data')
        .collection('metrics')
        .collection('daily')
        .doc(key);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Analytics')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: doc.get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() ?? {};
          final dau = data['dau'] ?? 0;
          final posts = data['posts'] ?? 0;
          final shorts = data['shortViews'] ?? 0;
          final intents = data['purchaseIntents'] ?? 0;
          final missing = snapshot.data!.exists ? '' : 'No metrics for today';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _metricCard('DAU', dau),
              _metricCard('Posts created', posts),
              _metricCard('Shorts views', shorts),
              _metricCard('Marketplace intents', intents),
              if (missing.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(missing),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _metricCard(String title, int value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title),
        trailing: Text(value.toString()),
      ),
    );
  }
}
