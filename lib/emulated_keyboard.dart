import 'dart:io';

import 'dart:typed_data';

class EmulatedKeyboard {
  String device = '/dev/hidg0';
  IOSink sink;
  Map<String, int> map = {
    'a': 4,
    'b': 5,
    'c': 6,
    'd': 7,
    'e': 8,
    'f': 9,
    'g': 10,
    'h': 11,
    'i': 12,
    'j': 13,
    'k': 14,
    'l': 15,
    'm': 16,
    'n': 17,
    'o': 18,
    'p': 19,
    'q': 20,
    'r': 21,
    's': 22,
    't': 23,
    'u': 24,
    'v': 25,
    'w': 26,
    'x': 27,
    'y': 28,
    'z': 29,
    '1': 30,
    '2': 31,
    '3': 32,
    '4': 33,
    '5': 34,
    '6': 35,
    '7': 36,
    '8': 37,
    '9': 38,
    '0': 39
  };

  open() async {
    var file = File(device);
    sink = file.openWrite(); // mode: FileMode.append);
    writeRelease();
    await sink.flush();
  }

  close() async {
    await sink.close();
  }

  /// a-z:   4-29
  /// 1-9,0: 30-39
  type(String string) async {
    // Send each character as an input report
    for (int i = 0; i < string.length; i++) {
      var char = string[i];
      writeKey(char);
      writeRelease();
    }
    writeRelease();
    await sink.flush();
  }

  writeRelease() {
    writeReport([0, 0, 0, 0, 0, 0, 0, 0]);
  }

  writeReport(List<int> payload) {
    sink.add(payload);
  }

  writeKey(String char) {
    int byte = map[char.toLowerCase()];
    print('Byte $char: $byte');
    writeReport([0, 0, byte, 0, 0, 0, 0, 0]);
  }
}
