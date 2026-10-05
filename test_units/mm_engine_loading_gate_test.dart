import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_loading_gate.dart';

void main() {
  Future<void> show(WidgetTester tester, bool loading, Widget child) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MmEngineLoadingGate(loading: loading, child: child),
          ),
        ),
      );

  testWidgets('initial checks show only a circle, without install prompts', (
    tester,
  ) async {
    await show(
      tester,
      true,
      const Column(
        children: [
          Text('P2Pirate Trading Engine is not installed'),
          Text('CEX plugins are not installed'),
          LinearProgressIndicator(),
        ],
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('not installed'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('verified content appears once loading completes', (
    tester,
  ) async {
    await show(tester, true, const Text('MY MAKER ORDERS'));
    await show(tester, false, const Text('MY MAKER ORDERS'));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('MY MAKER ORDERS'), findsOneWidget);
  });

  testWidgets('actual missing installation and errors remain visible', (
    tester,
  ) async {
    for (final message in [
      'CEX plugins are not installed',
      'Connection failed',
    ]) {
      await show(tester, false, Text(message));
      expect(find.text(message), findsOneWidget);
    }
  });

  testWidgets('download progress remains visible after initial checks', (
    tester,
  ) async {
    await show(tester, false, const LinearProgressIndicator(value: .5));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
