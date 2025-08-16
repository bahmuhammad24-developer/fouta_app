import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../marketplace_service.dart';

/// Guided onboarding flow for first-time sellers.
class SellerOnboardingFlow extends StatefulWidget {
  const SellerOnboardingFlow({super.key});

  @override
  State<SellerOnboardingFlow> createState() => _SellerOnboardingFlowState();
}

class _SellerOnboardingFlowState extends State<SellerOnboardingFlow> {
  final PageController _controller = PageController();
  final _profileForm = GlobalKey<FormState>();
  final _productForm = GlobalKey<FormState>();
  final MarketplaceService _service = MarketplaceService();

  // profile
  String? _displayName;
  String? _location;
  String? _contact;

  // product
  String? _draftId;
  String _title = '';
  String _price = '';
  final List<Uri> _images = [];

  int _index = 0;

  Future<void> _next() async {
    if (_index == 0) {
      if (!(_profileForm.currentState?.validate() ?? false)) return;
      _profileForm.currentState?.save();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('meta')
            .doc('onboarding')
            .set({
          'displayName': _displayName,
          'location': _location,
          'contact': _contact,
          'completed': false,
        }, SetOptions(merge: true));
      }
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else if (_index == 1) {
      if (!(_productForm.currentState?.validate() ?? false)) return;
      _productForm.currentState?.save();
      final priceAmount = double.tryParse(_price) ?? 0;
      _draftId = await _service.createDraftProduct(
        title: _title,
        price: priceAmount,
        currency: 'USD',
        images: _images,
      );
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else if (_index == 2) {
      if (_draftId == null) return;
      try {
        await _service.publishProduct(_draftId!);
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('meta')
              .doc('onboarding')
              .set({'completed': true}, SetOptions(merge: true));
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Fill in required fields')));
      }
    }
  }

  Widget _buildProfile() {
    return Form(
      key: _profileForm,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Display name'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              onSaved: (v) => _displayName = v,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Location'),
              onSaved: (v) => _location = v,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Contact'),
              onSaved: (v) => _contact = v,
            ),
            const Spacer(),
            ElevatedButton(onPressed: _next, child: const Text('Next')),
          ],
        ),
      ),
    );
  }

  Widget _buildProduct() {
    return Form(
      key: _productForm,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              onSaved: (v) => _title = v ?? '',
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              onSaved: (v) => _price = v ?? '',
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Image URL'),
              onSaved: (v) {
                if (v != null && v.isNotEmpty) {
                  final uri = Uri.tryParse(v);
                  if (uri != null) _images.add(uri);
                }
              },
            ),
            const Spacer(),
            ElevatedButton(onPressed: _next, child: const Text('Next')),
          ],
        ),
      ),
    );
  }

  Widget _buildReview() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Title: $_title'),
          Text('Price: $_price'),
          const Spacer(),
          ElevatedButton(onPressed: _next, child: const Text('Publish')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start Selling')),
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _index = i),
        children: [
          _buildProfile(),
          _buildProduct(),
          _buildReview(),
        ],
      ),
    );
  }
}

