# Code Coverage

A command-line application for calculation code coverage of dart and flutter applications.

## CLI

### Usage

Run `code_coverage` on your package. <br>
Output will be in this format:

<pre>
Running tests for package example...
┌───────────────────┬────────────┬─────────────────┐
│ File              │ Coverage % │ Uncovered Lines │
├───────────────────┼────────────┼─────────────────┤
│  src              │      66.67 │                 │
├───────────────────┼────────────┼─────────────────┤
│    a.dart         │      60.00 │ 5-6, 20-21      │
├───────────────────┼────────────┼─────────────────┤
│    b.dart         │     100.00 │                 │
├───────────────────┼────────────┼─────────────────┤
│ All covered files │      66.67 │                 │
└───────────────────┴────────────┴─────────────────┘
66.67% (2/3) of all files were covered

Uncovered files:
- src/others/c.dart
</pre>

#### Configuration

These are the available options and flags for configuring the coverage report:

- **--show-output, -o**: Prints `dart test` output.
- **--showUncovered, -u**: Shows uncovered files. Defaults to true.
- **--package-dir, -d**: Specifies the directory in which coverage will be calculated.
- **--minimum, -m**: Specifies minimum expected coverage. If line or file coverage does not reach this value, process will exit with code 1.
- **--include, -i**: Specifies which files to include in coverage output using one or multiple regexes.
- **--exclude, -e**: Specifies which files not to include in coverage output using one or multiple regexes.
- **--ignore-barrel-files**: Ignores barrel files in coverage output.
- **--inline-files**: Shows whole file path in output lines instead of using tree view.