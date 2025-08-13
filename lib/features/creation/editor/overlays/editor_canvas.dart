import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'overlay_models.dart';

/// Canvas for layering overlays on top of an image or video.
class EditorCanvas extends StatefulWidget {
  final String mediaPath;
  final String mediaType; // 'image' or 'video'
  final Uint8List? bytes;
  final List<OverlayModel>? initialOverlays;

  const EditorCanvas({
    super.key,
    required this.mediaPath,
    required this.mediaType,
    this.bytes,
    this.initialOverlays,
  });

  @override
  EditorCanvasState createState() => EditorCanvasState();
}

class EditorCanvasState extends State<EditorCanvas> {
  final List<OverlayModel> _overlays = [];
  OverlayModel? _selected;
  VideoPlayerController? _video;

  List<Map<String, dynamic>> getSerializedOverlays() =>
      _overlays.map((o) => o.toMap()).toList();

  @override
  void initState() {
    super.initState();
    _overlays.addAll(widget.initialOverlays ?? []);
    if (widget.mediaType == 'video') {
      _video = widget.mediaPath.startsWith('http')
          ? VideoPlayerController.network(widget.mediaPath)
          : VideoPlayerController.file(File(widget.mediaPath))
        ..initialize().then((_) {
          setState(() {});
          _video?.play();
        });
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  void _addText() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add text'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Add')),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;
    setState(() {
      _overlays.add(TextOverlay(
        id: UniqueKey().toString(),
        text: text,
        color: Colors.white.value,
        fontSize: 24,
        dx: 50,
        dy: 50,
        scale: 1,
        rotation: 0,
        opacity: 1,
        z: _overlays.length,
      ));
    });
  }

  void _addSticker(String emoji) {
    setState(() {
      _overlays.add(StickerOverlay(
        id: UniqueKey().toString(),
        emoji: emoji,
        dx: 50,
        dy: 50,
        scale: 1,
        rotation: 0,
        opacity: 1,
        z: _overlays.length,
      ));
    });
  }

  void _addShape(String shape) {
    setState(() {
      _overlays.add(ShapeOverlay(
        id: UniqueKey().toString(),
        shape: shape,
        color: Colors.white.value,
        dx: 50,
        dy: 50,
        scale: 1,
        rotation: 0,
        opacity: 1,
        z: _overlays.length,
      ));
    });
  }

  void _deleteSelected() {
    if (_selected == null) return;
    setState(() {
      _overlays.remove(_selected);
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = _buildBase();
    return Stack(
      children: [
        Positioned.fill(
            child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                    width: media.width,
                    height: media.height,
                    child: media.child))),
        ..._overlays.map(_buildOverlay),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: _buildToolbar(),
        ),
      ],
    );
  }

  _MediaWidget _buildBase() {
    if (widget.mediaType == 'video') {
      if (_video != null && _video!.value.isInitialized) {
        return _MediaWidget(
          width: _video!.value.size.width,
          height: _video!.value.size.height,
          child: AspectRatio(
            aspectRatio: _video!.value.aspectRatio,
            child: VideoPlayer(_video!),
          ),
        );
      }
      return const _MediaWidget(width: 0, height: 0, child: SizedBox());
    }
    if (widget.bytes != null) {
      final image = Image.memory(widget.bytes!);
      return _MediaWidget(width: image.width ?? 0, height: image.height ?? 0, child: image);
    }
    if (widget.mediaPath.startsWith('http')) {
      final image = Image.network(widget.mediaPath);
      return _MediaWidget(width: image.width ?? 0, height: image.height ?? 0, child: image);
    }
    final fileImage = Image.file(File(widget.mediaPath));
    return _MediaWidget(
        width: fileImage.width ?? 0, height: fileImage.height ?? 0, child: fileImage);
  }

  Widget _buildOverlay(OverlayModel overlay) {
    return Positioned(
      left: overlay.dx,
      top: overlay.dy,
      child: GestureDetector(
        onTap: () => setState(() => _selected = overlay),
        onPanUpdate: (d) {
          setState(() {
            overlay.dx += d.delta.dx;
            overlay.dy += d.delta.dy;
          });
        },
        onScaleUpdate: (d) {
          setState(() {
            overlay.scale *= d.scale;
            overlay.rotation += d.rotation;
          });
        },
        child: Transform.rotate(
          angle: overlay.rotation,
          child: Opacity(
            opacity: overlay.opacity,
            child: Transform.scale(
              scale: overlay.scale,
              child: _overlayWidget(overlay),
            ),
          ),
        ),
      ),
    );
  }

  Widget _overlayWidget(OverlayModel overlay) {
    if (overlay is TextOverlay) {
      return Text(
        overlay.text,
        style: TextStyle(color: Color(overlay.color), fontSize: overlay.fontSize),
      );
    } else if (overlay is StickerOverlay) {
      return Text(overlay.emoji, style: const TextStyle(fontSize: 48));
    } else if (overlay is ShapeOverlay) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Color(overlay.color).withOpacity(overlay.opacity),
          shape: overlay.shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildToolbar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(onPressed: _addText, icon: const Icon(Icons.text_fields)),
        IconButton(
            onPressed: () => _addSticker('😄'),
            icon: const Icon(Icons.emoji_emotions)),
        IconButton(
            onPressed: () => _addShape('rect'),
            icon: const Icon(Icons.crop_square)),
        IconButton(
            onPressed: () => _addShape('circle'),
            icon: const Icon(Icons.circle)),
        IconButton(onPressed: _deleteSelected, icon: const Icon(Icons.delete)),
      ],
    );
  }
}

class _MediaWidget {
  final double width;
  final double height;
  final Widget child;
  const _MediaWidget({required this.width, required this.height, required this.child});
}

