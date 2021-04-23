import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:code_coverage/constants.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

String summarizeLines(List<int> lines) {
  var result = '';
  var isSequence = false;
  var sequenceStart;
  for (var i = 0; i < lines.length; i++) {
    final currentLine = lines[i];
    final nextLine = lines.length > i + 1 ? lines[i + 1] : null;
    if (isSequence && (nextLine == null || currentLine != nextLine - 1)) {
      result = concatenate(result, '$sequenceStart-$currentLine');
      isSequence = false;
      sequenceStart = null;
    } else if (!isSequence) {
      if (nextLine != null && currentLine == nextLine - 1) {
        isSequence = true;
        sequenceStart = currentLine;
      } else {
        result = concatenate(result, '$currentLine');
      }
    }
  }
  return result;
}

String concatenate(String initial, String toAdd) {
  if (initial.isNotEmpty) {
    return '$initial, $toAdd';
  }
  return toAdd;
}

AnsiPen coveragePen(double coveragePercent) {
  if (coveragePercent < .6) {
    return kRedPen;
  } else if (coveragePercent < .8) {
    return kYellowPen;
  } else {
    return kGreenPen;
  }
}

String? getPackageName({required Directory directory}) {
  final pubspecFile = File(path.join(directory.absolute.path, 'pubspec.yaml'));
  final pubspecContent = loadYaml(pubspecFile.readAsStringSync());
  return pubspecContent['name'];
}
