import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/taker_form/taker_bloc.dart';
import 'package:web_dex/bloc/taker_form/taker_event.dart';
import 'package:web_dex/bloc/taker_form/taker_state.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/dex/common/front_plate.dart';
import 'package:web_dex/views/dex/simple/form/common/dex_form_group_header.dart';
import 'package:web_dex/views/dex/simple/form/taker/coin_item/taker_form_buy_switcher.dart';
import 'package:web_dex/views/dex/simple/form/taker/coin_item/trade_controller.dart';

class TakerFormBuyItem extends StatelessWidget {
  const TakerFormBuyItem({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TakerBloc, TakerState>(
      buildWhen: (prev, curr) {
        if (prev.selectedOrder != curr.selectedOrder) return true;
        if (prev.buyCoin != curr.buyCoin) return true;
        if (prev.bestOrders != curr.bestOrders) return true;
        if (prev.sellCoin != curr.sellCoin) return true;

        return false;
      },
      builder: (context, state) {
        final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
        final coin = coinsRepository.getCoin(state.buyCoin?.abbr ?? '');

        final controller = TradeOrderController(
          order: state.selectedOrder,
          coin: coin,
          isEnabled: false,
          isOpened: false,
          onTap: () {
            context.read<TakerBloc>().add(TakerOrderSelectorClick());
          },
        );

        return FrontPlate(
          child: Column(
            children: [
              _BuyHeader(),
              TakerFormBuySwitcher(controller),
              if (state.bestOrders?.error != null)
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Could not load swap offers: ${state.bestOrders!.error!.message}',
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.read<TakerBloc>().add(
                          TakerUpdateBestOrders(),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              if (state.buyCoin != null &&
                  state.selectedOrder == null &&
                  state.bestOrders != null &&
                  state.bestOrders!.error == null)
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 12),
                  child: Text(
                    LocaleKeys.dexNoSwapOffers.tr(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BuyHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      DexFormGroupHeader(title: LocaleKeys.buy.tr());
}
