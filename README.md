# Code Coverage

A command-line application and package for Code Coverage Reporting of a Dart application.

## CLI

### Usage

After installation, you can simply run `code_coverage` on the base directory of your package. <br>

The output will be something like this:
<pre>
Running package tests...
┌────────────────────┬────────────┬───────────────────┐
│ File               │ Coverage % │ Uncovered Lines   │
├────────────────────┼────────────┼───────────────────┤
│ All covered files  │      45.83 │                   │
│ src/utils.dart     │      52.38 │ 38-42, 44, 48-51  │
│ src/constants.dart │       0.00 │ 3-5               │
└────────────────────┴────────────┴───────────────────┘
18.18% (2/11) of all files were covered
</pre>

As you can see, the CLI will run your package tests and output a table showing which files and how much of them were reached.

#### Configuration

These are the available options and flags for configuring the coverage report:

- **--showOutput, -o**: This option will show the `dart test` output, so the total output will be something like this:
<pre>
Running package tests...
00:00 +0: test\utils_test.dart: should concatenate small group of lines as a range
00:00 +1: test\utils_test.dart: should concatenate medium group of lines as a range
00:00 +2: test\utils_test.dart: should concatenate two lines as separate
00:00 +3: test\utils_test.dart: should concatenate lines as range and separate
00:00 +4: test\utils_test.dart: should concatenate lines with a range followed by another range
00:00 +5: test\utils_test.dart: should concatenate lines as two ranges and two separate
00:03 +6: All tests passed!
┌────────────────────┬────────────┬───────────────────┐
│ File               │ Coverage % │ Uncovered Lines   │
├────────────────────┼────────────┼───────────────────┤
│ All covered files  │      45.83 │                   │
│ src/utils.dart     │      52.38 │ 38-42, 44, 48-51  │
│ src/constants.dart │       0.00 │ 3-5               │
└────────────────────┴────────────┴───────────────────┘
18.18% (2/11) of all files were covered
</pre>
- **--showUncovered, -u**: This option will show the list of uncovered files, this will look like this:
<pre>
Running package tests...
┌───────────────────┬────────────┬─────────────────┐
│ File              │ Coverage % │ Uncovered Lines │
├───────────────────┼────────────┼─────────────────┤
│ All covered files │      80.00 │                 │
│ a.dart            │      80.00 │ 20-21           │
└───────────────────┴────────────┴─────────────────┘
50.00% (1/2) of all files were covered

Uncovered files:
- b.dart
</pre>
- **--packageDir, -d**: With this option you can specify the directory of the package that will be tested;
- **--minimum, -m**: This option allows you to require a minimum code coverage, if the line or file coverage does not reaches the value specified, the process will exit with code 1;
- **--include, -i**: Allows you to specify multiple regexes that will be matched against all paths, and those that match any of the regexes will be included in the report. For example, using the regex `utils`, this would be the output:
<pre>
Running package tests...
┌────────────────────┬────────────┬───────────────────┐
│ File               │ Coverage % │ Uncovered Lines   │
├────────────────────┼────────────┼───────────────────┤
│ All covered files  │      52.38 │                   │
│ src/utils.dart     │      52.38 │ 38-42, 44, 48-51  │
└────────────────────┴────────────┴───────────────────┘
100% (1/1) of all files were covered
</pre>
- **--exclude, -e**: Allows you to specify multiple regexes that will be matched agains all paths, and those that don't match all of the regexes will be included in the report. For example, using the regex `utils`, this would be the output:
<pre>
┌────────────────────┬────────────┬───────────────────┐
│ File               │ Coverage % │ Uncovered Lines   │
├────────────────────┼────────────┼───────────────────┤
│ All covered files  │       0.00 │                   │
│ src/constants.dart │       0.00 │ 3-5               │
└────────────────────┴────────────┴───────────────────┘
20% (2/10) of all files were covered
</pre>

## Package

You can also use code_coverage as a package, so you can create your custom code coverage reports and applications!<br>
Here are the classes that you are likely to use:
- **HitmapReader**: Using the methods `fromDirectory`, `fromFile` and `fromString`, you can create a Hitmap object containing the files and lines reached in your tests. This class is used with `dart test --coverage` to read and parse the coverage output;
- **CoverageReportFactory**: Using the method `create` with a hitmap, base directory of a package and the package name, you can create a `CoverageReport`. The package directory is needed so the report will contain the uncovered files (dart test coverage output does not contain these), and the package name is used to filter the coverage output (it contains all the files covered, including internals);
- **CoverageReport**: This class contains the covered files reports, names of uncovered files, and also some useful methods for coverage reporting;
- **FileCoverageReport**: This class contains the covered file name, the lines covered and how many times they were reached, and also some useful methods for coverage reporting.

If you want to build your own coverage reporting tool, take a look at the `CodeCoverageExtractor` class, it is the main class that runs the tests and extracts the coverage reports.