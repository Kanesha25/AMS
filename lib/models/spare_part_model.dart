import 'package:cloud_firestore/cloud_firestore.dart';

class SparePart {
  final String? documentId;
  final int? id;
  final String name;
  final int minPrice;
  final int maxPrice;

  const SparePart({
    this.documentId,
    this.id,
    required this.name,
    required this.minPrice,
    required this.maxPrice,
  });

  SparePart copyWith({
    String? documentId,
    int? id,
    String? name,
    int? minPrice,
    int? maxPrice,
  }) {
    return SparePart(
      documentId: documentId ?? this.documentId,
      id: id ?? this.id,
      name: name ?? this.name,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'min_price': minPrice,
      'max_price': maxPrice,
    };
  }

  Map<String, dynamic> toFirestoreMap() => toMap();

  factory SparePart.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return SparePart(
      documentId: documentId,
      id: map['id'],
      name: map['name'],
      minPrice: map['min_price'],
      maxPrice: map['max_price'],
    );
  }

  factory SparePart.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return SparePart.fromMap(data, documentId: doc.id);
  }

  Map<String, dynamic> toEstimationMap() {
    return {
      'documentId': documentId,
      'id': id,
      'name': name,
      'min_price': minPrice,
      'max_price': maxPrice,
    };
  }
}