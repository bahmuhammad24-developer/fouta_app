// lib/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fouta_app/main.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = true;
  File? _pickedImage;
  String _currentProfileImageUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(user.uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      _firstNameController.text = userData['firstName'] ?? '';
      _lastNameController.text = userData['lastName'] ?? '';
      _bioController.text = userData['bio'] ?? '';
      _currentProfileImageUrl = userData['profileImageUrl'] ?? '';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final pickedImageFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedImageFile != null) {
      setState(() {
        _pickedImage = File(pickedImageFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser!;
    String newImageUrl = _currentProfileImageUrl;

    if (_pickedImage != null) {
      final ref = FirebaseStorage.instance.ref().child('artifacts/$APP_ID/public/data/profile_images').child('${user.uid}.jpg');
      await ref.putFile(_pickedImage!);
      newImageUrl = await ref.getDownloadURL();
    }

    await FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(user.uid).update({
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'bio': _bioController.text.trim(),
      'profileImageUrl': newImageUrl,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _pickedImage != null
                              ? FileImage(_pickedImage!)
                              : (_currentProfileImageUrl.isNotEmpty ? NetworkImage(_currentProfileImageUrl) : null) as ImageProvider?,
                          child: _pickedImage == null && _currentProfileImageUrl.isEmpty ? const Icon(Icons.person, size: 60) : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: IconButton(
                            icon: const CircleAvatar(child: Icon(Icons.camera_alt)),
                            onPressed: _pickImage,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                      validator: (value) => value!.isEmpty ? 'Please enter a first name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (value) => value!.isEmpty ? 'Please enter a last name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'Bio'),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
