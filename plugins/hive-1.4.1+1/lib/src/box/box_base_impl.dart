import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:meta/meta.dart';

/// Not part of public API
abstract class BoxBaseImpl<E> implements BoxBase<E> {
  @override
  final String name;

  /// Not part of public API
  @visibleForTesting
  final HiveImpl hive;

  final CompactionStrategy _compactionStrategy;

  /// Not part of public API
  @protected
  final StorageBackend backend;

  /// Not part of public API
  @protected
  @visibleForTesting
  Keystore<E> keystore;

  bool _open = true;

  /// Not part of public API
  BoxBaseImpl(
    this.hive,
    this.name,
    KeyComparator keyComparator,
    this._compactionStrategy,
    this.backend,
  ) {
    keystore = Keystore(this, ChangeNotifier(), keyComparator);
  }

  /// Not part of public API
  Type get valueType => E;

  @override
  bool get isOpen => _open;

  @override
  String get path => backend.path;

  @override
  Iterable<dynamic> get keys {
    checkOpen();
    return keystore.getKeys();
  }

  @override
  int get length {
    checkOpen();
    return keystore.length;
  }

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => length > 0;

  /// Not part of public API
  @protected
  void checkOpen() {
    if (!_open) {
      throw HiveError('Box has already been closed.');
    }
  }

  @override
  Stream<BoxEvent> watch({dynamic key}) {
    checkOpen();
    return keystore.watch(key: key);
  }

  @override
  dynamic keyAt(int index) {
    checkOpen();
    return keystore.getAt(index).key;
  }

  /// Not part of public API
  Future<void> initialize() {
    return backend.initialize(hive, keystore, lazy);
  }

  @override
  bool containsKey(dynamic key) {
    checkOpen();
    return keystore.containsKey(key);
  }

  @override
  Future<void> put(dynamic key, E value) => putAll({key: value});

  @override
  Future<void> delete(dynamic key) => deleteAll([key]);

  @override
  Future<int> add(E value) async {
    var key = keystore.autoIncrement();
    await put(key, value);
    return key;
  }

  @override
  Future<Iterable<int>> addAll(Iterable<E> values) async {
    var entries = <int, E>{};
    for (var value in values) {
      entries[keystore.autoIncrement()] = value;
    }
    await putAll(entries);
    return entries.keys;
  }

  @override
  Future<void> putAt(int index, E value) {
    return putAll({keystore.getAt(index).key: value});
  }

  @override
  Future<void> deleteAt(int index) {
    return deleteAll([keystore.getAt(index).key]);
  }

  @override
  Future<int> clear() async {
    checkOpen();

    await backend.clear();
    return keystore.clear();
  }

  @override
  Future<void> compact() async {
    checkOpen();

    if (!backend.supportsCompaction) return;
    if (keystore.deletedEntries == 0) return;

    await backend.compact(keystore.frames);
    keystore.resetDeletedEntries();
  }

  /// Not part of public API
  @protected
  Future<void> performCompactionIfNeeded() {
    if (_compactionStrategy(keystore.length, keystore.deletedEntries)) {
      return compact();
    }

    return Future.value();
  }

  @override
  Future<void> close() async {
    if (!_open) return;

    _open = false;
    await keystore.close();
    hive.unregisterBox(name);

    await backend.close();
  }

  @override
  Future<void> deleteFromDisk() async {
    if (_open) {
      _open = false;
      await keystore.close();
      hive.unregisterBox(name);
    }

    await backend.deleteFromDisk();
  }
}
