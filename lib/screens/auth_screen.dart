// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/utils/firestore_paths.dart';
import 'package:fouta_app/services/push_notification_service.dart';
import 'package:fouta_app/utils/snackbar.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _cityController = TextEditingController();

  final _passwordFocusNode = FocusNode();
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _phoneNumberFocusNode = FocusNode();
  final _cityFocusNode = FocusNode();

  bool _isRegistering = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _cityController.dispose();
    _passwordFocusNode.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _phoneNumberFocusNode.dispose();
    _cityFocusNode.dispose();
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

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _message = null;
      _isLoading = true;
    });
    try {
      if (_isRegistering) {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (userCredential.user != null) {
          await FirebaseFirestore.instance
              .collection(FirestorePaths.users())
              .doc(userCredential.user!.uid)
              .set({
            'email': _emailController.text.trim(),
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'displayName': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
            'phoneNumber': _phoneNumberController.text.trim(),
            'city': _cityController.text.trim(),
            'bio': '',
            'profileImageUrl': '',
            'followers': [],
            'following': [],
            'blockedUsers': [], // New field
            'createdAt': FieldValue.serverTimestamp(),
            'isDiscoverable': true,
            'postVisibility': 'everyone',
            'unreadMessageCount': 0,
            'dataSaver': true,
            'showOnlineStatus': true,
            'fcmTokens': [],
          });
          await PushNotificationService.updateDeviceToken();
        }
        _showMessage('Registration successful!');
      } else {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (userCredential.user != null) {
          final userDocRef = FirebaseFirestore.instance
              .collection(FirestorePaths.users())
              .doc(userCredential.user!.uid);
          final userDoc = await userDocRef.get();

          Map<String, dynamic> updateData = {};
          if (!userDoc.exists) {
            updateData = {
              'email': userCredential.user!.email,
              'firstName': userCredential.user!.email?.split('@')[0] ?? 'User',
              'lastName': '',
              'displayName': userCredential.user!.email?.split('@')[0] ?? 'User',
              'phoneNumber': '',
              'city': '',
              'bio': '',
              'profileImageUrl': '',
              'followers': [],
              'following': [],
              'blockedUsers': [], // New field
              'createdAt': FieldValue.serverTimestamp(),
              'isDiscoverable': true,
              'postVisibility': 'everyone',
              'unreadMessageCount': 0,
              'dataSaver': true,
              'showOnlineStatus': true,
            };
            await userDocRef.set(updateData);
          } else {
            final existingData = userDoc.data()!;
            bool needsUpdate = false;

            if (!existingData.containsKey('dataSaver')) {
              updateData['dataSaver'] = true;
              needsUpdate = true;
            }
            if (!existingData.containsKey('showOnlineStatus')) {
              updateData['showOnlineStatus'] = true;
              needsUpdate = true;
            }
            if (needsUpdate) {
              await userDocRef.update(updateData);
            }
          }
          await PushNotificationService.updateDeviceToken();
        }
        _showMessage('Login successful!');
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'An unknown authentication error occurred.');
    } catch (e) {
      _showMessage('An unexpected error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/fouta_logo_transparent.png',
                height: 120,
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        _isRegistering ? 'Join Fouta' : 'Welcome to Fouta',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_passwordFocusNode),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an email';
                          }
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        obscureText: !_isPasswordVisible,
                        textInputAction:
                            _isRegistering ? TextInputAction.next : TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (_isRegistering) {
                            FocusScope.of(context)
                                .requestFocus(_firstNameFocusNode);
                          } else if (!_isLoading) {
                            _authenticate();
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters long';
                          }
                          return null;
                        },
                      ),
                      if (_isRegistering) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _firstNameController,
                          focusNode: _firstNameFocusNode,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => FocusScope.of(context)
                              .requestFocus(_lastNameFocusNode),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lastNameController,
                          focusNode: _lastNameFocusNode,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => FocusScope.of(context)
                              .requestFocus(_phoneNumberFocusNode),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneNumberController,
                          focusNode: _phoneNumberFocusNode,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number (Optional)',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => FocusScope.of(context)
                              .requestFocus(_cityFocusNode),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cityController,
                          focusNode: _cityFocusNode,
                          decoration: const InputDecoration(
                            labelText: 'City (Optional)',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (!_isLoading) {
                              _authenticate();
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _authenticate,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                _isRegistering ? 'Register' : 'Login',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isRegistering = !_isRegistering;
                            _message = null;
                          });
                        },
                        child: Text(
                          _isRegistering
                              ? 'Already have an account? Login'
                              : 'Don\'t have an account? Register',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}