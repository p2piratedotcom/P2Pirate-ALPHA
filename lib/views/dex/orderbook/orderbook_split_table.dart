import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/orderbook/order.dart';
import 'package:web_dex/model/orderbook/orderbook.dart';
import 'package:web_dex/views/dex/orderbook/orderbook_table_item.dart';

/// Large Buy and Sell order-book panels for the desktop Swap form.
class OrderbookSplitTable extends StatelessWidget {
  const OrderbookSplitTable(
    this.orderbook, {
    super.key,
    this.myOrder,
    this.selectedOrderUuid,
    this.onAskClick,
    this.onBidClick,
  });

  final Orderbook orderbook;
  final Order? myOrder;
  final String? selectedOrderUuid;
  final ValueChanged<Order>? onAskClick;
  final ValueChanged<Order>? onBidClick;

  @override
  Widget build(BuildContext context) {
    final asks = [...orderbook.asks];
    final bids = [...orderbook.bids];
    if (myOrder?.direction == OrderDirection.ask) asks.add(myOrder!);
    if (myOrder?.direction == OrderDirection.bid) bids.add(myOrder!);
    asks.sort((a, b) {
      final byPrice = a.price.compareTo(b.price);
      return byPrice != 0
          ? byPrice
          : b.maxVolume.compareTo(a.maxVolume);
    });
    bids.sort((a, b) {
      final byPrice = b.price.compareTo(a.price);
      return byPrice != 0
          ? byPrice
          : b.maxVolume.compareTo(a.maxVolume);
    });

    var highestVolume = Rational.zero;
    for (final order in [...asks, ...bids]) {
      if (order.maxVolume > highestVolume) highestVolume = order.maxVolume;
    }

    final priceCoin = Coin.normalizeAbbr(orderbook.rel);
    final volumeCoin = Coin.normalizeAbbr(orderbook.base);
    final buyPanel = _OrderSidePanel(
      key: const Key('buy-orders-panel'),
      title: LocaleKeys.buy.tr(),
      emptyLabel: LocaleKeys.orderBookNoBids.tr(),
      color: theme.custom.bidsColor,
      orders: bids,
      priceCoin: priceCoin,
      priceTicker: orderbook.rel,
      volumeCoin: volumeCoin,
      highestVolume: highestVolume,
      selectedOrderUuid: selectedOrderUuid,
      onOrderClick: onBidClick,
    );
    final sellPanel = _OrderSidePanel(
      key: const Key('sell-orders-panel'),
      title: LocaleKeys.sell.tr(),
      emptyLabel: LocaleKeys.orderBookNoAsks.tr(),
      color: theme.custom.asksColor,
      orders: asks,
      priceCoin: priceCoin,
      priceTicker: orderbook.rel,
      volumeCoin: volumeCoin,
      highestVolume: highestVolume,
      selectedOrderUuid: selectedOrderUuid,
      onOrderClick: onAskClick,
    );

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 960
          ? Column(children: [buyPanel, const SizedBox(height: 16), sellPanel])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: buyPanel),
                const SizedBox(width: 16),
                Expanded(child: sellPanel),
              ],
            ),
    );
  }
}

class _OrderSidePanel extends StatefulWidget {
  const _OrderSidePanel({
    super.key,
    required this.title,
    required this.emptyLabel,
    required this.color,
    required this.orders,
    required this.priceCoin,
    required this.priceTicker,
    required this.volumeCoin,
    required this.highestVolume,
    required this.selectedOrderUuid,
    required this.onOrderClick,
  });

  final String title;
  final String emptyLabel;
  final Color color;
  final List<Order> orders;
  final String priceCoin;
  final String priceTicker;
  final String volumeCoin;
  final Rational highestVolume;
  final String? selectedOrderUuid;
  final ValueChanged<Order>? onOrderClick;

  @override
  State<_OrderSidePanel> createState() => _OrderSidePanelState();
}

class _OrderSidePanelState extends State<_OrderSidePanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final coinsState = context.watch<CoinsBloc>().state;
    return Container(
      height: 360,
      decoration: BoxDecoration(
        color: dexPageColors.frontPlate,
        border: Border.all(color: widget.color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Text(
              widget.title,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 22, right: 18),
            child: Row(
              children: [
                Expanded(
                  child: _ColumnHeading(LocaleKeys.price.tr(), widget.priceCoin),
                ),
                const SizedBox(width: 10),
                const Expanded(child: _ColumnHeading('Price', 'USD')),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _ColumnHeading(
                      LocaleKeys.volume.tr(),
                      widget.volumeCoin,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const SizedBox(
                  width: 40,
                  child: Center(child: _ColumnHeading('UUID', '')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: widget.orders.isEmpty
                ? Center(
                    child: Text(
                      widget.emptyLabel,
                      style: textTheme.bodySmall?.copyWith(color: widget.color),
                    ),
                  )
                : Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 8, 18, 12),
                      itemCount: widget.orders.length,
                      itemBuilder: (context, index) {
                        final order = widget.orders[index];
                        final volumeFraction =
                            widget.highestVolume == Rational.zero
                            ? 0.0
                            : (order.maxVolume / widget.highestVolume)
                                  .toDouble();
                        return OrderbookTableItem(
                          order,
                          key: Key(
                            'split-order-${order.direction.name}-$index-${order.uuid ?? ''}',
                          ),
                          volumeFraction: volumeFraction,
                          large: true,
                          showOrderDetails: true,
                          // KDF quotes rel units per base unit. Convert that
                          // amount using the rel coin's current USD quote.
                          usdPrice: _usdPrice(
                            coinsState.getUsdPriceForAmount(
                              order.price.toDouble(),
                              widget.priceTicker,
                            ),
                          ),
                          isSelected: widget.selectedOrderUuid != null &&
                              order.uuid == widget.selectedOrderUuid,
                          onClick: widget.onOrderClick,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _usdPrice(double? value) {
    if (value == null || !value.isFinite || value <= 0) return 'N/A';
    if (value < 0.00000001) return '<\$0.00000001';
    return '\$${value.toStringAsFixed(value < 0.01 ? 8 : 2)}';
  }
}

class _ColumnHeading extends StatelessWidget {
  const _ColumnHeading(this.label, this.coin);

  final String label;
  final String coin;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label $coin',
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}
