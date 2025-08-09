// lib/widgets/chat/audio_recorder.dart

import 'package:flutter/material.dart';

const bool kChatAudioEnabled = true;

class AudioRecorder extends StatefulWidget {
  final void Function() onRecorded;

  const AudioRecorder({super.key, required this.onRecorded});

  @override
  State<AudioRecorder> createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  bool _recording = false;

  void _toggle() {
    if (!kChatAudioEnabled) return;
    setState(() {
      _recording = !_recording;
    });
    if (!_recording) {
      widget.onRecorded();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kChatAudioEnabled) {
      return const SizedBox.shrink();
    }
    return IconButton(
      icon: Icon(_recording ? Icons.stop : Icons.mic),
      onPressed: _toggle,
      tooltip: _recording ? 'Stop recording' : 'Record audio',
    );
  }
}
