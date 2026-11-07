import 'dart:convert';
import 'dart:typed_data';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Téléchargement direct dans le navigateur.
Future<bool> saveTextFile(String filename, String content) async {
  // BOM UTF-8 pour qu'Excel lise correctement les accents.
  final bytes = utf8.encode('\uFEFF$content');
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body!.append(a);
  a.click();
  a.remove();
  web.URL.revokeObjectURL(url);
  return true;
}

/// Téléchargement d'un fichier binaire (image PNG, par exemple).
Future<bool> saveBytesFile(
  String filename,
  List<int> bytes, {
  String type = 'image/png',
}) async {
  final blob = web.Blob(
    [Uint8List.fromList(bytes).toJS].toJS,
    web.BlobPropertyBag(type: type),
  );
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body!.append(a);
  a.click();
  a.remove();
  web.URL.revokeObjectURL(url);
  return true;
}
