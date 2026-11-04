import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreHelper {
  static final _db = FirebaseFirestore.instance;

  static Future<String> addTicket(Map<String, dynamic> t) async {
    final ref = await _db.collection('tickets').add({
      ...t,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Stream<QuerySnapshot> ticketsStream() {
    return _db
        .collection('tickets')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> updateTicket(
      String docId, Map<String, dynamic> values) async {
    await _db.collection('tickets').doc(docId).update(values);
  }

  static Future<String> addUser(Map<String, dynamic> u) async {
    final ref = await _db.collection('users').add({
      ...u,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<List<Map<String, dynamic>>> getUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs.map((d) => {...d.data(), 'docId': d.id}).toList();
  }

  static Future<void> updateUser(
      String docId, Map<String, dynamic> values) async {
    await _db.collection('users').doc(docId).update(values);
  }
}