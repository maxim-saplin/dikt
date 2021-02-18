import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';

const int _blockSize = 64 * 1024;

class FileStream extends Stream<List<int>> {
  // Stream controller.
  StreamController<Uint8List> _controller = StreamController<Uint8List>();

  // Information about the underlying file.
  final String _path;
  RandomAccessFile _openedFile;
  int _position;
  final int _end;
  final Completer _closeCompleter = Completer();

  // Has the stream been paused or unsubscribed?
  bool _unsubscribed = false;

  // Is there a read currently in progress?
  bool _readInProgress = true;
  bool _closed = false;

  bool _atEnd = false;

  FileStream(this._path, int position, this._end) : _position = position ?? 0 {
    //_openedFile = RandomAccessFile()
  }

  StreamSubscription<Uint8List> listen(void onData(Uint8List event),
      {Function onError, void onDone(), bool cancelOnError}) {
    _controller = new StreamController<Uint8List>(
        sync: true,
        onListen: _start,
        onResume: _readBlock,
        onCancel: () {
          _unsubscribed = true;
          return _closeFile();
        });
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  Future _closeFile() {
    if (_readInProgress || _closed) {
      return _closeCompleter.future;
    }
    _closed = true;

    void done() {
      _closeCompleter.complete();
      _controller.close();
    }

    _openedFile.close().catchError(_controller.addError).whenComplete(done);
    return _closeCompleter.future;
  }

  void _readBlock() {
    // Don't start a new read if one is already in progress.
    if (_readInProgress) return;
    if (_atEnd) {
      _closeFile();
      return;
    }
    _readInProgress = true;
    int readBytes = _blockSize;
    final end = _end;
    if (end != null) {
      readBytes = min(readBytes, end - _position);
      if (readBytes < 0) {
        _readInProgress = false;
        if (!_unsubscribed) {
          _controller.addError(new RangeError("Bad end position: $end"));
          _closeFile();
          _unsubscribed = true;
        }
        return;
      }
    }
    _openedFile.read(readBytes).then((block) {
      _readInProgress = false;
      if (_unsubscribed) {
        _closeFile();
        return;
      }
      _position += block.length;
      if (block.length < readBytes || (_end != null && _position == _end)) {
        _atEnd = true;
      }
      if (!_atEnd && !_controller.isPaused) {
        _readBlock();
      }
      _controller.add(block);
      if (_atEnd) {
        _closeFile();
      }
    }).catchError((e, s) {
      if (!_unsubscribed) {
        _controller.addError(e, s);
        _closeFile();
        _unsubscribed = true;
      }
    });
  }

  void _start() {
    if (_position < 0) {
      _controller.addError(new RangeError("Bad start position: $_position"));
      _controller.close();
      _closeCompleter.complete();
      return;
    }

    void onReady(RandomAccessFile file) {
      _openedFile = file;
      _readInProgress = false;
      _readBlock();
    }

    void onOpenFile(RandomAccessFile file) {
      if (_position > 0) {
        file.setPosition(_position).then(onReady, onError: (e, s) {
          _controller.addError(e, s);
          _readInProgress = false;
          _closeFile();
        });
      } else {
        onReady(file);
      }
    }

    void openFailed(error, stackTrace) {
      _controller.addError(error, stackTrace);
      _controller.close();
      _closeCompleter.complete();
    }

    final path = _path;
    if (path != null) {
      File(path)
          .open(mode: FileMode.read)
          .then(onOpenFile, onError: openFailed);
    }
  }

  int get position {
    return _position;
  }
}
