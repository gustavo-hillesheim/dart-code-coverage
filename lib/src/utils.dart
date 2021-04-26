import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

/// Returns the package name based on the pubspec.yaml residing on the given directory
String? getPackageName({required Directory directory}) {
  final pubspecFile = File(path.join(directory.absolute.path, 'pubspec.yaml'));
  final pubspecContent = loadYaml(pubspecFile.readAsStringSync());
  return pubspecContent['name'];
}
