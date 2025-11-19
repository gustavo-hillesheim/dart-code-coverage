const value = 1;

String function() {
  final instance = MyClass();

  for (int i = 1; i <= 10; i++) {
    instance.add('.' * i);
  }

  return instance.getValues();
}

class MyClass {
  final List<String> _values = [];

  void add(String value) {
    _values.add(value);
  }

  String getValues() {
    return _values.join('\n');
  }
}

// Unused declarations (intentionally not referenced anywhere)
const int _unusedConst = 999;
final String _unusedFinal = 'this_is_unused';

void _unusedHelper() {
  final localUnused = 42;
  final list = <String>['a', 'b', 'c'];
  // operations that don't affect runtime when helper isn't called
  list.where((s) => s.contains('z')).toList();
  _unusedNoop();
}

void _unusedNoop() {
  // no-op helper left unused
}

String get _unusedGetter => 'unused';

class _UnusedUtility {
  int _counter = 0;

  void increment() {
    _counter++;
  }

  String describe() => 'counter=$_counter';
}

extension _UnusedExtension on MyClass {
  String extraInfo() => 'extra';
}
