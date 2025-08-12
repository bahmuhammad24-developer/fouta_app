import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Displays a basic camera preview with simple AR-style overlays.
class ArCameraScreen extends StatefulWidget {
  const ArCameraScreen({super.key});

  @override
  State<ArCameraScreen> createState() => _ArCameraScreenState();
}

class _ArCameraScreenState extends State<ArCameraScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _init();
  }

  Future<void> _init() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras.first, ResolutionPreset.medium);
    await _controller!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AR Camera')),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!(_controller?.value.isInitialized ?? false)) {
            return const Center(child: Text('Camera unavailable'));
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_controller!),
              // Simple AR effect using a color filter.
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                    Colors.purple.withOpacity(0.2), BlendMode.overlay),
                child: Container(),
              ),
              // Example sticker overlay
              const Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('🌟', style: TextStyle(fontSize: 48)),
                ),
              ),
              // TODO: consider integrating an external AR plugin if we need
              // advanced face/body tracking. Requires security review.
            ],
          );
        },
      ),
    );
  }
}
