// lib/screens/edit_event_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/main.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fouta_app/utils/snackbar.dart';

class EditEventScreen extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> initialData;

  const EditEventScreen({
    super.key,
    required this.eventId,
    required this.initialData,
  });

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  File? _headerImageFile;
  String? _currentHeaderImageUrl;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialData['title'] ?? '';
    _descriptionController.text = widget.initialData['description'] ?? '';
    _locationController.text = widget.initialData['location'] ?? '';
    _currentHeaderImageUrl = widget.initialData['headerImageUrl'];
    
    final Timestamp timestamp = widget.initialData['eventDate'];
    final initialDateTime = timestamp.toDate();
    _selectedDate = initialDateTime;
    _selectedTime = TimeOfDay.fromDateTime(initialDateTime);
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if(pickedImage != null) {
      setState(() {
        _headerImageFile = File(pickedImage.path);
      });
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      _selectedDate = date;
      _selectedTime = time;
    });
  }

  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      AppSnackBar.show(context, 'Please select a date and time.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final eventDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // FIX: Refactored logic to be more robust
    final Map<String, dynamic> dataToUpdate = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'location': _locationController.text.trim(),
      'eventDate': Timestamp.fromDate(eventDateTime),
    };

    try {
      if (_headerImageFile != null) {
        final ref = FirebaseStorage.instance.ref().child('event_headers').child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_headerImageFile!);
        final imageUrl = await ref.getDownloadURL();
        dataToUpdate['headerImageUrl'] = imageUrl;
      }

      await FirebaseFirestore.instance
          .collection('artifacts/$APP_ID/public/data/events')
          .doc(widget.eventId)
          .update(dataToUpdate);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Failed to update event: $e', isError: true);
      }
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _updateEvent,
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
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _buildImage(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Event Title'),
                      validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        _selectedDate == null
                            ? 'Select Date & Time'
                            : DateFormat.yMd().add_jm().format(DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute)),
                      ),
                      onTap: _pickDateTime,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImage() {
    if (_headerImageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(_headerImageFile!, fit: BoxFit.cover),
      );
    }
    if (_currentHeaderImageUrl != null && _currentHeaderImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: _currentHeaderImageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Icon(Icons.broken_image, size: 40, color: Theme.of(context).colorScheme.outline),
          ),
        ),
      );
    }
      return Builder(
        builder: (context) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 40, color: Theme.of(context).colorScheme.outline),
              const Text('Change Header Image')
            ],
          ),
        ),
      );
  }
}