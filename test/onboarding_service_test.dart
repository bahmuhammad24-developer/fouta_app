import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/growth/onboarding_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _FakeFirestore implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> data = {};
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _FakeCollection(this, path);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCollection implements CollectionReference<Map<String, dynamic>> {
  _FakeCollection(this.store, this.path);
  final _FakeFirestore store;
  final String path;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? id]) {
    return _FakeDoc(store, '$path/${id ?? "id"}');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDoc implements DocumentReference<Map<String, dynamic>> {
  _FakeDoc(this.store, this.path);
  final _FakeFirestore store;
  final String path;
  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    store.data[path] = data;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('saveInterests writes to firestore', () async {
    final fake = _FakeFirestore();
    final service = OnboardingService(firestore: fake);
    await service.saveInterests('u1', ['tech']);
    expect(fake.data.containsKey('users/u1'), true);
  });
}
