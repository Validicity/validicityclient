import 'dart:async';

import 'package:args/command_runner.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:validicityclient/emulated_keyboard.dart';
import 'package:validicityclient/key.dart';
import 'package:validicityclient/nfc.dart';
import 'package:validicitylib/api.dart';
import 'package:validicitylib/config.dart';
import 'package:validicitylib/rest.dart';
import 'package:path/path.dart' as path;
import 'validicityclient.dart';

const String clientID = "com.validicity.client";

abstract class BaseCommand extends Command implements CredentialsHolder {
  RestClient client;
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

  void run() async {
    configureValidicity(globalResults);
    var url = Uri.parse(config.api.url);
    api = ValidicityServerAPI(clientID, holder: this);
    api
      ..username = config.api.username
      ..password = config.api.password
      ..scopes = scopes
      ..server = url.host
      ..responseHandler = handleResponse;
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
  final description = "Test NFC scanning to verify it works.";

  void exec() async {
    var nfc = NFCDriver();
    var keyboard = EmulatedKeyboard();
    keyboard.open();
    print("Starting NFC scanner ...");
    await nfc.start();
    print("Ready to scan ...");
    var result = await nfc.scan();
    print(json.encode(result));
    await keyboard.print(result['ID']);
    await keyboard.close();
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

class BootstrapCommand extends BaseCommand {
  String description = "Bootstrap of Validicity creating admin account etc.";
  String name = "bootstrap";

  BootstrapCommand() {
    argParser.addOption('file',
        abbr: 'f', help: "The JSON file with the bootstrap content");
  }

  void exec() async {
    var payload = loadFile(argResults['file']);
    await client.doPost('bootstrap', payload, auth: false);
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
      Key.createKeys();
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
    var payload = {"public": validicityKey.publicKey, "account": boardId};
    await client.doPost('register', payload);
  }
}
