install_local:
	- rm -rf .dart_tool
	- fvm dart pub get
	- fvm dart pub global deactivate code_coverage
	- rm ~/.pub-cache/bin/code_coverage
	- cd .. && fvm dart pub global activate --source path code_coverage

run_example:
	fvm dart run bin/code_coverage.dart -d example