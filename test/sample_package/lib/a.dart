int sum(int a, int b) {
  return a + b;
}

int subtract(int a, int b) {
  return a - b;
}

int max(int a, int b) {
  if (a > b) {
    return a;
  }
  return b;
}

int min(int a, int b) {
  return a < b ? a : b;
}

int abs(double a) {
  final absolute = a.toInt();
  return absolute;
}
