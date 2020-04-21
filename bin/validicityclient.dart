import 'package:validicityclient/commands.dart';
import 'package:validicityclient/validicityclient.dart';

/// Print version and exit
printVersion(v) {
  if (v) {
    print('0.1.0');
    exit(0);
  }
}

main(List<String> arguments) async {
  // Trap process signals (ctrl-c etc)
  /*
  doExit() {
    print("Exiting");
    exit(0);
  }

  ProcessSignal.sighup.watch().listen((ProcessSignal signal) {
    print("HUP");
    doExit();
  });

  ProcessSignal.sigint.watch().listen((ProcessSignal signal) {
    print("INT");
    doExit();
  });
  ProcessSignal.sigterm.watch().listen((ProcessSignal signal) {
    print("TERM");
    doExit();
  });
*/
  var runner = CommandRunner("validicityclient", "Daemon for Validicity.")
    ..argParser.addOption("config",
        abbr: "c",
        defaultsTo: "validicity.yaml",
        valueHelp: "config file name",
        callback: (fn) => configFile = fn)
    ..addCommand(TestNFCCommand())
    ..addCommand(BootstrapCommand())
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
