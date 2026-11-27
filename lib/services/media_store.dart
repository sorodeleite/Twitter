import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Copia fotos escolhidas na galeria para uma pasta do app.
///
/// O image_picker devolve um arquivo temporário em cache; sem essa cópia a
/// foto de perfil poderia desaparecer quando o Android limpasse o cache.
class MediaStore {
  static Future<String> persist(String sourcePath) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return sourcePath;
      final base = await getApplicationDocumentsDirectory();
      final folder = Directory('${base.path}/media');
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
      final extension = sourcePath.contains('.')
          ? sourcePath.substring(sourcePath.lastIndexOf('.'))
          : '.jpg';
      final target =
          '${folder.path}/foto-${DateTime.now().microsecondsSinceEpoch}$extension';
      final saved = await source.copy(target);
      return saved.path;
    } catch (_) {
      return sourcePath;
    }
  }
}
