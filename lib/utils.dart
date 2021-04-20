String summarizeLines(List<int> lines) {
  var result = '';
  var isSequence = false;
  var sequenceStart;
  for (var i = 0; i < lines.length; i++) {
    final currentLine = lines[i];
    final nextLine = lines.length > i + 1 ? lines[i + 1] : null;
    if (isSequence && (nextLine == null || currentLine != nextLine - 1)) {
      if (result.isNotEmpty) {
        result += ', ';
      }
      result += '$sequenceStart-$currentLine';
      isSequence = false;
      sequenceStart = null;
    } else if (!isSequence) {
      if (nextLine != null && currentLine == nextLine - 1) {
        isSequence = true;
        sequenceStart = currentLine;
      } else {
        if (result.isNotEmpty) {
          result += ', ';
        }
        result += '$currentLine';
      }
    }
  }
  if (isSequence) {
    result += '$sequenceStart-${lines.last}';
  }
  return result;
}
