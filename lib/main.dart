import 'package:flutter/material.dart';
import 'screens/camera_screen.dart';
import 'screens/event_log_screen.dart';
import 'screens/watchlist_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const FaceRecognitionApp());
}

class FaceRecognitionApp extends StatelessWidget {
  const FaceRecognitionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Face Recognition',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreen(),
      routes: {
        "/camera": (context) => const CameraScreen(),
        "/watchlist": (context) => const WatchlistScreen(),
        "/event_logs": (context) => const EventLogScreen(),
        "/dashboard": (context) => const DashboardScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const DashboardScreen(),
    const CameraScreen(),
    const EventLogScreen(),
    const WatchlistScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Recognition App')),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.camera), label: 'Camera'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Event Logs'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Watchlist'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
