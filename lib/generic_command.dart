import 'package:validicitylib/config.dart';
import 'package:validicitylib/rest.dart';

import 'validicityclient.dart';

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

abstract class GenericCommand extends GenericSubCommand {
  GenericCommand(entity, description) : super(entity, description) {
    addSubcommand(GenericCreateCommand(entity));
    addSubcommand(GenericUpdateCommand(entity));
    addSubcommand(GenericDeleteCommand(entity));
    addSubcommand(GenericGetCommand(entity));
  }
}

abstract class GenericSubCommand extends BaseCommand {
  String entity, description;

  GenericSubCommand(this.entity, this.description);

  void addFileOption() {
    argParser.addOption('file',
        abbr: 'f', help: "The path to JSON metadata file");
  }

  void exec() async {
    return;
  }
}

class GenericCreateCommand extends GenericSubCommand {
  final name = "create";

  GenericCreateCommand(entity)
      : super(entity, "Create a ${capitalize(entity)} entity.") {
    argParser.addOption('file',
        abbr: 'f', help: "The JSON file with entity content");
  }

  void exec() async {
    var fn = argResults['file'];
    var payload = loadFile(fn);
    await api.getClient().doPost('${entity}', payload);
  }
}

class GenericUpdateCommand extends GenericSubCommand {
  final name = "update";

  GenericUpdateCommand(entity)
      : super(entity, "Update a ${capitalize(entity)} entity.") {
    argParser.addOption('id',
        abbr: 'i', help: "The id of the entity to update");
    argParser.addOption('file',
        abbr: 'f', help: "The JSON file with entity content");
  }

  void exec() async {
    var fn = argResults['file'];
    var id = argResults['id'];
    await api.getClient().doPut('$entity/$id', loadFile(fn));
  }
}

class GenericDeleteCommand extends GenericSubCommand {
  final name = "delete";

  GenericDeleteCommand(entity)
      : super(entity, "Delete a ${capitalize(entity)} entity.") {
    argParser.addOption('id',
        abbr: 'i', help: "The id of the entity to delete");
  }

  void exec() async {
    var id = argResults['id'];
    await api.getClient().doDelete('${entity}/${id}');
  }
}

class GenericGetCommand extends GenericSubCommand {
  final name = "get";

  GenericGetCommand(entity)
      : super(entity, "Get one ${capitalize(entity)} entity, or all.") {
    argParser.addOption('id',
        abbr: 'i',
        help: "The id of the entity to get, otherwise all are returned");
  }

  void exec() async {
    var id = argResults['id'];
    await api.getClient().doGet(id != null ? '${entity}/$id' : '${entity}');
  }
}
