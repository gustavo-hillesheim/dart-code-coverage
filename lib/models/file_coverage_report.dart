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
