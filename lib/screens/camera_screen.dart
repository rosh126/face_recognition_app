// ignore_for_file: unnecessary_import, library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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
  final String faceRecognitionApiUrl = "http://34.57.13.68:18411/v2/recognition";

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
    }
  }

  Future<void> _captureAndRecognize() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final XFile file = await _cameraController!.takePicture();
      await _sendForRecognition(File(file.path));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error capturing image")));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _sendForRecognition(File imageFile) async {
    try {
      String? token = await _authService.getAuthToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      FormData formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(imageFile.path, filename: 'captured_face.jpg'),
      });

      Response response = await _dio.post(
        faceRecognitionApiUrl,
        data: formData,
        options: Options(headers: {'Authorization': 'Token $token'}),
      );

      if (response.statusCode == 200) {
        _showRecognitionResult(response.data);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Recognition failed")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error processing image")));
    }
  }

  void _showRecognitionResult(dynamic data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Recognition Result"),
        content: Text("Recognized: ${data['recognized'] ? 'Yes' : 'No'}\nName: ${data['name'] ?? 'Unknown'}"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("OK")),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Face Recognition Camera")),
      body: Column(
        children: [
          _isCameraInitialized
              ? AspectRatio(
                  aspectRatio: _cameraController!.value.aspectRatio,
                  child: CameraPreview(_cameraController!),
                )
              : Center(child: CircularProgressIndicator()),
          SizedBox(height: 20),
          _isProcessing
              ? CircularProgressIndicator()
              : ElevatedButton.icon(
                  onPressed: _captureAndRecognize,
                  icon: Icon(Icons.camera_alt),
                  label: Text("Capture & Recognize"),
                ),
        ],
      ),
    );
  }
}

