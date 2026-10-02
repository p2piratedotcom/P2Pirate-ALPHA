import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/taker_form/taker_bloc.dart';
import 'package:web_dex/bloc/taker_form/taker_event.dart';
import 'package:web_dex/bloc/taker_form/taker_state.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/views/dex/common/front_plate.dart';
import 'package:web_dex/views/dex/simple/form/tables/coins_table/coins_table_content.dart';
import 'package:web_dex/views/dex/simple/form/tables/table_search_field.dart';
import 'package:web_dex/views/dex/simple/form/taker/coin_item/taker_form_buy_switcher.dart';
import 'package:web_dex/views/dex/simple/form/taker/coin_item/trade_controller.dart';

class OrdersTable extends StatefulWidget {
  const OrdersTable({super.key});

  @override
  State<OrdersTable> createState() => _OrdersTableState();
}

class _OrdersTableState extends State<OrdersTable> {
  String? _searchTerm;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TakerBloc, TakerState>(
      builder: (context, state) {
        final buyCoin = state.buyCoin;
        final controller = TradeOrderController(
          order: context.read<TakerBloc>().state.selectedOrder,
          coin: buyCoin,
          onTap: () => context.read<TakerBloc>().add(TakerOrderSelectorClick()),
          isEnabled: false,
          isOpened: true,
        );

        return FocusTraversalGroup(
          child: FrontPlate(
            shadowEnabled: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TakerFormBuySwitcher(
                  controller,
                  padding: const EdgeInsets.only(top: 16, bottom: 12),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TableSearchField(
                    height: 30,
                    onChanged: (String value) {
                      if (_searchTerm == value) return;
                      setState(() => _searchTerm = value);
                    },
                  ),
                ),
                const SizedBox(height: 5),
                if (state.bestOrders?.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Could not load swap offers: ${state.bestOrders!.error!.message}',
                        ),
                        TextButton(
                          onPressed: () => context.read<TakerBloc>().add(
                            TakerUpdateBestOrders(),
                          ),
                          child: const Text('Retry loading offers'),
                        ),
                      ],
                    ),
                  ),
                CoinsTableContent(
                  onSelect: (Coin coin) =>
                      context.read<TakerBloc>().add(TakerSelectBuyCoin(coin)),
                  searchString: _searchTerm,
                  maxHeight: 200,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
