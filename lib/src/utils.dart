import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

class PackageData {
  final String name;
  final Directory directory;
  final bool isFlutterProject;

  PackageData(
      {required this.name,
      required this.directory,
      required this.isFlutterProject});

  @override
  String toString() {
    return 'PackageData(name="$name", isFlutterProject=$isFlutterProject)';
  }
}

/// Returns the package data based on the pubspec.yaml residing on the given directory
PackageData? getPackageData({required Directory directory}) {
  final pubspecFile = File(path.join(directory.absolute.path, 'pubspec.yaml'));
  final pubspecContent = loadYaml(pubspecFile.readAsStringSync());
  if (pubspecContent != null) {
    final name = pubspecContent['name'];
    final dependencies = pubspecContent['dependencies'];
    final isFlutterProject =
        dependencies is Map && dependencies.containsKey('flutter');
    return PackageData(
      name: name,
      directory: directory,
      isFlutterProject: isFlutterProject,
    );
  }
  return null;
}
