// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:async';

import '../services/auth_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  final AuthService _authService = AuthService();
  final Dio _dio = Dio();
  Timer? _frameCaptureTimer;

  final String faceRecognitionApiUrl = "http://34.57.13.68:18411/v2/recognition";
  final String eventLogApiUrl = "http://34.57.13.68:8081/log_event"; // Tarantool API endpoint
  List<Map<String, dynamic>> _detectedFaces = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras!.isNotEmpty) {
      _cameraController = CameraController(cameras![0], ResolutionPreset.medium);
      await _cameraController!.initialize();
      setState(() => _isCameraInitialized = true);

      // Start face detection
      _startFaceDetection();
    }
  }

  void _startFaceDetection() {
    _frameCaptureTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!_isProcessing && _cameraController != null && _cameraController!.value.isInitialized) {
        setState(() => _isProcessing = true);
        try {
          final XFile file = await _cameraController!.takePicture();
          await _processFaceDetection(File(file.path));
        } catch (e) {
          if (kDebugMode) {
            print("Error capturing frame: $e");
          }
        } finally {
          setState(() => _isProcessing = false);
        }
      }
    });
  }

  Future<void> _processFaceDetection(File imageFile) async {
    try {
      String? token = await _authService.getAuthToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      FormData formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(imageFile.path, filename: 'frame.jpg'),
      });

      Response response = await _dio.post(
        faceRecognitionApiUrl,
        data: formData,
        options: Options(headers: {'Authorization': 'Token $token'}),
      );

      if (response.statusCode == 200) {
        _updateFaceBoundingBoxes(response.data);
        await _logEvent(response.data);
      } else {
        if (kDebugMode) {
          print("Face recognition failed");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error in face detection: $e");
      }
    }
  }

  void _updateFaceBoundingBoxes(dynamic data) {
    List<Map<String, dynamic>> detectedFaces = [];

    if (data['faces'] != null) {
      for (var face in data['faces']) {
        detectedFaces.add({
          'x': face['x'],
          'y': face['y'],
          'width': face['width'],
          'height': face['height'],
          'name': face['name'] ?? 'Unknown',
        });
      }
    }

    setState(() {
      _detectedFaces = detectedFaces;
    });
  }

  Future<void> _logEvent(dynamic data) async {
    try {
      String? token = await _authService.getAuthToken();
      if (token == null) return;

      for (var face in data['faces']) {
        Map<String, dynamic> event = {
          "face_id": face['face_id'] ?? "unknown",
          "name": face['name'] ?? "Unknown",
          "timestamp": DateTime.now().toIso8601String(),
          "status": face['recognized'] ? "Recognized" : "Unrecognized"
        };

        await _dio.post(
          eventLogApiUrl,
          data: event,
          options: Options(headers: {'Authorization': 'Token $token'}),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error logging event: $e");
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _frameCaptureTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Face Recognition Camera")),
      body: Stack(
        children: [
          // Camera preview
          _isCameraInitialized
              ? CameraPreview(_cameraController!)
              : const Center(child: CircularProgressIndicator()),

          // Face bounding boxes
          if (_isCameraInitialized) ...[
            Positioned.fill(
              child: CustomPaint(
                painter: FaceBoundingBoxPainter(_detectedFaces),
              ),
            ),
          ],

          // Capture button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _captureAndRecognize,
                icon: const Icon(Icons.camera_alt),
                label: const Text("Manually Capture & Recognize"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureAndRecognize() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final XFile file = await _cameraController!.takePicture();
      await _processFaceDetection(File(file.path));
    } catch (e) {
      if (kDebugMode) {
        print("Error capturing image: $e");
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}

// CustomPainter to draw bounding boxes around detected faces
class FaceBoundingBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> faces;

  FaceBoundingBoxPainter(this.faces);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (var face in faces) {
      double x = face['x'].toDouble();
      double y = face['y'].toDouble();
      double width = face['width'].toDouble();
      double height = face['height'].toDouble();
      String name = face['name'];

      // Draw rectangle
      canvas.drawRect(Rect.fromLTWH(x, y, width, height), paint);

      // Draw text above face
      textPainter.text = TextSpan(
        text: name,
        style: const TextStyle(color: Colors.white, fontSize: 14.0),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x, y - 20));
    }
  }

  @override
  bool shouldRepaint(FaceBoundingBoxPainter oldDelegate) {
    return true;
  }
}
