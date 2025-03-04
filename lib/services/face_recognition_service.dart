// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'auth_service.dart';

class FaceRecognitionService {
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();

  // API Endpoints
  final String detectApiUrl = "http://34.57.13.68:18411/v2/detect";
  final String watchlistApiUrl = "http://34.57.13.68:18411/v2/cards/humans";
  final String eventLogApiUrl = "http://34.57.13.68:18411/v2/events";

  Future<Map<String, dynamic>?> detectFace(String imagePath) async {
    String? token = await _authService.getAuthToken();
    if (token == null) {
      print("Authentication failed. Cannot detect face.");
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
        String faceId = response.data['faces'][0]['id'];
        return await _checkWatchlist(faceId, token);
      } else {
        await _logEvent(null, false, token, "Face not detected");
        return null;
      }
    } catch (e) {
      print("Face detection error: $e");
      await _logEvent(null, false, token, "API Error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> _checkWatchlist(String faceId, String token) async {
    try {
      Response response = await _dio.get(
        "$watchlistApiUrl/?looks_like=detection:$faceId",
        options: Options(headers: {'Authorization': 'Token $token'}),
      );

      if (response.statusCode == 200 && response.data['items'].isNotEmpty) {
        await _logEvent(faceId, true, token, "Match found in watchlist");
        return response.data['items'][0];
      }
    } catch (e) {
      print("Watchlist check error: $e");
      await _logEvent(faceId, false, token, "Error checking watchlist: $e");
    }

    await _logEvent(faceId, false, token, "No match in watchlist");
    return null;
  }

  Future<void> _logEvent(String? faceId, bool recognized, String token, String description) async {
    try {
      await _dio.post(
        eventLogApiUrl,
        data: {
          "face_id": faceId,
          "recognized": recognized,
          "timestamp": DateTime.now().toIso8601String(),
          "description": description,
        },
        options: Options(headers: {'Authorization': 'Token $token'}),
      );
      print("Event logged: $description");
    } catch (e) {
      print("Error logging event: $e");
    }
  }
}

  
