import 'package:nanodart/nanodart.dart';
import 'package:validicityclient/block.dart';
import 'package:validicityclient/validicityclient.dart';
import 'package:validicitylib/config.dart';

import 'package:json_annotation/json_annotation.dart';

part 'key.g.dart';

String keyFile = 'key.json';

Key validicityKey;

String createKey() {
  validicityKey = Key();
  validicityKey.create();
  return saveKey();
}

loadKey() {
  var f = fileInHome(keyFile);
  if (f.existsSync()) {
    try {
      var jsonString = f.readAsStringSync();
      validicityKey = Key.fromJson(json.decode(jsonString));
    } catch (e) {
      print('Failed to parse key file ${f.path} : $e');
      exit(1);
    }
  }
}

String saveKey() {
  var f = fileInHome(keyFile);
  try {
    f.writeAsStringSync(json.encode(validicityKey.toJson()));
  } catch (e) {
    print('Failed to save key file ${f.path} : $e');
    exit(1);
  }
  return f.path;
}

/*
    // Encrypting and decrypting a seed
    Uint8List encrypted = NanoCrypt.encrypt(seed, 'thisisastrongpassword');
    // String representation:
    String encryptedSeedHex = NanoHelpers.byteToHex(encrypted);
    // Decrypting (if incorrect password, will throw an exception)
    Uint8List decrypted = NanoCrypt.decrypt(
        NanoHelpers.hexToBytes(encryptedSeedHex), 'thisisastrongpassword');
*/
@JsonSerializable()
class Key {
  String publicKey;
  String privateKey;

  Key() {}

  create() {
    // Generating a random seed
    String seed = NanoSeeds.generateSeed();
    // Getting private key at index-0 of this seed
    privateKey = NanoKeys.seedToPrivate(seed, 0);
    // Getting public key from this private key
    publicKey = NanoKeys.createPublicKey(privateKey);
  }

  /// Signing a block
  signBlock(Block block) {
    block.signature =
        NanoSignatures.signBlock(block.calculateHash(), privateKey);
  }

  factory Key.fromJson(Map<String, dynamic> json) => _$KeyFromJson(json);

  Map<String, dynamic> toJson() => _$KeyToJson(this);
}
