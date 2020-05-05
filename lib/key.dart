Key validicityKey;

class Key {
  String publicKey;
  String privateKey;

  Key() {}

  bool save() {}

  bool load() {}

  static void createKeys() {
    validicityKey = Key();
    validicityKey.save();
  }
}
