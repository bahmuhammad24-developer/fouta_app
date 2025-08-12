import 'dart:io';

/// Very lightweight video editor that exposes common operations. All methods
/// currently act as no-ops and return the input file path. Real editing would
/// require integration with a dedicated plugin and additional security review.
class VideoEditor {
  Future<File> trim(File file, Duration start, Duration end) async {
    _log('trim ${file.path}');
    return file;
  }

  Future<File> crop(File file) async {
    _log('crop ${file.path}');
    return file;
  }

  Future<File> changeSpeed(File file, double multiplier) async {
    _log('speed ${file.path} x$multiplier');
    return file;
  }

  Future<File> overlay(File file, {String? sticker, String? text}) async {
    _log('overlay ${file.path}');
    return file;
  }

  void _log(String message) {
    final now = DateTime.now().toIso8601String();
    // ignore: avoid_print
    print('[$now][VideoEditor] $message');
  }
}
