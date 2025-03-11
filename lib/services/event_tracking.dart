// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:dio/dio.dart';
import 'auth_service.dart';

class EventTrackingService {
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();

  // API Endpoints
  final String findFaceApiUrl = "http://34.57.13.68:18411/v2/log_event"; // FindFace API
  final String tarantoolDbApiUrl = "http://34.57.13.68:8101/v2/event_logs"; // Tarantool Backend API

  Future<void> logEvent(String faceId, bool isRecognized) async {
    try {
      String? token = await _authService.getAuthToken();
      if (token == null) {
        print("Authentication failed. Unable to log event.");
        return;
      }

      Map<String, dynamic> eventData = {
        "face_id": faceId,
        "timestamp": DateTime.now().toIso8601String(),
        "recognized": isRecognized,
      };

      Options options = Options(
        headers: {"Authorization": "Token $token"},
        receiveTimeout: const Duration(seconds: 10),
      );

      // Log event in FindFace API
      await _logToFindFace(eventData, options);

      // Log event in Tarantool Database
      await _logToTarantool(eventData, options);
    } catch (e) {
      print("Unexpected error logging event: $e");
    }
  }

  Future<void> _logToFindFace(Map<String, dynamic> eventData, Options options) async {
    try {
      Response response = await _dio.post(
        findFaceApiUrl,
        data: jsonEncode(eventData),
        options: options,
      );

      if (response.statusCode == 200) {
        print("Event logged successfully in FindFace API.");
      } else {
        print("FindFace API Error: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      print("Error logging event in FindFace API: $e");
    }
  }

  Future<void> _logToTarantool(Map<String, dynamic> eventData, Options options) async {
    try {
      Response response = await _dio.post(
        tarantoolDbApiUrl,
        data: jsonEncode(eventData),
        options: options,
      );

      if (response.statusCode == 200) {
        print("Event logged successfully in Tarantool DB.");
      } else {
        print("Tarantool API Error: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      print("Error logging event in Tarantool DB: $e");
    }
  }
}
