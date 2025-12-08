import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/detection_record.dart';

class DetectionService {
  DetectionService({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  static const String _defaultEndpoint =
      String.fromEnvironment('DETECTION_API_URL',
          defaultValue: 'http://10.0.2.2:8000/detect');

  final http.Client _client;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<DetectionRecord>> runDetection(File imageFile,
      {String? endpoint}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final token = await user.getIdToken();
    final uri = Uri.parse(endpoint ?? _defaultEndpoint);
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

    final streamedResponse = await request.send();
    final body = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode >= 400) {
      throw HttpException(
        'Detection failed (${streamedResponse.statusCode}): $body',
        uri: uri,
      );
    }

    final parsed = jsonDecode(body) as Map<String, dynamic>;
    final detections = (parsed['detections'] as List<dynamic>? ?? [])
        .map((item) =>
            DetectionRecord.fromJson(item as Map<String, dynamic>))
        .toList();

    return detections;
  }
}

