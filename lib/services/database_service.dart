import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/accident_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addAccident(AccidentModel accident) async {
    try {
      await _firestore.collection('accidents').doc(accident.id).set(accident.toJson());
    } catch (e) {
      print('Error adding accident: $e');
    }
  }

  Stream<List<AccidentModel>> getAccidents() {
    return _firestore
        .collection('accidents')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AccidentModel.fromJson(doc.data()))
          .toList();
    });
  }

  Future<void> updateAccidentStatus(String accidentId, String status) async {
    try {
      await _firestore.collection('accidents').doc(accidentId).update({
        'status': status,
      });
    } catch (e) {
      print('Error updating accident: $e');
    }
  }
}