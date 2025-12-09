import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class CloudinaryService {
  static const String cloudName = "dwky6mb0a";
  static const String uploadPreset = "unsigned_preset_app";
  static const String apiKey = "773249422261124";
  static const String apiSecret = "G8d0hwQLI7AG-XcWLFARdHChufs";

  // ---------- SUBIR IMAGEN Y REGRESAR SOLO EL URL ----------
  static Future<String> uploadImage(File file) async {
    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', 'jpg'),
        ),
      );

    final response = await request.send();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Error al subir imagen");
    }

    final resStr = await response.stream.bytesToString();
    final data = json.decode(resStr);

    return data["secure_url"]; // 👈 SOLO EL STRING
  }

  // ---------- SUBIR IMAGEN COMPLETA (url + public_id) ----------
  static Future<Map<String, dynamic>> uploadImageFull(File file) async {
    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', 'jpg'),
        ),
      );

    final response = await request.send();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Error al subir imagen");
    }

    final resStr = await response.stream.bytesToString();
    final data = json.decode(resStr);

    return {
      "url": data["secure_url"],
      "public_id": data["public_id"],
    };
  }

  // ---------- ELIMINAR IMAGEN ----------
  static Future<void> deleteImage(String publicId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final signatureRaw = "public_id=$publicId&timestamp=$timestamp$apiSecret";
    final signature = sha1.convert(utf8.encode(signatureRaw)).toString();

    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/destroy",
    );

    final response = await http.post(url, body: {
      "public_id": publicId,
      "api_key": apiKey,
      "timestamp": "$timestamp",
      "signature": signature,
    });

    if (response.statusCode != 200) {
      throw Exception("No se pudo eliminar la imagen");
    }
  }
}