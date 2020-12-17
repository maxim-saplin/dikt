import './collection2/collection/collection.dart' as dc2;
import 'indexable_skip_list.dart';

/// Simple map for dictionary boxes which are readonly after indexing
/// Dikt has hundreds of thousands of keys, standrd version
/// is slow to load. On Samsung Note 10 with 8 dictionaries loaded in
/// isolates app load took on average 3.3 second. Replacing the
/// IndexableSkipList with custom version based on SplayTreeMap
/// showed 1,6 seconds for app to start and 75% decrease in openLazyBox
/// in isolated test on a 148730 key dictionary (700ms vs 180ms).
///
/// HashMap is slower than SplayTreeMap and doesn't sort keys, default Map
/// also maintains insert order of keys (which is OK is they are inserted
/// in right order) though show very inconsitent app start time on Note 10.
///
/// SplayTreeMap was modified as the SDK version has closure/function in internal
/// field which doesn't allow to pass this object between isolates
class AppendOnlyList<K, V> extends IndexableSkipList<K, V> {
  ///
  AppendOnlyList(Comparator<K> comparator) : super(comparator) {
    //print('AppendOnlyList created');
  }

  dc2.SplayTreeMap<K, V> _list = dc2.SplayTreeMap<K, V>();

  /// Not part of public API
  int get length => _list.length;

  /// Not part of public API
  Iterable<K> get keys {
    return _list.keys;
  }

  /// Not part of public API
  Iterable<V> get values => _list.values;

  V insert(K key, V value, [bool checkExisting = true]) {
    _list[key] = value;
    return null;
  }

  V delete(K key) => null;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  V get(K key) => _list[key];

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Iterable<V> valuesFromKey(K key) => null;

  void clear() {
    _list = dc2.SplayTreeMap<K, V>();
  }
}
