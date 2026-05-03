import 'dart:typed_data';

class FrameEntry {
  final Uint8List data;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  FrameEntry(this.data, this.metadata) : timestamp = DateTime.now();
}

class FrameBuffer {
  static const int maxBufferSize = 3;
  final _buffer = <FrameEntry>[];
  int _dropped = 0;

  int get droppedFrames => _dropped;
  int get size => _buffer.length;
  bool get isFull => _buffer.length >= maxBufferSize;

  bool push(Uint8List frameData, {Map<String, dynamic>? metadata}) {
    if (_buffer.length >= maxBufferSize) {
      _dropped++;
      return false;
    }
    _buffer.add(FrameEntry(frameData, metadata ?? {}));
    return true;
  }

  FrameEntry? pop() {
    if (_buffer.isEmpty) return null;
    return _buffer.removeAt(0);
  }

  void clear() {
    _buffer.clear();
  }
}
