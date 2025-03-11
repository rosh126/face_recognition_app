import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static const String baseUrl = 'http://34.57.13.68:18333';  // FindFace API URL
  static const String loginUrl = '$baseUrl/auth/login/';  // Authentication Endpoint
  static const String userInfoUrl = '$baseUrl/api/user/';  // Fetch User Info

  /// 🔹 Login Function with Token Authentication
  Future<bool> login(String username, String password) async {
    try {
      var response = await http.post(
        Uri.parse(loginUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        String token = data['token']; // Extract authentication token

        if (token.isNotEmpty) {
          await _saveAuthToken(token);
          return true;
        }
      } else {
        if (kDebugMode) {
          print('❌ Login failed: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Login error: $e');
      }
    }
    return false;
  }

  /// 🔹 Store Authentication Token
  Future<void> _saveAuthToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    if (kDebugMode) print('🔹 Token stored successfully');
  }

  /// 🔹 Retrieve Authentication Token
  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// 🔹 Check if User is Admin
  Future<bool> isAdmin() async {
    String? token = await getAuthToken();
    if (token == null) return false;

    try {
      var response = await http.get(
        Uri.parse(userInfoUrl),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['role'] == 'admin'; // Check if user is admin
      }
    } catch (e) {
      if (kDebugMode) print('❌ Admin check error: $e');
    }
    return false;
  }

  /// 🔹 Logout Function (Clear Token)
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (kDebugMode) print('🔹 Logged out successfully');
  }

  /// 🔹 Fetch User Details
  Future<Map<String, dynamic>?> fetchUserDetails() async {
    String? token = await getAuthToken();
    if (token == null) return null;

    try {
      var response = await http.get(
        Uri.parse(userInfoUrl),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error fetching user details: $e');
    }
    return null;
  }
}
