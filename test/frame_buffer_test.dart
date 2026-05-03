import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_phone_vision/core/frame_buffer.dart';

void main() {
  group('FrameBuffer', () {
    test('accepts frames when not full', () {
      final buffer = FrameBuffer();
      final frame = Uint8List.fromList([1, 2, 3]);
      expect(buffer.push(frame), isTrue);
      expect(buffer.size, 1);
    });

    test('drops frames when at max capacity', () {
      final buffer = FrameBuffer();
      final frame = Uint8List.fromList([1, 2, 3]);
      for (int i = 0; i < FrameBuffer.maxBufferSize; i++) {
        buffer.push(frame);
      }
      expect(buffer.isFull, isTrue);
      expect(buffer.push(frame), isFalse);
      expect(buffer.droppedFrames, 1);
    });

    test('pop returns oldest frame', () {
      final buffer = FrameBuffer();
      final frame1 = Uint8List.fromList([1]);
      final frame2 = Uint8List.fromList([2]);
      buffer.push(frame1);
      buffer.push(frame2);
      final popped = buffer.pop();
      expect(popped?.data, frame1);
    });

    test('pop returns null when empty', () {
      final buffer = FrameBuffer();
      expect(buffer.pop(), isNull);
    });

    test('clear empties the buffer', () {
      final buffer = FrameBuffer();
      buffer.push(Uint8List.fromList([1]));
      buffer.push(Uint8List.fromList([2]));
      buffer.clear();
      expect(buffer.size, 0);
      expect(buffer.pop(), isNull);
    });

    test('dropped frame count accumulates', () {
      final buffer = FrameBuffer();
      final frame = Uint8List.fromList([0]);
      for (int i = 0; i < FrameBuffer.maxBufferSize + 3; i++) {
        buffer.push(frame);
      }
      expect(buffer.droppedFrames, 3);
    });
  });
}
