import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class StoryCameraScreen extends StatefulWidget {
  const StoryCameraScreen({super.key});

  @override
  State<StoryCameraScreen> createState() => _StoryCameraScreenState();
}

class _StoryCameraScreenState extends State<StoryCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  bool _initializing = true;
  int _index = 0;

  bool _isRecording = false;
  Timer? _timer;
  DateTime? _recordStart;
  double _progress = 0.0;
  static const Duration _maxDuration = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _initializing = false);
        return;
      }
      _controller = CameraController(
        _cameras[_index],
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await _controller!.initialize();
    } catch (_) {
      // handled in UI
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || _controller == null) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _init();
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isRecording) return;
    try {
      final file = await _controller!.takePicture();
      if (!mounted) return;
      Navigator.pop(context, {'type': 'image', 'path': file.path});
    } catch (_) {}
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized || _isRecording) return;
    try {
      await _controller!.startVideoRecording();
      _isRecording = true;
      _recordStart = DateTime.now();
      _progress = 0.0;
      _timer = Timer.periodic(const Duration(milliseconds: 50), (t) async {
        final elapsed = DateTime.now().difference(_recordStart!);
        setState(() {
          _progress = (elapsed.inMilliseconds /
                  _maxDuration.inMilliseconds)
              .clamp(0.0, 1.0);
        });
        if (elapsed >= _maxDuration) {
          await _stopRecording();
        }
      });
      setState(() {});
    } catch (_) {}
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_controller!.value.isInitialized || !_isRecording) return;
    try {
      final file = await _controller!.stopVideoRecording();
      _timer?.cancel();
      _isRecording = false;
      if (!mounted) return;
      Navigator.pop(context, {'type': 'video', 'path': file.path});
    } catch (_) {
      _timer?.cancel();
      _isRecording = false;
      setState(() {});
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isRecording) return;
    setState(() => _initializing = true);
    _index = (_index + 1) % _cameras.length;
    await _controller?.dispose();
    _controller = CameraController(
      _cameras[_index],
      ResolutionPreset.medium,
      enableAudio: true,
    );
    await _controller!.initialize();
    if (mounted) setState(() => _initializing = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_initializing) {
      return Scaffold(
        backgroundColor: cs.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Camera')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Camera not available'),
              const SizedBox(height: 8),
              FilledButton(onPressed: _init, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          Positioned(
            top: 48,
            right: 24,
            child: IconButton(
              icon: const Icon(Icons.cameraswitch,
                  color: Colors.white, size: 28),
              onPressed: _switchCamera,
            ),
          ),
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: _takePhoto,
              onLongPress: _startRecording,
              onLongPressUp: _stopRecording,
              child: SizedBox(
                width: double.infinity,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 4),
                        ),
                      ),
                      if (_isRecording)
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 4,
                            backgroundColor: Colors.white24,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    Colors.redAccent),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

