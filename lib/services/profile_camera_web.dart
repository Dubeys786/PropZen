// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';

class ProfileCameraHelper {
  static bool get isCameraSupported {
    try {
      return html.window.navigator.mediaDevices != null;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> capturePhoto() async {
    final completer = Completer<Map<String, dynamic>?>();
    try {
      final input = html.FileUploadInputElement()
        ..accept = 'image/jpeg,image/png,image/webp'
        ..setAttribute('capture', 'user');

      input.onChange.listen((event) async {
        final files = input.files;
        if (files == null || files.isEmpty) {
          if (!completer.isCompleted) completer.complete(null);
          return;
        }

        final file = files[0];
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((_) {
          try {
            final result = reader.result;
            if (result is ByteBuffer) {
              final bytes = Uint8List.view(result);
              if (!completer.isCompleted) {
                completer.complete({
                  'bytes': bytes,
                  'name': file.name,
                  'size': file.size,
                });
              }
            } else if (result is Uint8List) {
              if (!completer.isCompleted) {
                completer.complete({
                  'bytes': result,
                  'name': file.name,
                  'size': file.size,
                });
              }
            } else {
              if (!completer.isCompleted) completer.complete(null);
            }
          } catch (_) {
            if (!completer.isCompleted) completer.complete(null);
          }
        });

        reader.onError.listen((_) {
          if (!completer.isCompleted) completer.complete(null);
        });
      });

      // Listen for window focus to detect cancellation if user cancels file dialog
      void onFocus(html.Event e) {
        Future.delayed(const Duration(seconds: 1), () {
          if (!completer.isCompleted && (input.files == null || input.files!.isEmpty)) {
            completer.complete(null);
          }
        });
      }

      html.window.addEventListener('focus', onFocus, true);
      completer.future.whenComplete(() {
        html.window.removeEventListener('focus', onFocus, true);
      });

      input.click();
    } catch (e) {
      if (!completer.isCompleted) completer.complete(null);
    }

    return completer.future;
  }
}
