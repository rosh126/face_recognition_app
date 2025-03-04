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

    Options options = Options(headers: {"Authorization": "Token $token"});

    try {
      // Send Event to FindFace API
      Response findFaceResponse = await _dio.post(
        findFaceApiUrl,
        data: jsonEncode(eventData),
        options: options,
      );

      if (findFaceResponse.statusCode == 200) {
        print("Event logged in FindFace API.");
      }

      // Store Event in Tarantool Database
      Response tarantoolResponse = await _dio.post(
        tarantoolDbApiUrl,
        data: jsonEncode(eventData),
        options: options,
      );

      if (tarantoolResponse.statusCode == 200) {
        print("Event logged in Tarantool DB.");
      }
    } catch (e) {
      print("Error logging event: $e");
    }
  }
}

