part of hive_not_tuned;

/// [LazyBox]es don't keep the values in memory like normal boxes. Each time a
/// value is read, it is loaded from the backend.
abstract class LazyBox<E> extends BoxBase<E> {
  /// Returns the value associated with the given [key]. If the key does not
  /// exist, `null` is returned.
  ///
  /// If [defaultValue] is specified, it is returned in case the key does not
  /// exist.
  Future<E> get(dynamic key, {E defaultValue});

  /// Returns the value associated with the n-th key.
  Future<E> getAt(int index);

  /// Exposing indexed DB to JS interop for bulk insert workaround
  dynamic get indexedDb;
}