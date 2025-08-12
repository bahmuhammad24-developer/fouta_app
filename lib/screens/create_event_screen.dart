// lib/screens/create_event_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/main.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouta_app/services/media_service.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fouta_app/screens/event_invite_screen.dart';
import 'package:fouta_app/utils/snackbar.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  File? _headerImageFile;

  // List of user IDs invited to this event (followers selected from invite screen).
  List<String> _invitedIds = [];

  final MediaService _mediaService = MediaService();

  Future<void> _pickImage() async {
    final attachment = await _mediaService.pickImage();
    if (attachment != null) {
      setState(() {
        _headerImageFile = File(attachment.file.path);
      });
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      _selectedDate = date;
      _selectedTime = time;
    });
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      AppSnackBar.show(context, 'Please select a date and time.', isError: true);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackBar.show(context, 'You must be logged in to create an event.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    
    String? imageUrl;
    if(_headerImageFile != null) {
      final ref = FirebaseStorage.instance.ref().child('event_headers').child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(_headerImageFile!);
      imageUrl = await ref.getDownloadURL();
    }

    final eventDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    await FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/events').add({
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'location': _locationController.text.trim(),
      'headerImageUrl': imageUrl ?? '',
      'eventDate': Timestamp.fromDate(eventDateTime),
      'attendees': [user.uid], // Creator automatically attends
      'creatorId': user.uid,
      'invitedIds': _invitedIds,
    });

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveEvent,
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
                        child: _headerImageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_headerImageFile!, fit: BoxFit.cover),
                              )
                            : Center(
                                child: Builder(
                                  builder: (context) => Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt, size: 40, color: Theme.of(context).colorScheme.outline),
                                      const Text('Add Header Image'),
                                    ],
                                  ),
                                ),
                              ),
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
                    const SizedBox(height: 16),
                    // Invite people button and selected count
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.person_add),
                          label: const Text('Invite'),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventInviteScreen(initialSelected: _invitedIds),
                              ),
                            );
                            if (result != null && result is List<String>) {
                              setState(() {
                                _invitedIds = result;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        if (_invitedIds.isNotEmpty) Text('Invited: ${_invitedIds.length}')
                      ],
                    ),
                    // Display invited users as chips
                    if (_invitedIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('artifacts/$APP_ID/public/data/users')
                              .where(FieldPath.documentId, whereIn: _invitedIds)
                              .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox.shrink();
                            }
                            final docs = snapshot.data!.docs;
                            return Wrap(
                              spacing: 4,
                              children: docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final name = data['displayName'] ?? 'User';
                                return Chip(label: Text(name));
                              }).toList(),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}