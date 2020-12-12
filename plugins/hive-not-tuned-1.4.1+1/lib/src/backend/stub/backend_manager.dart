import 'package:hive_not_tuned/hive_not_tuned.dart';
import 'package:hive_not_tuned/src/backend/storage_backend.dart';

/// Not part of public API
class BackendManager implements BackendManagerInterface {
  @override
  Future<StorageBackend> open(
      String name, String path, bool crashRecovery, HiveCipher2 cipher) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteBox(String name, String path) {
    throw UnimplementedError();
  }
}
