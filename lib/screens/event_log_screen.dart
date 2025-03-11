// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, empty_catches, unused_field, unused_element

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';

class EventLogScreen extends StatefulWidget {
  const EventLogScreen({super.key});

  @override
  _EventLogScreenState createState() => _EventLogScreenState();
}

class _EventLogScreenState extends State<EventLogScreen> {
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();
  final String eventLogApiUrl = "http://34.57.13.68:18411/v2/event_logs"; // ✅ Corrected API URL
  List<dynamic> _eventLogs = [];
  bool _isLoading = false;
  int _currentPage = 1;
  final int _perPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchEventLogs();
  }

  /// 🔹 Fetch Event Logs from API
  Future<void> _fetchEventLogs() async {
    setState(() => _isLoading = true);
    try {
      String? token = await _authService.getAuthToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }
      Response response = await _dio.get(
        eventLogApiUrl,
        options: Options(headers: {'Authorization': 'Token $token'}),
        queryParameters: {
          'page': _currentPage,
          'per_page': _perPage,
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _eventLogs = response.data['items'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching event logs: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔹 Pagination Controls
  void _nextPage() {
    setState(() {
      _currentPage++;
    });
    _fetchEventLogs();
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _fetchEventLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Event Logs")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _eventLogs.isEmpty
                      ? const Center(child: Text("No event logs found"))
                      : ListView.builder(
                          itemCount: _eventLogs.length,
                          itemBuilder: (context, index) {
                            final event = _eventLogs[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              child: ListTile(
                                leading: const Icon(Icons.event),
                                title: Text(event["description"] ?? "No Description"),
                                subtitle: Text("Timestamp: ${event["timestamp"]}"),
                              ),
                            );
                          },
                        ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _currentPage > 1 ? _previousPage : null,
                      child: const Text("Previous"),
                    ),
                    ElevatedButton(
                      onPressed: _nextPage,
                      child: const Text("Next"),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
