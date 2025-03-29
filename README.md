# Code Coverage

A command-line application for calculation code coverage of dart and flutter applications.

## CLI

### Usage

Run `code_coverage` on your package. <br>
Output will be in this format:

<pre>
Running package tests...
┌────────────────────┬────────────┬───────────────────┐
│ File               │ Coverage % │ Uncovered Lines   │
├────────────────────┼────────────┼───────────────────┤
│ src/utils.dart     │      52.38 │ 38-42, 44, 48-51  │
│ src/constants.dart │       0.00 │ 3-5               │
│ All covered files  │      45.83 │                   │
└────────────────────┴────────────┴───────────────────┘
18.18% (2/11) of all files were covered
</pre>

#### Configuration

These are the available options and flags for configuring the coverage report:

- **--show-output, -o**: Prints `dart test` output.
- **--showUncovered, -u**: Shows uncovered files.
- **--package-dir, -d**: Specifies the directory in which coverage will be calculated.
- **--minimum, -m**: Specifies minimum expected coverage. If line or file coverage does not reach this value, process will exit with code 1.
- **--include, -i**: Specifies which files to include in coverage output using one or multiple regexes.
- **--exclude, -e**: Specifies which files not to include in coverage output using one or multiple regexes.
- **--ignore-barrel-files**: Ignores barrel files in coverage output.
- **--inline-files**: Shows whole file path in output lines instead of using tree view.