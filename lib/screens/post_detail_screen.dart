// lib/screens/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fouta_app/utils/firestore_paths.dart';

import 'package:fouta_app/main.dart'; // Import APP_ID
import 'package:fouta_app/widgets/post_card_widget.dart';
import 'package:fouta_app/utils/snackbar.dart';
import 'package:fouta_app/widgets/safe_stream_builder.dart';
import 'package:fouta_app/widgets/progressive_image.dart';
import 'package:fouta_app/widgets/video_player_widget.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final FirebaseFirestore firestore;
  const PostDetailScreen({super.key, required this.postId, FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  String? _message;
  bool _isDataSaverOn = true;
  bool _isOnMobileData = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadDataSaverPreference();
    Connectivity().checkConnectivity().then((result) {
      if (mounted) {
        setState(() {
          _isOnMobileData = result is List<ConnectivityResult>
              ? result.contains(ConnectivityResult.mobile)
              : result == ConnectivityResult.mobile;
        });
      }
    });
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() {
          _isOnMobileData = results.contains(ConnectivityResult.mobile);
        });
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _connectivitySubscription?.cancel();
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
        backgroundColor: msg.contains('successful') ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
      ),
    );

    final lower = msg.toLowerCase();
    final isError = lower.contains('fail') || lower.contains('error');
    AppSnackBar.show(context, msg, isError: isError);

  }

  Future<void> _loadDataSaverPreference() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final doc = await widget.firestore
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

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),
      body: SafeStreamBuilder<DocumentSnapshot>(
        stream: widget.firestore
            .collection('artifacts/$APP_ID/public/data/posts')
            .doc(widget.postId)
            .snapshots(),
        empty: const Center(child: CircularProgressIndicator()),
        builder: (context, snapshot) {
          if (!snapshot.data!.exists) {
            return const Center(child: Text('Post not found.'));
          }

          final post = snapshot.data!.data() as Map<String, dynamic>;
          final postId = snapshot.data!.id;
          final mediaUrl = post['mediaUrl'] as String? ?? '';
          final mediaType = post['mediaType'] as String? ?? 'text';
          final double? aspectRatio =
              (post['aspectRatio'] as num?)?.toDouble();
          final postForCard = Map<String, dynamic>.from(post)
            ..remove('media')
            ..remove('mediaUrl');

          final mediaWidget = mediaUrl.isEmpty
              ? const SizedBox.shrink()
              : Hero(
                  tag: '${postId}-media',
                  child: mediaType == 'video'
                      ? VideoPlayerWidget(
                          videoUrl: mediaUrl,
                          videoId: postId,
                          aspectRatio: aspectRatio,
                          areControlsVisible: true,
                          shouldInitialize: true,
                        )
                      : ProgressiveImage(
                          imageUrl: mediaUrl,
                          thumbUrl: post['thumbUrl'] ?? mediaUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                );

          return Column(
            children: [
              if (_message != null)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: _message!.contains('successful')
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.errorContainer,
                  child: Center(
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _message!.contains('successful')
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              if (mediaUrl.isNotEmpty) mediaWidget,
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: PostCardWidget(
                    key: ValueKey(postId),
                    post: postForCard,
                    postId: postId,
                    currentUser: currentUser,
                    appId: APP_ID,
                    onMessage: _showMessage,
                    isDataSaverOn: _isDataSaverOn,
                    isOnMobileData: _isOnMobileData,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}