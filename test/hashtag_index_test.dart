import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/discovery/discovery_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/main.dart';

class _FakeFirestore implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> data = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _FakeCollection(data, path);
  }

  @override
  Future<T> runTransaction<T>(Future<T> Function(Transaction) handler,
      {Duration timeout = const Duration(seconds: 5), int maxAttempts = 5}) async {
    final tx = _FakeTransaction(data);
    return handler(tx);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCollection implements CollectionReference<Map<String, dynamic>> {
  _FakeCollection(this.store, this.path);
  final Map<String, Map<String, dynamic>> store;
  final String path;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? id]) {
    return _FakeDoc(store, '$path/${id ?? 'id'}');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDoc implements DocumentReference<Map<String, dynamic>> {
  _FakeDoc(this.store, this.path);
  final Map<String, Map<String, dynamic>> store;
  final String path;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return _FakeSnapshot(store[path]);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    if (options?.merge == true && store[path] != null) {
      store[path] = {...store[path]!, ...data};
    } else {
      store[path] = data;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeSnapshot(this._data);
  final Map<String, dynamic>? _data;
  @override
  Map<String, dynamic>? data() => _data;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTransaction implements Transaction {
  _FakeTransaction(this.store);
  final Map<String, Map<String, dynamic>> store;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get(
      DocumentReference<Map<String, dynamic>> doc) {
    return (doc as _FakeDoc).get();
  }

  @override
  Transaction set(DocumentReference<Map<String, dynamic>> doc,
      Map<String, dynamic> data,
      [SetOptions? options]) {
    (doc as _FakeDoc).set(data, options);
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('extractHashtags parses unique tags', () {
    final tags = DiscoveryService.extractHashtags('Hello #World #flutter #WORLD');
    expect(tags, containsAll(['world', 'flutter']));
    expect(tags.length, 2);
  });

  test('updateHashtagAggregates increments and decrements counts', () async {
    final fake = _FakeFirestore();
    await DiscoveryService.updateHashtagAggregates(fake, ['foo', 'bar']);
    final base = 'artifacts/$APP_ID/public/data/hashtags';
    expect(fake.data['$base/foo']?['count'], 1);
    await DiscoveryService.updateHashtagAggregates(fake, ['bar'],
        oldTags: ['foo', 'bar']);
    expect(fake.data['$base/foo']?['count'], 0);
    expect(fake.data['$base/bar']?['count'], 2);
  });
}
