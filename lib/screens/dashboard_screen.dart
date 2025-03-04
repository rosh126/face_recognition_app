// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();
  final String analyticsApiUrl = "http://34.57.13.68:18411/v2/analytics";

  int totalRecognized = 0;
  int watchlistAlerts = 0;
  List<FlSpot> faceRecognitionTrends = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() => _isLoading = true);
    try {
      String? token = await _authService.getAuthToken();
      if (token == null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/');
        return;
      }

      Response response = await _dio.get(
        analyticsApiUrl,
        options: Options(headers: {'Authorization': 'Token $token'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          totalRecognized = response.data['total_recognized'] ?? 0;
          watchlistAlerts = response.data['watchlist_alerts'] ?? 0;
          faceRecognitionTrends = (response.data['trend'] as List<dynamic>? ?? [])
              .map((data) => FlSpot(
                    (data['day'] ?? 0).toDouble(),
                    (data['count'] ?? 0).toDouble(),
                  ))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching analytics: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Analytics"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAnalytics),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStats(),
                Expanded(child: _buildChart()),
              ],
            ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCard("Total Recognized", totalRecognized.toString(), Icons.face),
          _buildStatCard("Watchlist Alerts", watchlistAlerts.toString(), Icons.warning),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.deepPurple),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, color: Colors.deepPurple)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: faceRecognitionTrends,
              isCurved: true,
              color: Colors.deepPurple,
              barWidth: 4,
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}






