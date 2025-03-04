// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'auth_service.dart';

class EventLogService {
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();

  // API Endpoints
  final String findFaceApiUrl = "http://34.57.13.68:18411/v2/event_logs"; // FindFace API
  final String tarantoolDbApiUrl = "http://34.57.13.68:8101/v2/event_logs"; // Tarantool Backend API

  Future<List<Map<String, dynamic>>> fetchEventLogs({
    DateTime? startDate,
    DateTime? endDate,
    bool? recognized,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      String? token = await _authService.getAuthToken();
      if (token == null) return [];

      Map<String, dynamic> queryParams = {
        "page": page,
        "limit": limit,
        if (startDate != null) "start_date": startDate.toIso8601String(),
        if (endDate != null) "end_date": endDate.toIso8601String(),
        if (recognized != null) "recognized": recognized.toString(),
      };

      // Headers with Authentication Token
      Options options = Options(headers: {"Authorization": "Token $token"});

      // Fetch Logs from FindFace API
      Response findFaceResponse = await _dio.get(findFaceApiUrl, queryParameters: queryParams, options: options);
      List<Map<String, dynamic>> findFaceLogs = List<Map<String, dynamic>>.from(findFaceResponse.data);

      // Fetch Logs from Tarantool Database
      Response tarantoolResponse = await _dio.get(tarantoolDbApiUrl, queryParameters: queryParams, options: options);
      List<Map<String, dynamic>> tarantoolLogs = List<Map<String, dynamic>>.from(tarantoolResponse.data);

      // Merge Logs and Sort by Timestamp (Newest First)
      List<Map<String, dynamic>> combinedLogs = [...findFaceLogs, ...tarantoolLogs];
      combinedLogs.sort((a, b) => (b["timestamp"] ?? "").compareTo(a["timestamp"] ?? ""));

      return combinedLogs;
    } catch (e) {
      print("Error fetching logs: $e");
      return [];
    }
  }
}

