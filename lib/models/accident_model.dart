class AccidentModel {
  final String id;
  final String location;
  final String description;
  final DateTime timestamp;
  final String status;

  AccidentModel({
    required this.id,
    required this.location,
    required this.description,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }

  factory AccidentModel.fromJson(Map<String, dynamic> json) {
    return AccidentModel(
      id: json['id'],
      location: json['location'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      status: json['status'],
    );
  }
}