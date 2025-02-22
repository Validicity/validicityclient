/// Validicity
library validicitylib;

import 'dart:io';

import 'package:args/args.dart';
import 'package:validicitylib/config.dart';

export 'dart:io';
export 'dart:convert';

export 'package:args/command_runner.dart';
export 'package:logging/logging.dart';

//export 'package:validicitylib/validicitylib.dart';
export 'package:validicityclient/commands.dart';

const appName = 'validityclient';

String configFile = 'validity.yaml';

String boardId = readBoardId();

String readBoardId() {
  return File('/sys/class/efuse/usid').readAsStringSync();
}

configureValidicity(ArgResults globalResults) {
  configure(appName, null, configFile);
  if (globalResults['verbose'] != null) {
    config.verbose = globalResults['verbose'];
  }
  if (config.verbose) {
    print("CONFIG: ${config.path}");
  }
  if (globalResults['pretty'] != null) {
    config.pretty = globalResults['pretty'];
  }
}
