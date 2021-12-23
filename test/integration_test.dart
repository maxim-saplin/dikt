import 'dart:async';
import 'dart:io';

import 'package:dikt/common/isolate_pool.dart';
import 'package:dikt/models/dictionary_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:test/test.dart';

late DictionaryManager dicManager;
var tmpPath = 'test/tmp_int';

void main() {
  group('DictionaryManager', () {
    setUpAll(() async {
      print('Setting up tests, tmp path $tmpPath');

      var tmpDir = Directory(tmpPath);
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
      Directory(tmpPath).createSync();

      await DictionaryManager.init(tmpPath);
      dicManager = DictionaryManager();
    });

    tearDownAll(() {
      try {
        Directory(tmpPath).delete(recursive: true);
      } catch (_) {}
    });

    test('DictionaryManager - corrupted JSON dictionary is properlly handled',
        () async {
      // All this zone fuss is to allow bypass async unhandled error somehwere in
      // darts internals of stream listener which doesn't influence anything
      var files = [
        'test/data/3 MES.csv',
        'test/data/broken_BY_RU Ворвуль.json'
      ];

      for (var file in files) {
        var f = runZonedGuarded(() async {
          try {
            await dicManager.loadFromJsonOrDiktFiles(
                [PlatformFile(path: file, name: file, size: 1)]);
          } catch (err) {
            //print(err);
          }
          //print('Done');
        }, (err, st) {
          print('zone caught error\n$err');
        });

        expect(dicManager.dictionariesBeingProcessed.length, 1);
        expect(dicManager.dictionariesBeingProcessed[0].state,
            DictionaryBeingProcessedState.inprogress);
        await f;
        expect(dicManager.dictionariesBeingProcessed[0].state,
            DictionaryBeingProcessedState.error);
      }
    }, timeout: Timeout(Duration(milliseconds: 800)));

    test(
        'DictionaryManager - fine JSON and IKV dictionaries are properlly handled',
        () async {
      var f = dicManager.loadFromJsonOrDiktFiles([
        PlatformFile(
            path: 'test/data/BY_RU Ворвуль.json',
            name: 'test/data/BY_RU Ворвуль.json',
            size: 1),
        PlatformFile(
            path: 'test/data/dik_enenwordnet3.dikt',
            name: 'test/data/dik_enenwordnet3.dikt',
            bytes: File('test/data/dik_enenwordnet3.dikt')
                .readAsBytesSync(), // workaround, non pool'ed indexer expects paltform file to have bytes
            size: 1)
      ]);

      expect(dicManager.dictionariesBeingProcessed.length, 2);
      expect(dicManager.dictionariesBeingProcessed[0].state,
          DictionaryBeingProcessedState.inprogress);
      expect(dicManager.dictionariesBeingProcessed[1].state,
          DictionaryBeingProcessedState.pending);
      await f;
      expect(dicManager.dictionariesBeingProcessed[0].state,
          DictionaryBeingProcessedState.success);
      expect(dicManager.dictionariesBeingProcessed[1].state,
          DictionaryBeingProcessedState.success);
    });

    test(
        'DictionaryManager - isolate pool, fine JSON and IKV dictionaries are properlly handled',
        () async {
      var f = dicManager.loadFromJsonOrDiktFiles([
        PlatformFile(
            path: 'test/data/BY_RU Ворвуль.json',
            name: 'test/data/BY_RU Ворвуль.json',
            size: 1),
        PlatformFile(
            path: 'test/data/dik_enenwordnet3.dikt',
            name: 'test/data/dik_enenwordnet3.dikt',
            size: 1)
      ]);

      initIsolatePool();
      await pool!.started;

      expect(dicManager.dictionariesBeingProcessed.length, 2);
      expect(dicManager.dictionariesBeingProcessed[0].state,
          DictionaryBeingProcessedState.inprogress);
      expect(dicManager.dictionariesBeingProcessed[1].state,
          DictionaryBeingProcessedState.pending);
      await f;
      expect(dicManager.dictionariesBeingProcessed[0].state,
          DictionaryBeingProcessedState.success);
      expect(dicManager.dictionariesBeingProcessed[1].state,
          DictionaryBeingProcessedState.success);
    });
  });
}
