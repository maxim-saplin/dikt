import 'dart:typed_data';
import './onlineDictionaries.dart';

class FakeRepoDownloader extends RepoDownloader {
  final bool throwError;

  FakeRepoDownloader(int length, this.throwError) : super(length) {
    var l = length;

    if (length == -1)
      l = 128000; // imitate downloaded of stream with unknown length

    this.bytes = getBytes(l);
  }

  Stream<Uint8List> getBytes(int lengthBytes) async* {
    var chunkSize = (lengthBytes / 100).round();
    var totalSize = 0;

    for (int i = 0; i < 100; i++) {
      if (i == 50 && throwError) throw 'Error downloading dictionary';
      totalSize += chunkSize;
      var n = chunkSize;
      if (totalSize > lengthBytes) n = lengthBytes + chunkSize - totalSize;
      await Future.delayed(const Duration(milliseconds: 10));
      yield Uint8List(n);
    }
  }
}

class FakeOnlineRepo extends OnlineRepo {
  static List<RepoDictionary> dictionaries = [
    RepoDictionary('https://repo.by/1', 'EN_RU Universal Lngv', 100100,
        101 * 1024 * 1024, '1'),
    RepoDictionary('https://repo.by/2', 'RU_EN Universal Lngv', 100200,
        102 * 1024 * 1024, '2'),
    RepoDictionary('https://repo.by/3', 'RU_RU Толковый словарь Даля', 100300,
        103 * 1024 * 1024, '3'),
    RepoDictionary('https://repo.by/4', 'EN_EN WordNet 3.0', 100400,
        104 * 1024 * 1024, '4'),
    RepoDictionary('https://repo.by/5', 'RU_BY Словарь НАН РБ (ред. Крапивы)',
        100500, 105 * 1024 * 1024, '5'),
    RepoDictionary('https://repo.by/6', 'BY_RU Cлоўнік (А. Варвуль)', 100600,
        106 * 1024 * 1024, '6'),
    RepoDictionary('https://repo.by/7', 'BY_BY Тлумачальны слоўнік', 100700,
        107 * 1024 * 1024, '7'),
    RepoDictionary('https://repo.by/8', 'BY_EN Cлоўнік Якуба Коласа', 100800,
        108 * 1024 * 1024, '8'),
    RepoDictionary('https://repo.by/9', 'EN_BY Universal Kolas', 100900,
        109 * 1024 * 1024, '9'),
    RepoDictionary(
        'https://repo.by/10', 'BY_UA Cлоўнік', 101000, 110 * 1024 * 1024, '10'),
  ];

  static const String defaultUrl =
      'https://ipfs.io/ipfs/QmWByPsvVmTH7fMoSWFxECTWgnYJRcCZmdFzhLNhejqHzm';

  static const String secondUrl =
      'https://ipfs.io/ipfs/QmWByPsvVmTH7fMoSWFxECTWgnYJRcCZmdFzhLNhejqHz2';

  static const Duration _timeoutMs = Duration(milliseconds: 2430);

  @override
  Future<List<RepoDictionary>> getDictionariesList(String url) {
    if (url == null) throw 'URL not set';
    if (url == defaultUrl)
      return Future<List<RepoDictionary>>.delayed(
          _timeoutMs, () => dictionaries.toList());

    if (url == secondUrl)
      return Future<List<RepoDictionary>>.delayed(
          _timeoutMs, () => dictionaries.reversed.take(5).toList());

    return Future<List<RepoDictionary>>.delayed(
        _timeoutMs, () => throw 'Repository not available');
  }

  // 3rd - stream error
  // 5th - method error
  // every first download - error, every second - OK

  bool thirdError = false;
  bool fifthError = true;

  @override
  RepoDownloader downloadDictionary(String url) {
    RepoDictionary dic;

    try {
      dic = dictionaries.where((e) => e.url == url).first;
    } catch (_) {
      throw 'Dictionary not found';
    }

    var i = dictionaries.indexOf(dic);

    if (i == 4 && fifthError) {
      fifthError = !fifthError;
      throw '500  Server error';
    } else if (i == 4 && !fifthError) {
      fifthError = !fifthError;
    }

    if (i == 2 && thirdError) {
      thirdError = !thirdError;
    } else if (i == 2 && !thirdError) {
      thirdError = !thirdError;
    }

    return FakeRepoDownloader(
        i % 2 == 1
            ? dic.sizeBytes
            : -1, //every odd dictionary has unknown number of bytes in stream
        thirdError);
  }
}
