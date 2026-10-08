import 'dart:async';

import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/blocs/orderbook_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/orderbook/order.dart';
import 'package:web_dex/model/orderbook/orderbook.dart';
import 'package:web_dex/model/orderbook_model.dart';
import 'package:web_dex/shared/ui/gradient_border.dart';
import 'package:web_dex/views/dex/orderbook/orderbook_error_message.dart';
import 'package:web_dex/views/dex/orderbook/orderbook_table.dart';
import 'package:web_dex/views/dex/orderbook/orderbook_split_table.dart';
import 'package:web_dex/views/dex/orderbook/orderbook_table_title.dart';

class OrderbookView extends StatefulWidget {
  const OrderbookView({
    required this.base,
    required this.rel,
    this.myOrder,
    this.selectedOrderUuid,
    this.onBidClick,
    this.onAskClick,
    this.splitSides = false,
    this.visibleDirection,
    this.unavailableMessage,
  });

  final Coin? base;
  final Coin? rel;
  final Order? myOrder;
  final String? selectedOrderUuid;
  final Function(Order)? onBidClick;
  final Function(Order)? onAskClick;
  final bool splitSides;
  final OrderDirection? visibleDirection;
  final String? unavailableMessage;

  @override
  State<OrderbookView> createState() => _OrderbookViewState();
}

class _OrderbookViewState extends State<OrderbookView> {
  late OrderbookModel _model;
  Timer? _priceTimer;

  void _refreshPrices() {
    final bloc = context.read<CoinsBloc>();
    for (final coin in [widget.base, widget.rel]) {
      if (coin != null) bloc.add(CoinPriceRequested(coin.abbr));
    }
  }

  @override
  void initState() {
    _model = OrderbookModel(
      base: widget.base,
      rel: widget.rel,
      orderBookRepository: RepositoryProvider.of<OrderbookBloc>(context),
    );

    super.initState();
    _refreshPrices();
    _priceTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _refreshPrices();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _model.dispose();
    _priceTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OrderbookView oldWidget) {
    if (widget.base != oldWidget.base) _model.base = widget.base;
    if (widget.rel != oldWidget.rel) _model.rel = widget.rel;
    if (widget.base?.abbr != oldWidget.base?.abbr ||
        widget.rel?.abbr != oldWidget.rel?.abbr) {
      _refreshPrices();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OrderbookResult?>(
      initialData: _model.response,
      stream: _model.outResponse,
      builder: (context, snapshot) {
        if (!_model.isComplete) return const SizedBox.shrink();

        final OrderbookResult? result = snapshot.data;

        if (result == null) {
          return const Center(child: UiSpinner());
        }

        if (result.hasError) {
          return OrderbookErrorMessage(
            result.error ?? LocaleKeys.orderBookFailedLoadError.tr(),
            onReloadClick: _model.reload,
          );
        }

        final response = result.response;
        if (response == null) {
          return const Center(child: UiSpinner());
        }

        // A pair change can render before the stream's loading event arrives.
        // Never leave the previous pair's offers selectable during that gap.
        if (response.base != widget.base?.abbr ||
            response.rel != widget.rel?.abbr) {
          return const Center(child: UiSpinner());
        }

        final Orderbook orderbook = Orderbook.fromSdkResponse(response);
        if (widget.splitSides) {
          return OrderbookSplitTable(
            orderbook,
            myOrder: widget.myOrder,
            selectedOrderUuid: widget.selectedOrderUuid,
            onAskClick: widget.onAskClick,
            onBidClick: widget.onBidClick,
            visibleDirection: widget.visibleDirection,
            unavailableMessage: widget.unavailableMessage,
          );
        }
        if (orderbook.asks.isEmpty && orderbook.bids.isEmpty) {
          return Center(child: Text(LocaleKeys.orderBookEmpty.tr()));
        }

        return GradientBorder(
          innerColor: dexPageColors.frontPlate,
          gradient: dexPageColors.formPlateGradient,
          child: Container(
            constraints: BoxConstraints(maxWidth: theme.custom.dexFormWidth),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: OrderbookTableTitle(
                    LocaleKeys.orderBook.tr(),
                    titleTextSize: 14,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: OrderbookTable(
                    orderbook,
                    myOrder: widget.myOrder,
                    selectedOrderUuid: widget.selectedOrderUuid,
                    onAskClick: widget.onAskClick,
                    onBidClick: widget.onBidClick,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
