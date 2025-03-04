import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';

class EventLogScreen extends StatefulWidget {
  const EventLogScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EventLogScreenState createState() => _EventLogScreenState();
}

class _EventLogScreenState extends State<EventLogScreen> {
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();
  final String eventLogApiUrl = "http://34.57.13.68:18411/v2/events";
  List<dynamic> _eventLogs = [];
  DateTime? _startDate;
  DateTime? _endDate;
  int _currentPage = 1;
  final int _perPage = 10;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchEventLogs();
  }

  Future<void> _fetchEventLogs() async {
    setState(() => _isLoading = true);
    try {
      String? token = await _authService.getAuthToken();
      if (token == null) {
        // ignore: use_build_context_synchronously
        Navigator.pushReplacementNamed(context, '/');
        return;
      }
      Response response = await _dio.get(eventLogApiUrl, options: Options(headers: {'Authorization': 'Token $token'}), queryParameters: {
        'start_date': _startDate?.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
        'page': _currentPage,
        'per_page': _perPage,
      });
      if (response.statusCode == 200) {
        setState(() {
          _eventLogs = response.data['events'];
          _isLoading = false;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error fetching event logs: $e");
      setState(() => _isLoading = false);
    }
  }

  void _openDatePicker(BuildContext context, bool isStart) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    setState(() {
      if (isStart) {
        _startDate = pickedDate;
      } else {
        _endDate = pickedDate;
      }
      _fetchEventLogs();
    });
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Event Logs")),
      body: _isLoading
          ? Center(child: Lottie.asset('assets/loading.json', height: 150))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _openDatePicker(context, true),
                        child: Text(_startDate == null ? "Start Date" : DateFormat.yMd().format(_startDate!)),
                      ),
                      ElevatedButton(
                        onPressed: () => _openDatePicker(context, false),
                        child: Text(_endDate == null ? "End Date" : DateFormat.yMd().format(_endDate!)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _eventLogs.isEmpty
                      ? Center(child: Lottie.asset('assets/no_data.json', height: 150))
                      : ListView.builder(
                          itemCount: _eventLogs.length,
                          itemBuilder: (context, index) {
                            final event = _eventLogs[index];
                            return Card(
                              elevation: 3,
                              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              child: ListTile(
                                leading: Icon(event["recognized"] ? Icons.check_circle : Icons.error, color: event["recognized"] ? Colors.green : Colors.red),
                                title: Text("Face ID: ${event["face_id"]}"),
                                subtitle: Text("Timestamp: ${DateFormat.yMMMd().add_jm().format(DateTime.parse(event["timestamp"]))}"),
                              ),
                            );
                          },
                        ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _currentPage > 1 ? () {
                        setState(() {
                          _currentPage--;
                          _fetchEventLogs();
                        });
                      } : null,
                      child: Text("Previous"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentPage++;
                          _fetchEventLogs();
                        });
                      },
                      child: Text("Next"),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
