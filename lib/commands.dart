import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:validicitylib/api.dart';
import 'package:validicitylib/config.dart';
import 'package:validicitylib/model/key.dart';
import 'package:validicitylib/model/sample.dart';
import 'package:validicitylib/rest.dart';

import 'emulated_keyboard.dart';
import 'nfc.dart';
import 'validicityclient.dart';

const String clientID = "city.validi.validicityclient";

abstract class BaseCommand extends Command implements CredentialsHolder {
  // RestClient client;
  ValidicityServerAPI api;
  Map<String, dynamic> result;
  File _credentialsFile;

  int intArg(String name) {
    return int.tryParse(argResults[name]);
  }

  File get credentialsFile {
    if (_credentialsFile != null) {
      return _credentialsFile;
    } else {
      var home = Platform.environment['HOME'];
      var p = path.join(home, "oauth2-credentials.json");
      return File(p);
    }
  }

  // We try to request all scopes
  List<String> scopes = ['admin', 'client', 'customer'];

  // Load any state from disk etc
  load() {
    loadKey();
  }

  void run() async {
    // Configure
    configureValidicity(globalResults);

    // Load state
    load();

    // Set up API
    var url = Uri.parse(config.api.url);
    api = ValidicityServerAPI(config.api.clientID, holder: this);
    api
      ..username = config.api.username
      ..password = config.api.password
      ..scopes = scopes
      ..server = url.host
      ..responseHandler = handleResponse;

    // Execute action and handle result
    try {
      await exec();
    } catch (e) {
      print(e);
      exit(1);
    }
    handleResult(result);
    exit(0);
  }

  void handleResult(Map result) {
    if (result != null) {
      if (config.pretty) {
        try {
          print(JsonEncoder.withIndent('  ').convert(result));
        } catch (e) {
          print("$result");
        }
      } else {
        print(result);
      }
    }
  }

  http.Response handleResponse(http.Response response) {
    if (response == null) {
      print("No response");
      return null;
    }
    if (config.verbose) {
      print("REQUEST: ${response.request}");
      print("RESPONSE STATUS: ${response.statusCode}");
      print("RESPONSE HEADERS: ${response.headers}");
      print("RESPONSE BODY: ${response.body}");
    }
    return response;
  }

  @override
  Future<String> loadCredentials() async {
    if (await credentialsFile.exists()) {
      return credentialsFile.readAsStringSync();
    } else {
      return null;
    }
  }

  @override
  Future<void> removeCredentials() async {
    if (await credentialsFile.exists()) {
      await credentialsFile.deleteSync();
    }
  }

  @override
  Future<void> saveCredentials(String credentials) async {
    await credentialsFile.writeAsString(credentials);
  }

  // Subclasses implement
  void exec();
}

class TestNFCCommand extends BaseCommand {
  final name = "testnfc";
  final description = "Test a single NFC scan to verify it works.";

  void exec() async {
    var nfc = NFCDriver();
    var keyboard = EmulatedKeyboard();
    await keyboard.open();
    print("Starting NFC scanner ...");
    await nfc.start();
    print("Ready to scan ...");
    var result = await nfc.scan();
    if (result['STATUS'] == 'OK') {
      print(json.encode(result));
      print("Printing ${result['ID']} on keyboard ...");
      await keyboard.type(result['ID']);
      await keyboard.close();
    } else {
      print("No tag scanned");
    }
    print("Done.");
  }
}

class TestEmulatedKeyboard extends BaseCommand {
  final name = "testkeyboard";
  final description = "Test keyboard emulation to verify it works.";

  void exec() async {
    var keyboard = EmulatedKeyboard();
    await keyboard.open();
    print("Keyboard opened ... Typing 'hello' followed by 'world'.");
    await keyboard.type('hello');
    await Future.delayed(Duration(seconds: 1));
    await keyboard.type('world');
    await keyboard.close();
    print("Done.");
  }
}

class TestContinuous extends BaseCommand {
  final name = "testcontinuous";
  final description = "Scan and type to keyboard continuously.";

  void exec() async {
    var nfc = NFCDriver();
    print("Starting NFC scanner ...");
    await nfc.start();
    var keyboard = EmulatedKeyboard();
    print("Opening emulated keyboard ...");
    await keyboard.open();

    print("Ready to scan ...");
    var running = true;
    String lastId;
    DateTime threshold = DateTime.now();
    while (running) {
      var result = await nfc.scan();
      if (result['STATUS'] == 'FAILED SCAN') {
        running = false;
      } else if (result['STATUS'] == 'OK') {
        var id = result['ID'];
        if (id != lastId || DateTime.now().isAfter(threshold)) {
          print("Printing ${result['ID']} on keyboard ...");
          await keyboard.type(id);
          lastId = id;
          threshold = DateTime.now().add(Duration(seconds: 5));
          print("Printed.");
        } else {
          print("Ignored duplicate scan.");
        }
      } else {
        print("$result");
      }
      await Future.delayed(Duration(milliseconds: 300));
    }
    print("Exit due to scan failure.");
  }
}

class DaemonCommand extends BaseCommand {
  final name = "daemon";
  final description =
      "Scan, submit to Validicity and type to keyboard continuously.";

  void exec() async {
    var nfc = NFCDriver();
    print("Starting NFC scanner ...");
    await nfc.start();
    var keyboard = EmulatedKeyboard();
    print("Opening emulated keyboard ...");
    await keyboard.open();

    print("Ready to scan ...");
    var running = true;
    String lastId;
    DateTime threshold = DateTime.now();
    while (running) {
      var result = await nfc.scan();
      if (result['STATUS'] == 'FAILED SCAN') {
        running = false;
      } else if (result['STATUS'] == 'OK') {
        var scannedSerial = result['ID'];
        if (scannedSerial != lastId || DateTime.now().isAfter(threshold)) {
          // First get previous known record (block) for this Sample
          var previous = await api.findSample(scannedSerial);
          // TODO: Error handling
          print(previous);
          // Then build new sample
          var sample = Sample()..serial = scannedSerial;
          sample.seal(validicityKey, previous);
          // And submit it
          result = await api.submitSample(sample);
          print("Printing $scannedSerial on keyboard ...");
          await keyboard.type(scannedSerial);
          lastId = scannedSerial;
          threshold = DateTime.now().add(Duration(seconds: 5));
          print("Printed.");
        } else {
          print("Ignored duplicate scan.");
        }
      } else {
        print("$result");
      }
      await Future.delayed(Duration(milliseconds: 300));
    }
    print("Exit due to scan failure.");
  }
}

class StatusCommand extends BaseCommand {
  String description = "Get status of the Validicity system.";
  String name = "status";

  StatusCommand() {}

  void exec() async {
    result = await api.status();
    result['boardId'] = boardId;
    result['config'] = config;
  }
}

class CreateKeysCommand extends BaseCommand {
  String description = "Create keys for this client in the Validicity system.";
  String name = "createkeys";

  RegisterCommand() {
    /*argParser.addOption('user',
        abbr: 'u', help: "The user to authenticate with");
    argParser.addOption('password',
        abbr: 'p', help: "The password to authenticate with");
        */
  }

  void exec() async {
    if (validicityKey != null) {
      print(
          "Keys already exist, can not create new keys. Remove existing key file first.");
    } else {
      String path = createKey();
      print("Keys created in ${path}");
    }
  }
}

class RegisterCommand extends BaseCommand {
  String description = "Register this client in the Validicity system.";
  String name = "register";

  RegisterCommand() {
    /*argParser.addOption('user',
        abbr: 'u', help: "The user to authenticate with");
    argParser.addOption('password',
        abbr: 'p', help: "The password to authenticate with");
        */
  }

  void exec() async {
    if (validicityKey == null) {
      print("Keys do not exist, you first need to create new keys");
    }
    await api.register(validicityKey.publicKey);
    print(
        "Public key ${validicityKey.publicKey} registered for user ${config.api.username}");
  }
}

class SampleSubmitCommand extends BaseCommand {
  String description = "Manually make a new Sample event.";
  String name = "sample";

  RegisterCommand() {
    argParser.addOption('serial', abbr: 's', help: "The serial of the Sample");
    argParser.addOption('file',
        abbr: 'f', help: "The JSON file with the sample content");
  }

  void exec() async {
    var sampleJson = loadFile(argResults['file']);
    if (validicityKey == null) {
      print(
          "Keys do not exist, you first need to create new keys and register.");
    } else {
      var serial = argResults['serial'];
      if (serial == null) {
        print("No serial given!");
      } else {
        // First get previous known record (block) for this Sample
        var previous = await api.findSample(serial);
        // Then build new sample
        var sample = Sample.fromJson(sampleJson);
        sample.seal(validicityKey, previous);
        // And submit it
        result = await api.submitSample(sample);
      }
    }
  }
}
