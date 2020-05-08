find ./lib -name "*.g.dart" | xargs rm
pub run build_runner build --delete-conflicting-outputs
