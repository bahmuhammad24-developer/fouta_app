import 'dart:typed_data';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/services/media_service.dart';
import 'package:image_picker/image_picker.dart';

class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker({this.image, this.video});
  final XFile? image;
  final XFile? video;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => image;

  @override
  Future<XFile?> pickVideo({
    required ImageSource source,
    Duration? maxDuration,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async => video;
}

void main() {
  test('pickImage returns attachment when permission granted', () async {
    final picker = _FakeImagePicker(
      image: XFile.fromData(Uint8List(0), name: 'a.jpg', mimeType: 'image/jpeg'),
    );
    final service = MediaService(
      picker: picker,
      requestPermission: () async => true,
    );
    final attachment = await service.pickImage();
    expect(attachment, isNotNull);
    expect(attachment!.type, 'image');
  });

  test('upload image returns uploaded media', () async {
    final service = MediaService(
      uploadBytes: (data, path, contentType) async => 'bytes:$contentType',
      uploadFile: (file, path, contentType) async => 'file:$contentType',
      generateThumb: (path) async => Uint8List(0),
    );
    final attachment = MediaAttachment(
      file: XFile.fromData(Uint8List(0), name: 'a.jpg', mimeType: 'image/jpeg'),
      type: 'image',
      bytes: Uint8List(0),
    );
    final uploaded = await service.upload(attachment, pathPrefix: 'test');
    expect(uploaded.url, 'bytes:image/jpeg');
    expect(uploaded.type, 'image');
  });

  test('upload video uses file uploader and generates thumbnail', () async {
    bool fileCalled = false;
    bool bytesCalled = false;
    final service = MediaService(
      uploadBytes: (data, path, contentType) async {
        bytesCalled = true;
        return 'bytes:$contentType';
      },
      uploadFile: (file, path, contentType) async {
        fileCalled = true;
        return 'file:$contentType';
      },
      generateThumb: (path) async => Uint8List(0),
    );
    final attachment = MediaAttachment(
      file: XFile('/tmp/video.mp4'),
      type: 'video',
      aspectRatio: 1.0,
      durationMs: 1000,
    );
    final uploaded = await service.upload(attachment, pathPrefix: 'test');
    expect(uploaded.url, 'file:video/mp4');
    expect(uploaded.thumbUrl, 'bytes:image/jpeg');
    expect(fileCalled, isTrue);
    expect(bytesCalled, isTrue);
  });
}
