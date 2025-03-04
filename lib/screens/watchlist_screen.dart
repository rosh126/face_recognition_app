// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, empty_catches

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  _WatchlistScreenState createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();
  final String watchlistApiUrl = "http://34.57.13.68:18411/v2/cards/humans";
  List<dynamic> _watchlist = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchWatchlist();
  }

  Future<void> _fetchWatchlist() async {
    setState(() => _isLoading = true);
    try {
      String? token = await _authService.getAuthToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }
      Response response = await _dio.get(
        watchlistApiUrl,
        options: Options(headers: {'Authorization': 'Token $token'}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _watchlist = response.data['items'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addFace() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final imagePath = pickedFile.path;
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Name"),
        content: TextField(controller: nameController),
        actions: [
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  String? token = await _authService.getAuthToken();
                  if (token == null) {
                    Navigator.pushReplacementNamed(context, '/');
                    return;
                  }
                  FormData formData = FormData.fromMap({
                    'photo': await MultipartFile.fromFile(imagePath, filename: 'face.jpg'),
                    'name': nameController.text,
                  });
                  await _dio.post(
                    watchlistApiUrl,
                    data: formData,
                    options: Options(headers: {'Authorization': 'Token $token'}),
                  );
                  _fetchWatchlist();
                } catch (e) {}
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFace(String faceId) async {
    try {
      String? token = await _authService.getAuthToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }
      await _dio.delete(
        "$watchlistApiUrl/$faceId",
        options: Options(headers: {'Authorization': 'Token $token'}),
      );
      _fetchWatchlist();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Watchlist Management"),
        backgroundColor: Colors.deepPurple, // Matching theme with other screens
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _watchlist.isEmpty
              ? const Center(child: Text("No faces in watchlist"))
              : ListView.builder(
                  itemCount: _watchlist.length,
                  itemBuilder: (context, index) {
                    final face = _watchlist[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: face['photo'] != null
                              ? Image.network(face['photo'], width: 50, height: 50, fit: BoxFit.cover)
                              : const Icon(Icons.person, size: 50),
                        ),
                        title: Text(face['name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeFace(face['id']),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: _addFace,
        child: const Icon(Icons.add),
      ),
    );
  }
}