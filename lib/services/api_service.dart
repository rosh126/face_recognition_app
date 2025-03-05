import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://34.57.13.68:8000'; // FindFace Server IP

  static Future<Map<String, dynamic>?> detectFace(String imagePath) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/face/detect'));
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    var response = await request.send();
    if (response.statusCode == 200) {
      return json.decode(await response.stream.bytesToString());
    } else {
      return null;
    }
  }
}
