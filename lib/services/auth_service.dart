// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = 'http://34.57.13.68:18333'; // FindFace Security API
  final String loginUrl = "http://34.57.13.68:18333/auth/login/"; // Login API

  static const String adminUsername = "admin";
  static const String adminPassword = "Admin@1234"; // Fixed admin password

  /// 🔹 Login Function
  Future<bool> login(String username, String password) async {
    // Validate hardcoded credentials first
    if (username == adminUsername && password == adminPassword) {
      print('✅ Hardcoded admin login successful.');
      await _storeToken("dummy_token"); // Store a dummy token
      return true;
    }

    try {
      print('🔹 Attempting login for user: $username');

      var response = await http.post(
        Uri.parse(loginUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      print('🔹 Response Status: ${response.statusCode}');
      print('🔹 Response Data: ${response.body}');

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        final token = responseData['token'];

        if (token != null) {
          await _storeToken(token);
          return true;
        }
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized: Invalid credentials.');
      } else {
        print('❌ Unexpected error: ${response.statusCode}');
      }
      return false;
    } catch (e) {
      print('❌ Login error: $e');
      return false;
    }
  }

  /// 🔹 Store authentication token
  Future<void> _storeToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    print('🔹 Token stored successfully');
  }

  /// 🔹 Retrieve authentication token
  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// 🔹 Check if user is authenticated
  Future<bool> isAuthenticated() async {
    String? token = await getAuthToken();
    return token != null;
  }

  /// 🔹 Check if user is Admin
  Future<bool> isAdmin() async {
    String? token = await getAuthToken();
    return token != null && token == "dummy_token"; // Dummy check for admin
  }

  /// 🔹 Logout function
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    print('🔹 Logged out successfully');
  }

  authenticateWithFace(File context) {}
}
