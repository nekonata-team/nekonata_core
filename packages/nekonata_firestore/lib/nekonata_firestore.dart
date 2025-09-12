import 'package:cloud_firestore/cloud_firestore.dart';

final class FirestoreRepository<T> {
  const FirestoreRepository({
    required this.collectionName,
    required this.fromFirestore,
    required this.toFirestore,
    this.firestore,
  });

  final String collectionName;
  final FromFirestore<T> fromFirestore;
  final ToFirestore<T> toFirestore;

  final FirebaseFirestore? firestore;

  FirebaseFirestore get _firestore => firestore ?? FirebaseFirestore.instance;

  CollectionReference<T> get collection => _firestore
      .collection(collectionName)
      .withConverter(fromFirestore: fromFirestore, toFirestore: toFirestore);

  Future<T?> get(String id) async {
    final doc = await collection.doc(id).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> set(String id, T value) async {
    await collection.doc(id).set(value);
  }

  Future<void> add(T value) async {
    await collection.add(value);
  }

  Future<void> delete(String id) async {
    await collection.doc(id).delete();
  }

  Future<void> updateFields(String id, Map<String, dynamic> fields) async {
    await collection.doc(id).update(fields);
  }

  Future<List<T>> getAll({required int limit}) async {
    final snapshot = await collection.limit(limit).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Stream<T?> stream(String value) => collection
      .doc(value)
      .snapshots()
      .map((doc) => doc.exists ? doc.data() : null);
}
