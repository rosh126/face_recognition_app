// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, empty_catches

import 'package:flutter/foundation.dart' show kDebugMode;
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
  String _searchQuery = "";
  int _currentPage = 1;
  final int _perPage = 10;

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
        queryParameters: {
          'page': _currentPage,
          'per_page': _perPage,
          'search': _searchQuery.isNotEmpty ? _searchQuery : null,
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _watchlist = response.data['items'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching watchlist: $e");
      }
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
                } catch (e) {
                  if (kDebugMode) {
                    print("Error adding face: $e");
                  }
                }
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFace(String faceId) async {
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
    } catch (e) {
      if (kDebugMode) {
        print("Error deleting face: $e");
      }
    }
  }

  void _searchWatchlist(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
    });
    _fetchWatchlist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Watchlist")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _searchWatchlist,
              decoration: const InputDecoration(
                hintText: "Search by name...",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: _watchlist.isEmpty
                      ? const Center(child: Text("No watchlist entries found"))
                      : ListView.builder(
                          itemCount: _watchlist.length,
                          itemBuilder: (context, index) {
                            final face = _watchlist[index];
                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              child: ListTile(
                                leading: face["photo_url"] != null
                                    ? CircleAvatar(backgroundImage: NetworkImage(face["photo_url"]))
                                    : const CircleAvatar(child: Icon(Icons.person)),
                                title: Text(face["name"] ?? "Unknown"),
                                subtitle: Text("ID: ${face["id"]}"),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteFace(face["id"]),
                                ),
                              ),
                            );
                          },
                        ),
                ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _currentPage > 1
                    ? () {
                        setState(() {
                          _currentPage--;
                          _fetchWatchlist();
                        });
                      }
                    : null,
                child: const Text("Previous"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentPage++;
                    _fetchWatchlist();
                  });
                },
                child: const Text("Next"),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFace,
        child: const Icon(Icons.add),
      ),
    );
  }
}
