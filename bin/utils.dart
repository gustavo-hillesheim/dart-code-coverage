import 'package:ansicolor/ansicolor.dart';

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
  final kRedPen = AnsiPen()..red();
  final kYellowPen = AnsiPen()..yellow();
  final kGreenPen = AnsiPen()..green();
  if (coveragePercent < .6) {
    return kRedPen;
  } else if (coveragePercent < .8) {
    return kYellowPen;
  } else {
    return kGreenPen;
  }
}
