import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

String? getPackageName({required Directory directory}) {
  final pubspecFile = File(path.join(directory.absolute.path, 'pubspec.yaml'));
  final pubspecContent = loadYaml(pubspecFile.readAsStringSync());
  return pubspecContent['name'];
}
