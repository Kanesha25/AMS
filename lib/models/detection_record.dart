class DetectionRecord {
  final String label;
  final double confidence;
  final List<double> boundingBox;

  DetectionRecord({
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });

  factory DetectionRecord.fromJson(Map<String, dynamic> json) {
    final bbox = (json['bbox'] ??
            json['boundingBox'] ??
            json['bounding_box'] ??
            [])
        as List<dynamic>;
    return DetectionRecord(
      label: json['label'] ?? json['class'] ?? 'unknown',
      confidence: (json['confidence'] ?? json['score'] ?? 0).toDouble(),
      boundingBox:
          bbox.map((value) => (value as num).toDouble()).toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'confidence': confidence,
      'bbox': boundingBox,
    };
  }
}

