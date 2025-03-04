// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String baseUrl = 'http://34.57.13.68'; // FindFace API Base URL
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<bool> login(String username, String password) async {
    try {
      String basicAuth = 'Basic ${base64Encode(utf8.encode('$username:$password'))}';
      var response = await http.post(
        Uri.parse('$baseUrl/auth/login/'),
        headers: {'Authorization': basicAuth},
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        await _storeAuthToken(responseData['token'], responseData['token_expiration_datetime']);
        return true;
      }
      return false;
    } catch (e) {
      print('Login Error: $e');
      return false;
    }
  }

  Future<void> _storeAuthToken(String token, String expiry) async {
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'token_expiry', value: expiry);
  }

  Future<String?> getAuthToken() async {
    String? token = await _storage.read(key: 'auth_token');
    String? expiry = await _storage.read(key: 'token_expiry');

    if (expiry != null) {
      DateTime expiryDate = DateTime.tryParse(expiry) ?? DateTime.now();
      if (DateTime.now().isAfter(expiryDate)) {
        await logout();
        return null;
      }
    }
    return token;
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<Map<String, dynamic>?> authenticateUser(File imageFile) async {
    try {
      String? token = await getAuthToken();
      if (token == null) return null;

      var response = await _sendMultipartRequest(
        endpoint: '/v1/identify',
        token: token,
        imageFile: imageFile,
      );

      if (response?.statusCode == 200) {
        return jsonDecode(await response!.stream.bytesToString());
      } else {
        print('Error: ${response?.statusCode} - ${await response?.stream.bytesToString()}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  Future<http.StreamedResponse?> _sendMultipartRequest({
    required String endpoint,
    required String token,
    required File imageFile,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'))
        ..headers['Authorization'] = 'Token $token'
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      return await request.send();
    } catch (e) {
      print('Multipart Request Error: $e');
      return null;
    }
  }

  authenticateWithFace() {}
}


