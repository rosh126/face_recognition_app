// ignore_for_file: avoid_print, unused_import

import 'dart:convert';
import 'package:dio/dio.dart';
import 'auth_service.dart';
import 'event_tracking.dart';

class FaceRecognitionService {
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();
  final EventTrackingService _eventTrackingService = EventTrackingService();

  // API Endpoints
  final String detectApiUrl = "http://34.57.13.68:18411/v2/detect"; // Face Detection
  final String watchlistApiUrl = "http://34.57.13.68:18411/v2/cards/humans"; // Watchlist Matching
  final String livenessApiUrl = "http://34.57.13.68:18411/v2/liveness"; // Liveness Detection

  Future<Map<String, dynamic>?> detectAndRecognizeFace(String imagePath) async {
    String? token = await _authService.getAuthToken();
    if (token == null) {
      print("Authentication failed. Cannot process face recognition.");
      return null;
    }

    try {
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath, filename: 'face.jpg'),
      });

      Response response = await _dio.post(
        detectApiUrl,
        data: formData,
        options: Options(headers: {'Authorization': 'Token $token'}),
      );

      if (response.statusCode == 200 && response.data['faces'].isNotEmpty) {
        List<dynamic> detectedFaces = response.data['faces'];
        print("Detected Faces: $detectedFaces");

        for (var face in detectedFaces) {
          String faceId = face['id'];
          bool isLive = await _checkLiveness(faceId, token);
          if (!isLive) {
            print("Liveness check failed. Possible spoofing detected.");
            await _eventTrackingService.logEvent(faceId, false);
            return null;
          }
        }
      }
    } catch (e) {
      print("Error during face detection and recognition: $e");
    }
    return null;
  }

  Future<bool> _checkLiveness(String faceId, String token) async {
    try {
      Response response = await _dio.post(
        livenessApiUrl,
        data: {'face_id': faceId},
        options: Options(headers: {'Authorization': 'Token $token'}),
      );

      if (response.statusCode == 200 && response.data['liveness'] == true) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error during liveness check: $e");
      return false;
    }
  }
}