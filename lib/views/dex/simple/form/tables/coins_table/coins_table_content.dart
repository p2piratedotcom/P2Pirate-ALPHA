import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/bloc/trading_status/trading_status_bloc.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/views/dex/simple/form/tables/nothing_found.dart';
import 'package:web_dex/views/dex/simple/form/tables/orders_table/grouped_list_view.dart';
import 'package:web_dex/views/dex/simple/form/tables/table_utils.dart';

class CoinsTableContent extends StatefulWidget {
  const CoinsTableContent({
    required this.onSelect,
    required this.searchString,
    required this.maxHeight,
  });

  final Function(Coin) onSelect;
  final String? searchString;
  final double maxHeight;

  @override
  State<CoinsTableContent> createState() => _CoinsTableContentState();
}

class _CoinsTableContentState extends State<CoinsTableContent> {
  late final Timer _activationRefreshTimer;

  @override
  void initState() {
    super.initState();
    context.read<CoinsBloc>().add(CoinsActivationStatusRefreshed());
    _activationRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (context.read<CoinsBloc>().state.walletCoins.values.any(
        (coin) => coin.isActivating,
      )) {
        context.read<CoinsBloc>().add(CoinsActivationStatusRefreshed());
      }
    });
  }

  @override
  void dispose() {
    _activationRefreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Using BlocBuilder to listen to TradingStatusBloc changes
    // This ensures the coin list is re-filtered when geo-blocking status changes.
    // Following BLoC best practices: widgets should rebuild when dependent bloc states change.
    return BlocBuilder<TradingStatusBloc, TradingStatusState>(
      builder: (context, tradingStatus) {
        return BlocBuilder<CoinsBloc, CoinsState>(
          builder: (context, coinsState) {
            final coins = prepareCoinsForTable(
              context,
              coinsState.walletCoins.values
                  .where((coin) => coin.isActive)
                  .toList(),
              widget.searchString,
              testCoinsEnabled: context
                  .read<SettingsBloc>()
                  .state
                  .testCoinsEnabled,
            );
            if (coins.isEmpty) return const NothingFound();

            return GroupedListView<Coin>(
              items: coins,
              onSelect: widget.onSelect,
              maxHeight: widget.maxHeight,
            );
          },
        );
      },
    );
  }
}
