import 'package:validicityclient/commands.dart';
import 'package:validicityclient/validicityclient.dart';
import 'package:validicityclient/pubspec.dart';

/// Print version and exit
printVersion(v) {
  if (v) {
    print(Pubspec.version);
    exit(0);
  }
}

main(List<String> arguments) async {
  var runner = CommandRunner("validicityclient", "Daemon for Validicity.")
    ..argParser.addOption("config",
        abbr: "c",
        defaultsTo: "validicity.yaml",
        valueHelp: "config file name",
        callback: (fn) => configFile = fn)
    ..addCommand(TestNFCCommand())
    ..addCommand(TestEmulatedKeyboard())
    ..addCommand(TestContinuous())
    ..addCommand(CreateKeysCommand())
    ..addCommand(RegisterCommand())
    ..addCommand(StatusCommand())
    ..argParser.addFlag('version',
        negatable: false,
        help: 'Show version of validicityclient',
        callback: printVersion)
    ..argParser.addFlag('verbose',
        help: 'Show more information when executing commands',
        abbr: 'v',
        defaultsTo: null)
    ..argParser.addFlag('pretty',
        help: 'Pretty print JSON in results', abbr: 'p', defaultsTo: null);
  await runner.run(arguments);
  exit(0);
}
