import 'package:media_kit_video/media_kit_video.dart';

/// Provides a no-op [dispose] for [VideoController] to maintain
/// compatibility with versions of `media_kit_video` that do not expose
/// an explicit dispose method.
extension VideoControllerExtensions on VideoController? {
  /// Safely dispose the controller if the underlying implementation
  /// provides a [dispose] method. For older versions where no dispose is
  /// necessary, this acts as a no-op.
  void dispose() {
    final controller = this;
    if (controller != null) {
      try {
        // Some versions of `media_kit_video` expose a `dispose` method on
        // [VideoController]. Use dynamic invocation so that calling code
        // compiles regardless of the version in use.
        (controller as dynamic).dispose();
      } catch (_) {
        // ignore: no dispose available
      }
    }
  }
}
