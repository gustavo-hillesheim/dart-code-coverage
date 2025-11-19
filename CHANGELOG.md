## 2.1.0

- Added total coverage percentage and lines of code for each file
- Added `exclude-fully-covered` option to remove fully covered files from the report

## 2.0.1

- Removed dependency to add compatibility with older Dart SDK versions

## 2.0.0

### Features

- Added `test-args` option to specify additional arguments for internal `dart test`/`flutter test` command

### Changes

- Changed Dart SDK constraints to `">=3.0.0 <4.0.0`
- Changed `All covered files` output line to end of table so its easier to find it on larger projects
- Changed command arguments from camelCase to kebab-case
- Changed `ignore-barrel-files` option default value to `true`
- Changed `show-uncovered` option to `hide-uncovered-files` with `false` default value. Now uncovered files are shown by default
- Removed `show-output` option. Now test output is always shown
- Improved table output to word-wrap when reaching maximum terminal window width

## 1.4.0

### Features

- Added 'ignoreBarrelFiles' flag
- Added 'inlineFiles' flag

### Changes

- Changed default print to group files by folder and show individual folder coverage

## 1.3.0

### Changes

- Changed 'include' and 'exclude' options to accept multiple arguments

## 1.2.0

### Features

- Added 'include' and 'exclude' options
- Added validation of existence of 'test' directory
- Added help message

### Fixes

- Fixed alignment of 'Uncovered lines' of report table
- Fixed error in which covered files would show up as uncovered

## 1.1.0

- Added support to Flutter projects

## 1.0.0-SNAPSHOT

- Created initial version of CLI
