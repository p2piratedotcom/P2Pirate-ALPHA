import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/bloc/settings/settings_repository.dart';
import 'package:web_dex/model/stored_settings.dart';
import 'package:web_dex/model/available_balance_state.dart';
import 'package:web_dex/services/storage/base_storage.dart';
import 'package:web_dex/views/settings/widgets/general_settings/settings_market_prices.dart';
import 'package:web_dex/views/dex/simple/form/taker/available_balance.dart';

class MemoryStorage implements BaseStorage {
  final values = <String, dynamic>{};
  @override
  Future<bool> write(String key, dynamic value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<dynamic> read(String key) async => values[key];
  @override
  Future<bool> delete(String key) async => values.remove(key) != null;
}

void main() {
  testWidgets('late price API A result cannot overwrite new URL B result', (
    tester,
  ) async {
    final bloc = SettingsBloc(
      StoredSettings.initial(),
      SettingsRepository(storage: MemoryStorage()),
    );
    addTearDown(bloc.close);
    final first = Completer<int>(), second = Completer<int>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: bloc,
            child: SettingsMarketPrices(
              testSource: (url) =>
                  url.contains('first') ? first.future : second.future,
            ),
          ),
        ),
      ),
    );
    final input = find.byKey(const Key('custom-price-api-url'));
    await tester.enterText(input, 'https://first.example/tickers');
    await tester.tap(find.text('Test API'));
    await tester.pump();
    await tester.enterText(input, 'https://second.example/tickers');
    await tester.pump();
    await tester.tap(find.text('Test API'));
    second.complete(2);
    await tester.pumpAndSettle();
    expect(
      find.text('Tested current URL: 2 tickers available'),
      findsOneWidget,
    );
    first.complete(99);
    await tester.pumpAndSettle();
    expect(
      find.text('Tested current URL: 2 tickers available'),
      findsOneWidget,
    );
    expect(find.textContaining('99 tickers'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown and failed balances are distinct from confirmed zero', (
    tester,
  ) async {
    Future<void> show(AvailableBalanceState state, Rational? amount) =>
        tester.pumpWidget(
          MaterialApp(home: Scaffold(body: AvailableBalance(amount, state))),
        );
    await show(AvailableBalanceState.unavailable, Rational.zero);
    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.text('0.00'), findsNothing);
    await show(AvailableBalanceState.failure, Rational.fromInt(5));
    expect(find.text('Could not refresh'), findsOneWidget);
    await show(AvailableBalanceState.success, Rational.zero);
    expect(find.text('0.00'), findsOneWidget);
    expect(find.text('Unavailable'), findsNothing);
  });
}
