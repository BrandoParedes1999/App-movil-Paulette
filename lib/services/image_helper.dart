import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

class ImageHelper {
  // Esta función hace la magia: comprime y arregla la rotación (autoCorrectionAngle: true)
  static Future<File?> fixRotationAndCompress(File file) async {
    try {
      final dir = await path_provider.getTemporaryDirectory();
      // Creamos una ruta temporal para la nueva imagen corregida
      final targetPath = '${dir.absolute.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85, // Calidad 85% (reduce tamaño sin perder mucha calidad visible)
        autoCorrectionAngle: true, // 👈 ¡ESTO ES LA CLAVE! Arregla la rotación
        format: CompressFormat.jpeg, // Aseguramos formato JPG
      );

      if (result == null) return null;

      // Devolvemos el nuevo archivo ya rotado físicamente
      return File(result.path);
    } catch (e) {
      print("Error al procesar imagen: $e");
      return file; // Si falla, devolvemos la original aunque esté chueca
    }
  }
}