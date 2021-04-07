import 'dart:io';

import 'package:code_coverage/code_coverage.dart';
import 'package:code_coverage/src/components/code_coverage_runner.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

void main(List<String> arguments) async {
  final pubspecFile =
      File(path.join(Directory.current.absolute.path, 'pubspec.yaml'));
  final pubspecContent = loadYaml(pubspecFile.readAsStringSync());
  final packageName = pubspecContent['name'];

  final hitmapReader = HitmapReader();
  final coverageReportFactory = CoverageReportFactory();
  final coverageReport = await CodeCoverageRunner(
    hitmapReader: hitmapReader,
    coverageReportFactory: coverageReportFactory,
  ).run(packages: [packageName]);

  print(TableFormatter().format(coverageReport));
}
