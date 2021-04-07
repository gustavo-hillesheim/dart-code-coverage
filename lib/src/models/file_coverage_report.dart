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

  int get totalLines => linesCoverage.length;
}
