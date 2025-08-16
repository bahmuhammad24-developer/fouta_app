import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/fouta_button.dart';
import 'seller_service.dart';

class SellerOnboardingScreen extends StatefulWidget {
  const SellerOnboardingScreen({super.key});

  @override
  State<SellerOnboardingScreen> createState() => _SellerOnboardingScreenState();
}

class _SellerOnboardingScreenState extends State<SellerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _submitting = false;
  final SellerService _service = SellerService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    setState(() => _submitting = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _service.createSellerProfile(
      userId: uid,
      displayName: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seller Setup')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Display name'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Display name required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioCtrl,
                decoration:
                    const InputDecoration(labelText: 'Bio (optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              FoutaButton(
                label: _submitting ? 'Submitting...' : 'Submit',
                onPressed: _submitting ? null : _submit,
                expanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
