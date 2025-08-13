import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';

class ProfileHeader extends StatelessWidget {
  final String userId;
  final String displayName;
  final String bio;
  final String joinedDate;
  final bool isMyProfile;
  final bool isEditing;
  final TextEditingController bioController;
  final String profileImageUrl;
  final XFile? newProfileImage;
  final bool isUploading;
  final double uploadProgress;
  final List<dynamic> followers;
  final List<dynamic> following;
  final VoidCallback onAvatarTap;
  final VoidCallback onEditPressed;
  final VoidCallback onFollowersTap;
  final VoidCallback onFollowingTap;
  final Widget? creatorStats;

  const ProfileHeader({
    super.key,
    required this.userId,
    required this.displayName,
    required this.bio,
    required this.joinedDate,
    required this.isMyProfile,
    required this.isEditing,
    required this.bioController,
    required this.profileImageUrl,
    this.newProfileImage,
    required this.isUploading,
    required this.uploadProgress,
    required this.followers,
    required this.following,
    required this.onAvatarTap,
    required this.onEditPressed,
    required this.onFollowersTap,
    required this.onFollowingTap,
    this.creatorStats,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarChild;
    if (newProfileImage != null) {
      if (kIsWeb) {
        avatarChild = Image.network(
          newProfileImage!.path,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      } else {
        avatarChild = Image.file(
          File(newProfileImage!.path),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      }
    } else if (profileImageUrl.isNotEmpty) {
      avatarChild = Image.network(
        profileImageUrl,
        key: Key('profile-avatar-$userId'),
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } else {
      avatarChild = Icon(
        Icons.person,
        size: 60,
        color: Theme.of(context).colorScheme.onPrimary,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceVariant,
                  child: ClipOval(child: avatarChild),
                ),
                if (isMyProfile)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      child: IconButton(
                        icon: Icon(
                          isEditing ? Icons.check : Icons.edit,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        onPressed: onEditPressed,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isUploading)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: LinearProgressIndicator(value: uploadProgress),
            ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (isEditing)
            TextField(
              controller: bioController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Bio'),
              textAlign: TextAlign.center,
            )
          else
            Text(
              bio,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Joined: $joinedDate',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onFollowersTap,
                child: Column(
                  children: [
                    Text(
                      '${followers.length}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Followers',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 30),
              GestureDetector(
                onTap: onFollowingTap,
                child: Column(
                  children: [
                    Text(
                      '${following.length}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Following',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (creatorStats != null) creatorStats!,
        ],
      ),
    );
  }
}
