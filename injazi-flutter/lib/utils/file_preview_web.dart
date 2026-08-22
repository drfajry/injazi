import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Opens raw bytes in a new browser tab using a Blob URL. Works for any
/// file type the browser can render natively (PDF, images) — the browser
/// shows its own preview, and the user can save it from there with the
/// browser's built-in "Save as" if they want a local copy.
///
/// Flutter-web only: this file uses package:web directly since this project
/// targets web exclusively (see pubspec — no mobile/desktop build targets).
void previewFileInNewTab(Uint8List bytes, String mimeType, String filename) {
  final blobParts = [bytes.toJS].toJS;
  final blob = web.Blob(blobParts, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);

  web.window.open(url, '_blank');

  // Revoke shortly after opening — the new tab has already loaded the blob
  // by then, and this avoids leaking the object URL for the session.
  Future.delayed(const Duration(minutes: 5), () => web.URL.revokeObjectURL(url));
}

