part of hive_not_tuned;

/// Annotate all fields you want to persist with [HiveField].
class HiveField {
  /// The index of this field.
  final int index;

  ///
  const HiveField(this.index);
}
