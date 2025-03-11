// ignore_for_file: library_private_types_in_public_api, unused_import, deprecated_member_use, unused_element, camel_case_types

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import 'camera_screen.dart';
import 'watchlist_screen.dart' as watchlist;
import 'event_log_screen.dart' as event_log;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();
  final String analyticsApiUrl = "http://34.57.13.68:18810/api/v2/analytics";

  int totalRecognized = 0;
  int watchlistAlerts = 0;
  int totalWatchlistFaces = 0;
  double recognitionRate = 0.0;
  List<FlSpot> faceRecognitionTrends = [];
  bool _isLoading = false;
  bool isAdmin = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() => _isLoading = true);
    try {
      String? token = await _authService.getAuthToken();
      isAdmin = await _authService.isAdmin();

      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Authentication token not found. Please login again.")),
          );
          Navigator.pushReplacementNamed(context, '/');
        }
        return;
      }

      Response response = await _dio.get(
        analyticsApiUrl,
        options: Options(
          headers: {'Authorization': 'Token $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          totalRecognized = response.data['total_recognized'] ?? 0;
          watchlistAlerts = response.data['watchlist_alerts'] ?? 0;
          totalWatchlistFaces = response.data['total_watchlist_faces'] ?? 0;
          recognitionRate = (response.data['recognition_rate'] ?? 0).toDouble();
          faceRecognitionTrends = (response.data['trend'] as List<dynamic>? ?? [])
              .map((data) => FlSpot(
                    (data['day'] ?? 0).toDouble(),
                    (data['count'] ?? 0).toDouble(),
                  ))
              .toList();
        });
      } else if (response.statusCode == 401) {
        if (mounted) {
          await _authService.logout();
          Navigator.pushReplacementNamed(context, '/');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching analytics: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAnalytics),
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _authService.logout();
                if (mounted) Navigator.pushReplacementNamed(context, '/');
              }),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Analytics"),
          BottomNavigationBarItem(icon: Icon(Icons.camera), label: "Camera"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Watchlist"),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildStats();
      case 1:
        return const CameraScreen();
      case 2:
        return const watchlist.WatchlistScreen();
      case 3:
        return const event_log.EventLogScreen();
      default:
        return _buildStats();
    }
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildStatCard("Total Recognized", totalRecognized.toString(), Icons.face),
              _buildStatCard("Watchlist Alerts", watchlistAlerts.toString(), Icons.warning, navigateTo: 'watchlist'),
              if (isAdmin) _buildStatCard("Watchlist Faces", totalWatchlistFaces.toString(), Icons.people, navigateTo: 'event_log'),
              if (isAdmin) _buildStatCard("Recognition Rate", "${recognitionRate.toStringAsFixed(2)}%", Icons.trending_up),
              _buildChart(),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraScreen())),
            child: const Text("Scan Face"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, {String? navigateTo}) {
    return GestureDetector(
      onTap: navigateTo == null
          ? null
          : () {
              if (navigateTo == 'watchlist') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const watchlist.WatchlistScreen()));
              } else if (navigateTo == 'event_log') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const event_log.EventLogScreen()));
              }
            },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      // Your chart widget implementation
    );
  }
}
