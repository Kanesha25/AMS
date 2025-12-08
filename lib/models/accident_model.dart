import 'detection_record.dart';

class AccidentModel {
  final String id;
  final String location;
  final String description;
  final DateTime timestamp;
  final String status;
  final String vehicleNumber;
  final String vehicleModel;
  final List<String> imageUrls;
  final List<DetectionRecord> detections;
  final List<Map<String, dynamic>> estimatedParts;
  final int? estimatedMinCost;
  final int? estimatedMaxCost;

  AccidentModel({
    required this.id,
    required this.location,
    required this.description,
    required this.timestamp,
    required this.status,
    required this.vehicleNumber,
    required this.vehicleModel,
    List<String>? imageUrls,
    List<DetectionRecord>? detections,
    List<Map<String, dynamic>>? estimatedParts,
    this.estimatedMinCost,
    this.estimatedMaxCost,
  })  : imageUrls = imageUrls ?? const [],
        detections = detections ?? const [],
        estimatedParts = estimatedParts ?? const [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'vehicleNumber': vehicleNumber,
      'vehicleModel': vehicleModel,
      'imageUrls': imageUrls,
      'detections': detections.map((detection) => detection.toJson()).toList(),
      'estimatedParts': estimatedParts,
      'estimatedMinCost': estimatedMinCost,
      'estimatedMaxCost': estimatedMaxCost,
    };
  }

  factory AccidentModel.fromJson(Map<String, dynamic> json) {
    final imageUrlList = (json['imageUrls'] as List<dynamic>? ?? [])
        .map((value) => value.toString())
        .toList();
    final detectionList = (json['detections'] as List<dynamic>? ?? [])
        .map(
          (item) => DetectionRecord.fromJson(item as Map<String, dynamic>),
        )
        .toList();
    final estimatedPartsList =
        (json['estimatedParts'] as List<dynamic>? ?? []).map((item) {
          if (item is Map<String, dynamic>) return item;
          return <String, dynamic>{};
        }).toList();

    return AccidentModel(
      id: json['id'],
      location: json['location'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      status: json['status'],
      vehicleNumber: json['vehicleNumber'] ?? '',
      vehicleModel: json['vehicleModel'] ?? '',
      imageUrls: imageUrlList,
      detections: detectionList,
      estimatedParts: estimatedPartsList,
      estimatedMinCost: (json['estimatedMinCost'] as num?)?.toInt(),
      estimatedMaxCost: (json['estimatedMaxCost'] as num?)?.toInt(),
    );
  }
}