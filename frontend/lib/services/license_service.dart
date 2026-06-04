import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class LicenseService {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const FlutterSecureStorage storage = FlutterSecureStorage();

  static Future<bool> registerLicenseImage({
    required XFile imageFile,
  }) async {
    final token = await storage.read(key: 'access_token');

    if (token == null) {
      return false;
    }

    final url = Uri.parse('$baseUrl/license/register');

    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';

    final bytes = await imageFile.readAsBytes();

    final extension = imageFile.name.split('.').last.toLowerCase();

    String mimeType = 'jpeg';

    if (extension == 'png') {
      mimeType = 'png';
    } else if (extension == 'jpg' || extension == 'jpeg') {
      mimeType = 'jpeg';
    } else if (extension == 'webp') {
      mimeType = 'webp';
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: imageFile.name,
        contentType: MediaType('image', mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('license upload status: ${response.statusCode}');
    print('license upload body: ${response.body}');

    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> getLicenseStatus() async {
    final token = await storage.read(key: 'access_token');

    if (token == null) {
      return null;
    }

    final url = Uri.parse('$baseUrl/license/status');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }
}