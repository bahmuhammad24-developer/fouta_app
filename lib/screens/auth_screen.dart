// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/main.dart'; // Import APP_ID

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isRegistering = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
        backgroundColor: msg.contains('successful') ? Colors.green : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _authenticate() async {
    setState(() {
      _message = null;
    });
    try {
      if (_isRegistering) {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (userCredential.user != null) {
          await FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(userCredential.user!.uid).set({
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
          });
        }
        _showMessage('Registration successful!');
      } else {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (userCredential.user != null) {
          final userDocRef = FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(userCredential.user!.uid);
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
        }
        _showMessage('Login successful!');
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'An unknown authentication error occurred.');
    } catch (e) {
      _showMessage('An unexpected error occurred: $e');
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
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
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
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outlined),
                      ),
                      obscureText: true,
                    ),
                    if (_isRegistering) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _phoneNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number (Optional)',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City (Optional)',
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _authenticate,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: Text(
                        _isRegistering ? 'Register' : 'Login',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        style: TextStyle(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}