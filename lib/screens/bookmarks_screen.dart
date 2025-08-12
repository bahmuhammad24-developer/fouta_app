// lib/screens/bookmarks_screen.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:fouta_app/main.dart';
import 'package:fouta_app/utils/firestore_paths.dart';
import 'package:fouta_app/utils/snackbar.dart';
import 'package:fouta_app/widgets/post_card_widget.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  bool _isDataSaverOn = true;
  bool _isOnMobileData = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadDataSaverPreference();
    Connectivity().checkConnectivity().then((result) {
      if (!mounted) return;
      setState(() {
        _isOnMobileData = result is List<ConnectivityResult>
            ? result.contains(ConnectivityResult.mobile)
            : result == ConnectivityResult.mobile;
      });
    });
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      setState(() {
        _isOnMobileData = results.contains(ConnectivityResult.mobile);
      });
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDataSaverPreference() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final doc = await FirebaseFirestore.instance
          .collection(FirestorePaths.users())
          .doc(currentUser.uid)
          .get();
      if (mounted) {
        setState(() {
          _isDataSaverOn = doc.data()?['dataSaver'] ?? true;
        });
      }
    }
  }

  void _showMessage(String msg) {
    AppSnackBar.show(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bookmarks')),
        body: const Center(child: Text('Please log in to view bookmarks.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('artifacts/$APP_ID/public/data/posts')
            .where('bookmarks', arrayContains: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No bookmarks yet.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return PostCardWidget(
                post: data,
                postId: docs[index].id,
                currentUser: currentUser,
                appId: APP_ID,
                onMessage: _showMessage,
                isDataSaverOn: _isDataSaverOn,
                isOnMobileData: _isOnMobileData,
              );
            },
          );
        },
      ),
    );
  }
}
