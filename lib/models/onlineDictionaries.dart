import 'package:flutter/foundation.dart';

class OnlineDictionaries extends ChangeNotifier {
  String _repoUrl;

  String get repoUrl {
    return _repoUrl;
  }

  set repoUrl(String value) {}

  List<OnlineDictionary> get dictionaries {
    return null;
  }
}

class OnlineDictionary {
  final String url;
  final String name;
  final int words;
  final int sizeBytes;

  OnlineDictionary(this.url, this.name, this.words, this.sizeBytes);
}
