/// Representation of a coverage report for a file.
/// This class contains the path of the file inside the lib folder (ex.: lib/test.dart is test.dart)
/// and also a map of the lines covered and how many times each line was covered.
/// There are also some methods to calculate line coverage of the file.
///
/// Normally objects of this class will be attached to a [CoverageReport] and will not be found alone.
class FileCoverageReport {
  final String fileName;
  final Map<int, int> linesCoverage;

  FileCoverageReport({
    required this.fileName,
    required this.linesCoverage,
  });

  double calculateLineCoveragePercent() {
    return calculateLinesCovered() / totalLines;
  }

  int calculateLinesCovered() {
    return linesCoverage.values
        .where((timesExecuted) => timesExecuted > 0)
        .length;
  }

  List<int> getUncoveredLines() {
    return linesCoverage.entries
        .where((entry) => entry.value == 0)
        .map((entry) => entry.key)
        .toList();
  }

  int get totalLines => linesCoverage.length;
}
