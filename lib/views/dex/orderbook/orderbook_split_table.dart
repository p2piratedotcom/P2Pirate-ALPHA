import 'package:decimal/decimal.dart';
import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/orderbook/order.dart';
import 'package:web_dex/model/orderbook/orderbook.dart';
import 'package:web_dex/views/dex/orderbook/orderbook_table_item.dart';

/// Desktop order-book panels, optionally restricted to the actionable side.
class OrderbookSplitTable extends StatelessWidget {
  const OrderbookSplitTable(
    this.orderbook, {
    super.key,
    this.myOrder,
    this.selectedOrderUuid,
    this.onAskClick,
    this.onBidClick,
    this.visibleDirection,
    this.unavailableMessage,
  });

  final Orderbook orderbook;
  final Order? myOrder;
  final String? selectedOrderUuid;
  final ValueChanged<Order>? onAskClick;
  final ValueChanged<Order>? onBidClick;
  final OrderDirection? visibleDirection;
  final String? unavailableMessage;

  @override
  Widget build(BuildContext context) {
    final asks = [...orderbook.asks];
    final bids = [...orderbook.bids];
    if (myOrder?.direction == OrderDirection.ask) asks.add(myOrder!);
    if (myOrder?.direction == OrderDirection.bid) bids.add(myOrder!);
    asks.sort((a, b) {
      final byPrice = a.price.compareTo(b.price);
      return byPrice != 0 ? byPrice : b.maxVolume.compareTo(a.maxVolume);
    });
    bids.sort((a, b) {
      final byPrice = b.price.compareTo(a.price);
      return byPrice != 0 ? byPrice : b.maxVolume.compareTo(a.maxVolume);
    });

    var highestVolume = Rational.zero;
    final visibleOrders = switch (visibleDirection) {
      OrderDirection.bid => bids,
      OrderDirection.ask => asks,
      null => [...asks, ...bids],
    };
    for (final order in visibleOrders) {
      if (order.maxVolume > highestVolume) highestVolume = order.maxVolume;
    }

    final priceCoin = Coin.normalizeAbbr(orderbook.rel);
    final volumeCoin = Coin.normalizeAbbr(orderbook.base);
    final buyPanel = _OrderSidePanel(
      key: const Key('buy-orders-panel'),
      title: LocaleKeys.buy.tr(),
      emptyLabel: unavailableMessage ?? LocaleKeys.orderBookNoBids.tr(),
      color: theme.custom.bidsColor,
      orders: bids,
      priceCoin: priceCoin,
      priceTicker: orderbook.rel,
      volumeCoin: volumeCoin,
      highestVolume: highestVolume,
      selectedOrderUuid: selectedOrderUuid,
      onOrderClick: onBidClick,
    );
    if (visibleDirection == OrderDirection.bid) return buyPanel;
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
    if (visibleDirection == OrderDirection.ask) return sellPanel;

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
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final showUsd = context.select<SettingsBloc, bool>(
      (bloc) => bloc.state.showWalletUsdValues,
    );
    final coinsState = context.watch<CoinsBloc>().state;
    final quoteCoin = coinsState.coins[widget.priceTicker];
    final rawQuoteUsd = quoteCoin == null
        ? null
        : coinsState.getPriceForAsset(quoteCoin.id)?.price;
    final parsedQuoteUsd = rawQuoteUsd == null
        ? null
        : Rational.tryParse(rawQuoteUsd.toString());
    final quoteUsd = parsedQuoteUsd != null && parsedQuoteUsd > Rational.zero
        ? parsedQuoteUsd
        : null;
    return Container(
      height: 360,
      decoration: BoxDecoration(
        color: dexPageColors.frontPlate,
        border: Border.all(color: widget.color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: constraints.maxWidth < (showUsd ? 880 : 580)
                  ? (showUsd ? 880 : 580)
                  : constraints.maxWidth,
              height: constraints.maxHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                    child: Text(
                      widget.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 22, right: 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ColumnHeading(
                            'Available',
                            widget.volumeCoin,
                            'Maximum quantity available in this offer, in ${widget.volumeCoin}. The minimum accepted quantity is shown on each row.',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ColumnHeading(
                            'Unit price',
                            '${widget.priceCoin}/${widget.volumeCoin}',
                            '${widget.priceCoin} per one ${widget.volumeCoin}.',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ColumnHeading(
                            'Total',
                            widget.priceCoin,
                            'Available quantity × unit price, for the full offer. Excludes swap fees; not the amount entered in the form.',
                          ),
                        ),
                        if (showUsd) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ColumnHeading(
                              'Unit price',
                              'USD/${widget.volumeCoin}',
                              'Estimated USD value per one ${widget.volumeCoin}, using the current ${widget.priceCoin} USD reference.',
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: _ColumnHeading(
                              'Total',
                              'USD',
                              'Estimated USD value of the full available offer. Excludes swap fees and is not an execution guarantee.',
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        const SizedBox(
                          width: 40,
                          child: Center(
                            child: _ColumnHeading(
                              'UUID',
                              '',
                              'Maker order identifier. Use the copy button on a row to copy its full UUID.',
                            ),
                          ),
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
                              style: textTheme.bodySmall?.copyWith(
                                color: widget.color,
                              ),
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
                                  details: _offerCells(
                                    order,
                                    quoteUsd,
                                    showUsd,
                                  ),
                                  isSelected:
                                      widget.selectedOrderUuid != null &&
                                      order.uuid == widget.selectedOrderUuid,
                                  onClick: widget.onOrderClick,
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _offerCells(Order order, Rational? quoteUsd, bool showUsd) {
    // Native totals stay Rational. These display values never feed submissions.
    final total = order.price * order.maxVolume;
    final unitUsd = quoteUsd == null ? null : order.price * quoteUsd;
    final totalUsd = quoteUsd == null ? null : total * quoteUsd;
    final minimum = order.minVolume;
    final quantityTip =
        'Available: ${_precise(order.maxVolume)} ${widget.volumeCoin}.\n'
        '${minimum == null ? 'Minimum quantity unavailable.' : 'Minimum: ${_precise(minimum)} ${widget.volumeCoin}.'}';
    return Row(
      children: [
        Expanded(child: _amountCell(order.maxVolume, quantityTip)),
        const SizedBox(width: 12),
        Expanded(
          child: _amountCell(
            order.price,
            '${_precise(order.price)} ${widget.priceCoin} per one ${widget.volumeCoin}.',
            color: order.uuid == orderPreviewUuid
                ? theme.custom.targetColor
                : widget.color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _amountCell(
            total,
            '${_precise(order.maxVolume)} ${widget.volumeCoin} × ${_precise(order.price)} ${widget.priceCoin}/${widget.volumeCoin} = ${_precise(total)} ${widget.priceCoin}.\nFull available offer; swap fees excluded.',
          ),
        ),
        if (showUsd) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _amountCell(
              unitUsd,
              quoteUsd == null
                  ? 'USD estimate unavailable: no USD reference for ${widget.priceCoin}.'
                  : 'Estimated ${_precise(unitUsd!)} USD per ${widget.volumeCoin}.\nReference: 1 ${widget.priceCoin} ≈ ${_precise(quoteUsd)} USD.',
              usd: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _amountCell(
              totalUsd,
              quoteUsd == null
                  ? 'USD total unavailable: no USD reference for ${widget.priceCoin}.'
                  : 'Estimated total: ${_precise(totalUsd!)} USD.\n${_precise(total)} ${widget.priceCoin} × ${_precise(quoteUsd)} USD/${widget.priceCoin}.\nFull available offer; swap fees excluded.',
              usd: true,
            ),
          ),
        ],
      ],
    );
  }

  String _precise(Rational value) {
    if (value > Rational.zero && value < Rational.parse('0.00000001')) {
      return '<0.00000001';
    }
    final fixed = value
        .toDecimal(scaleOnInfinitePrecision: 18)
        .toStringAsFixed(8);
    final compact = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
    return Rational.parse(compact) == value ? compact : '≈ $compact';
  }

  Widget _amountCell(
    Rational? value,
    String tooltip, {
    bool usd = false,
    Color? color,
  }) {
    String text = 'N/A';
    if (value != null) {
      final digits = usd && value >= Rational.parse('0.01') ? 2 : 8;
      final smallest = Rational.parse('0.00000001');
      if (value > Rational.zero && value < smallest) {
        text = usd ? '<\$0.00000001' : '<0.00000001';
      } else {
        final fixed = value
            .toDecimal(scaleOnInfinitePrecision: 18)
            .toStringAsFixed(digits);
        if (usd) {
          text = '≈ \$$fixed';
        } else {
          final compact = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
          text = Rational.parse(compact) == value ? compact : '≈ $compact';
        }
      }
    }
    return Tooltip(
      message: tooltip,
      child: Text(
        text,
        textAlign: TextAlign.right,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _ColumnHeading extends StatelessWidget {
  const _ColumnHeading(this.label, this.coin, this.tooltip);

  final String label;
  final String coin;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Text(
      '$label $coin',
      textAlign: TextAlign.right,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall,
    ),
  );
}
