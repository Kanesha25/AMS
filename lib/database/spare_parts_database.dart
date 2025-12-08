import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spare_part_model.dart';

class SparePartsDatabase {
  static final SparePartsDatabase _instance = SparePartsDatabase._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('spare_parts');

  SparePartsDatabase._internal();

  factory SparePartsDatabase() => _instance;

  static const List<Map<String, dynamic>> _defaultParts = [
    {'id': 1, 'name': 'Left Headlight', 'min_price': 50000, 'max_price': 125000},
    {'id': 2, 'name': 'Right Headlight', 'min_price': 50000, 'max_price': 125000},
    {'id': 3, 'name': 'Left Side Mirror', 'min_price': 20000, 'max_price': 75000},
    {'id': 4, 'name': 'Right Side Mirror', 'min_price': 20000, 'max_price': 75000},
    {'id': 5, 'name': 'Tail Light', 'min_price': 50000, 'max_price': 100000},
    {'id': 6, 'name': 'Bonnet', 'min_price': 10000, 'max_price': 15000},
    {'id': 7, 'name': 'Front Bumper', 'min_price': 70000, 'max_price': 150000},
    {'id': 8, 'name': 'Rear Bumper', 'min_price': 70000, 'max_price': 150000},
    {'id': 9, 'name': 'Front Windshield', 'min_price': 100000, 'max_price': 175000},
    {'id': 10, 'name': 'Rear Windshield', 'min_price': 100000, 'max_price': 175000},
    {'id': 11, 'name': 'Trunk', 'min_price': 50000, 'max_price': 75000},
    {'id': 12, 'name': 'Front Door', 'min_price': 100000, 'max_price': 105000},
    {'id': 13, 'name': 'Rear Door', 'min_price': 98000, 'max_price': 100000},
  ];

  Future<void> _seedDefaultsIfNeeded() async {
    final snapshot = await _collection.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    for (var part in _defaultParts) {
      final docId = 'part_${part['id']}';
      batch.set(_collection.doc(docId), {
        ...part,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<List<SparePart>> getAllSpareParts() async {
    await _seedDefaultsIfNeeded();
    final snapshot = await _collection.orderBy('name').get();
    return snapshot.docs.map(SparePart.fromFirestore).toList();
  }

  Future<String> insertSparePart(SparePart sparePart) async {
    final doc = await _collection.add(sparePart.toFirestoreMap());
    return doc.id;
  }

  Future<void> updateSparePart(SparePart sparePart) async {
    final docId = sparePart.documentId;
    if (docId == null) {
      throw ArgumentError('Spare part must contain a documentId to update.');
    }
    await _collection.doc(docId).update(sparePart.toFirestoreMap());
  }

  Future<void> deleteSparePart(SparePart sparePart) async {
    final docId = sparePart.documentId;
    if (docId == null) {
      throw ArgumentError('Spare part must contain a documentId to delete.');
    }
    await _collection.doc(docId).delete();
  }

  Future<void> updateMultipleSpareParts(List<SparePart> spareParts) async {
    final batch = _firestore.batch();
    for (var sparePart in spareParts) {
      final docId = sparePart.documentId ?? 'part_${sparePart.id}';
      batch.set(
        _collection.doc(docId),
        sparePart.toFirestoreMap(),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }
}