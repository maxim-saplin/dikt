import 'indexable_skip_list.dart';

/// Nedded to compilr in Web, not used there
class AppendOnlyList<K, V> extends IndexableSkipList<K, V> {
  ///
  AppendOnlyList(comparator) : super(comparator);
}
