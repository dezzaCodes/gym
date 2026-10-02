import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Mirrors a single user's workout data (encoded as JSON, the same shape
/// used for local storage) to Firestore so it can sync across devices.
///
/// Deals only in raw JSON maps rather than app-specific models, so this
/// stays a plain sync primitive and the workout feature owns encoding.
class CloudWorkoutRepository {
  CloudWorkoutRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'ftnx');

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('workout_profiles').doc(uid);

  Future<Map<String, dynamic>?> fetch(String uid) async {
    final snapshot = await _doc(uid).get();
    return snapshot.data();
  }

  Future<void> save(String uid, Map<String, dynamic> json) {
    return _doc(uid).set(json);
  }

  Stream<Map<String, dynamic>?> watch(String uid) {
    return _doc(uid).snapshots().map((snapshot) => snapshot.data());
  }
}
