import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nekonata_firestore/nekonata_firestore.dart';

// テスト用のデータモデル
class _TestModel {
  _TestModel({required this.id, required this.name});

  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TestModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

void main() {
  // fromFirestoreとtoFirestoreのコンバーターを定義
  _TestModel fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return _TestModel(id: snapshot.id, name: data['name'] as String);
  }

  Map<String, Object?> toFirestore(_TestModel model, SetOptions? options) {
    return {'name': model.name};
  }

  group('FirestoreRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreRepository<_TestModel> repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirestoreRepository(
        firestore: fakeFirestore,
        collectionName: 'test',
        fromFirestore: fromFirestore,
        toFirestore: toFirestore,
      );
    });

    test('set and get', () async {
      const id = 'testId';
      final model = _TestModel(id: id, name: 'testName');

      await repository.set(id, model);
      final result = await repository.get(id);

      expect(result, model);
    });

    test('add and get', () async {
      final model = _TestModel(id: '', name: 'testName');
      await repository.add(model);

      final results = await repository.getAll(limit: 1);
      expect(results.length, 1);
      expect(results.first.name, model.name);
    });

    test('delete', () async {
      const id = 'testId';
      final model = _TestModel(id: id, name: 'testName');

      await repository.set(id, model);
      var result = await repository.get(id);
      expect(result, isNotNull);

      await repository.delete(id);
      result = await repository.get(id);
      expect(result, isNull);
    });

    test('updateFields', () async {
      const id = 'testId';
      final model = _TestModel(id: id, name: 'initialName');

      await repository.set(id, model);
      await repository.updateFields(id, {'name': 'updatedName'});

      final result = await repository.get(id);
      expect(result?.name, 'updatedName');
    });

    test('getAll', () async {
      final model1 = _TestModel(id: 'id1', name: 'name1');
      final model2 = _TestModel(id: 'id2', name: 'name2');

      await repository.set('id1', model1);
      await repository.set('id2', model2);

      final results = await repository.getAll(limit: 2);
      expect(results.length, 2);
      expect(results, contains(model1));
      expect(results, contains(model2));
    });

    test('stream', () async {
      const id = 'testId';
      final model = _TestModel(id: id, name: 'testName');

      // 最初にデータをセット
      await repository.set(id, model);

      // 最初のデータが正しいことを確認
      final stream1 = repository.stream(id);
      expect(await stream1.first, model);

      // データを更新
      await repository.updateFields(id, {'name': 'updatedName'});

      // 更新されたデータがストリームに流れてくることを確認
      final stream2 = repository.stream(id);
      final updatedModel = await stream2.first;
      expect(updatedModel?.name, 'updatedName');

      // データを削除
      await repository.delete(id);

      // nullが流れてくることを確認
      final stream3 = repository.stream(id);
      expect(await stream3.first, isNull);
    });
  });
}
