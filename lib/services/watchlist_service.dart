// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:dio/dio.dart';
import 'auth_service.dart';

class WatchlistService {
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();

  // API Endpoints
  final String findFaceWatchlistUrl = "http://34.57.13.68:18411/v2/watchlist";
  final String tarantoolWatchlistUrl = "http://34.57.13.68:8101/v2/watchlist";

  Future<List<Map<String, dynamic>>> fetchWatchlist() async {
    try {
      String? token = await _authService.getAuthToken();
      if (token == null) return [];

      Options options = Options(headers: {"Authorization": "Token $token"});

      // Fetch watchlist from FindFace API
      Response findFaceResponse = await _dio.get(findFaceWatchlistUrl, options: options);
      List<Map<String, dynamic>> findFaceWatchlist = List<Map<String, dynamic>>.from(findFaceResponse.data);

      // Fetch watchlist from Tarantool
      Response tarantoolResponse = await _dio.get(tarantoolWatchlistUrl, options: options);
      List<Map<String, dynamic>> tarantoolWatchlist = List<Map<String, dynamic>>.from(tarantoolResponse.data);

      // Merge both watchlists
      List<Map<String, dynamic>> combinedWatchlist = [...findFaceWatchlist, ...tarantoolWatchlist];

      return combinedWatchlist;
    } catch (e) {
      print("Error fetching watchlist: $e");
      return [];
    }
  }

  Future<bool> addToWatchlist(String faceId, String name, String category) async {
    try {
      String? token = await _authService.getAuthToken();
      if (token == null) return false;

      Map<String, dynamic> watchlistEntry = {
        "face_id": faceId,
        "name": name,
        "category": category, // Example: "VIP", "Banned", "Employee"
        "timestamp": DateTime.now().toIso8601String(),
      };

      Options options = Options(headers: {"Authorization": "Token $token"});

      // Add to FindFace API Watchlist
      Response findFaceResponse = await _dio.post(findFaceWatchlistUrl, data: jsonEncode(watchlistEntry), options: options);
      bool findFaceSuccess = findFaceResponse.statusCode == 200;

      // Add to Tarantool Watchlist
      Response tarantoolResponse = await _dio.post(tarantoolWatchlistUrl, data: jsonEncode(watchlistEntry), options: options);
      bool tarantoolSuccess = tarantoolResponse.statusCode == 200;

      return findFaceSuccess && tarantoolSuccess;
    } catch (e) {
      print("Error adding to watchlist: $e");
      return false;
    }
  }

  Future<bool> removeFromWatchlist(String faceId) async {
    try {
      String? token = await _authService.getAuthToken();
      if (token == null) return false;

      Options options = Options(headers: {"Authorization": "Token $token"});

      // Remove from FindFace API Watchlist
      Response findFaceResponse = await _dio.delete("$findFaceWatchlistUrl/$faceId", options: options);
      bool findFaceSuccess = findFaceResponse.statusCode == 200;

      // Remove from Tarantool Watchlist
      Response tarantoolResponse = await _dio.delete("$tarantoolWatchlistUrl/$faceId", options: options);
      bool tarantoolSuccess = tarantoolResponse.statusCode == 200;

      return findFaceSuccess && tarantoolSuccess;
    } catch (e) {
      print("Error removing from watchlist: $e");
      return false;
    }
  }

  Future<bool> isFaceInWatchlist(String faceId) async {
    List<Map<String, dynamic>> watchlist = await fetchWatchlist();
    return watchlist.any((entry) => entry["face_id"] == faceId);
  }
}
