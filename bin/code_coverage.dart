import 'dart:io';

import 'package:code_coverage/code_coverage.dart';
import 'package:code_coverage/src/components/code_coverage_runner.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

void main(List<String> arguments) async {
  final workingDir = Directory.current;
  final packageName = getPackageName(directory: workingDir);

  final coverageReport = await CodeCoverageRunner.newDefault().run(
    packages: [packageName],
    packageDirectory: workingDir,
  );

  print(TableFormatter().format(coverageReport));
}

String getPackageName({required Directory directory}) {
  final pubspecFile = File(path.join(directory.absolute.path, 'pubspec.yaml'));
  final pubspecContent = loadYaml(pubspecFile.readAsStringSync());
  return pubspecContent['name'];
}
