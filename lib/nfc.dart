import 'dart:io';
import 'dart:convert';

import 'package:async/async.dart';

class NFCDriver {
  Process driver;
  StreamQueue lines;
  Map<String, dynamic> last;
  String get status => last['STATUS'];

  start() async {
    driver = await Process.start('ntag-driver', []);
    var lineStream =
        driver.stdout.transform(utf8.decoder).transform(new LineSplitter());
    lines = await StreamQueue<String>(lineStream);
    // print("PID: ${driver.pid}");
    // Make sure it started
    await poll();
    assert(status == 'STARTING');
    // Wait until it's ready to scan
    await poll();
    assert(status == 'READY');
  }

  Future<Map<String, dynamic>> poll() async {
    var l = await lines.next;
    last = json.decode(l);
    return last;
  }

  send(String cmd) async {
    driver.stdin.writeln(cmd);
    await driver.stdin.flush();
  }

  Future<Map<String, dynamic>> scan() async {
    // Trigger a new scan
    await send("");
    // Wait for result
    return poll();
  }
}
