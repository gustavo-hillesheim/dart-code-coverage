# Code Coverage

A command-line application and package for Code Coverage Reporting of a Dart application.

## CLI

### Installation

To use the CLI you first need to install it globally using `pub global activate code_coverage` or `dart pub gobal activate code_coverage`.

### Usage

After installation, you can simply run `code_coverage` on the base directory of your package. <br>
Alternatively you can run it using `pub global run code_coverage` or even `dart pub global run code_coverage`, again, on the base directory of your package.

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

#### Options

Even though the base command you do for some people, there are some options to provide flexibility for the user, they are:

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
- **--packageDir, -d**: With this option you can specify the directory of the package that will be tested.