// ignore_for_file: avoid_print

import 'dart:io';

import 'package:args/args.dart';

import 'test_integration/runners/integration_test_runner.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false)
    ..addFlag('verbose', abbr: 'v', negatable: false)
    ..addFlag('kdf', negatable: false);
  final args = parser.parse(arguments);
  if (args['help'] as bool) {
    print('Run Linux desktop tests under Xvfb.');
    print('--kdf starts a verified KDF 2.7 binary in a disposable profile.');
    print(parser.usage);
    exit(0);
  }

  try {
    await IntegrationTestRunner(
      verbose: args['verbose'] as bool,
      runKdf: args['kdf'] as bool,
    ).run();
  } on ProcessException catch (error) {
    stderr.writeln(error);
    exit(1);
  } catch (error, stack) {
    stderr.writeln('$error\n$stack');
    exit(1);
  }
}
