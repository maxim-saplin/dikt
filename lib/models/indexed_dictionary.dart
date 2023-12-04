// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:ikvpack/ikvpack.dart';
import 'package:isolate_pool_2/isolate_pool_2.dart';
part 'indexed_dictionary.g.dart';

@HiveType(typeId: 0)
class IndexedDictionary extends HiveObject {
  /// For multi-file dictionary the path will contain number of dictionaries encoded
  /// in the ending og the file name, e.g. "EN RU Dictionary.part5.dikt"
  @HiveField(0)
  String ikvPath = '';
  @HiveField(1)
  bool isEnabled = false;
  @HiveField(2)
  String name = '';
  //set to false before starting indexing and to true when done. E.g. if you reload page or close app while indexing it won't be ready and thus won't show up anywhere
  @HiveField(3)
  bool isReadyToUse = false;
  // error while indexing
  @HiveField(4)
  int order = -1;
  @HiveField(5)
  String hash = '';

  bool isError = false;
  bool isLoaded = false;
  bool isLoading = false;
  bool isBundled = false;

  /// If multi file dictionary is used, number of dictionaries used is returned. If single file dictionary 0 is returned
  static int getNumOfParts(String path) {
    var exp = RegExp(r'(\.part\d+.dikt)');
    var matches = exp.allMatches(path);
    if (matches.isNotEmpty) {
      exp = RegExp(r"(\d+)");
      matches = exp.allMatches(matches.first.group(0)!);

      return int.parse(matches.first.group(0)!);
    }
    return 0;
  }

  static List<String> getPartsPaths(String path) {
    var num = getNumOfParts(path);
    var paths = List<String>.filled(num, '');
    var p = path.replaceAll(RegExp(r'(\.part\d+.dikt)'), '');

    for (var i = 0; i < paths.length; i++) {
      paths[i] = p + '.part${i + 1}.dikt';
    }

    return paths;
  }

  static List<String> getPartsPathsFromOneFile(String path, int n) {
    var paths = List<String>.filled(n, '');

    if (!path.endsWith('.dikt')) {
      throw 'Invalid path, must end with .dikt: $path';
    }

    path = path.substring(0, path.length - 5);

    for (var i = 0; i < paths.length; i++) {
      paths[i] = path + '.part${i + 1}.dikt';
    }

    return paths;
  }

  bool get isMultiPart =>
      RegExp(r'(\.part\d+.dikt)').allMatches(ikvPath).isNotEmpty;

  List<IkvPack> ikvs = [];

  Future<List<IkvPack>> openIkvs([IsolatePool? pool]) async {
    var completer = Completer<List<IkvPack>>();
    var futures = <Future<IkvPack>>[];

    if (!isLoaded) {
      isLoading = true;
      var partsPaths = getPartsPaths(ikvPath);

      if (kIsWeb) {
        futures.add(IkvPack.load(ikvPath));
      } else {
        if (partsPaths.isEmpty) {
          futures.add(pool == null
              ? IkvPack.loadInIsolate(ikvPath)
              : IkvPackProxy.loadInIsolatePoolAndUseProxy(pool, ikvPath));
        } else {
          for (var p in partsPaths) {
            futures.add(pool == null
                ? IkvPack.loadInIsolate(p)
                : IkvPackProxy.loadInIsolatePoolAndUseProxy(pool, p));
          }
        }
      }

      Future.wait(futures).then((value) {
        ikvs = value;
        isLoaded = true;
        isLoading = false;
        completer.complete(ikvs);
      }).catchError((e) {
        debugPrint('Error loaiding IkvPack.\n' + e.toString());
        isLoading = false;
        completer.completeError(e);
      });
      return completer.future;
    }

    return completer.future;
  }

  // can throw
  Future<IkvInfo> getInfo() async {
    var paths = getPartsPaths(ikvPath);

    if (paths.isNotEmpty) {
      var bytes = 0;
      var count = 0;

      for (var p in paths) {
        var i = await IkvPack.getInfo(p);
        bytes += i.sizeBytes;
        count += i.count;
      }

      return IkvInfo(bytes, count);
    }
    return IkvPack.getInfo(ikvPath);
  }

  IndexedDictionary();

  IndexedDictionary.init(
      this.ikvPath, this.name, this.isEnabled, this.isReadyToUse);
}
