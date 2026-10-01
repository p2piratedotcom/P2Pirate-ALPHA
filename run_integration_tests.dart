// ignore_for_file: avoid_print

import 'dart:io';

import 'package:args/args.dart';

import 'test_integration/runners/integration_test_runner.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false)
    ..addFlag('verbose', abbr: 'v', negatable: false);
  final args = parser.parse(arguments);
  if (args['help'] as bool) {
    print('Run the Linux desktop UI integration tests under Xvfb.');
    print(parser.usage);
    exit(0);
  }

  try {
    await IntegrationTestRunner(verbose: args['verbose'] as bool).run();
  } on ProcessException catch (error) {
    stderr.writeln(error);
    exit(1);
  } catch (error, stack) {
    stderr.writeln('$error\n$stack');
    exit(1);
  }
}
