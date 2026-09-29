import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/taker_form/taker_bloc.dart';
import 'package:web_dex/bloc/taker_form/taker_state.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/views/dex/simple/confirm/taker_order_confirmation.dart';
import 'package:web_dex/views/dex/simple/form/tables/coins_table/taker_sell_coins_table.dart';
import 'package:web_dex/views/dex/simple/form/tables/orders_table/taker_orders_table.dart';
import 'package:web_dex/views/dex/simple/form/taker/taker_form_content.dart';
import 'package:web_dex/views/dex/simple/form/taker/coin_item/taker_form_buy_item.dart';
import 'package:web_dex/views/dex/simple/form/taker/coin_item/taker_form_sell_item.dart';
import 'package:web_dex/views/dex/simple/form/common/dex_flip_button.dart';
import 'package:web_dex/views/dex/simple/form/common/swap_desktop_scroll_area.dart';
import 'package:web_dex/views/dex/common/section_switcher.dart';
import 'package:web_dex/views/dex/simple/form/taker/taker_order_book.dart';

class TakerFormLayout extends StatelessWidget {
  const TakerFormLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TakerBloc, TakerState, TakerStep>(
      selector: (state) => state.step,
      builder: (context, step) {
        return step == TakerStep.confirm
            ? const TakerOrderConfirmation()
            : isMobile
            ? const _TakerFormMobileLayout()
            : _TakerFormDesktopLayout();
      },
    );
  }
}

class _TakerFormDesktopLayout extends StatefulWidget {
  @override
  State<_TakerFormDesktopLayout> createState() =>
      _TakerFormDesktopLayoutState();
}

class _TakerFormDesktopLayoutState extends State<_TakerFormDesktopLayout> {
  late final ScrollController _mainScrollController;

  @override
  void initState() {
    super.initState();
    _mainScrollController = ScrollController();
    _mainScrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _mainScrollController.removeListener(_onScroll);
    _mainScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Dismiss keyboard when user starts scrolling
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth - swapDesktopScrollbarGutter;
        final narrow = contentWidth < 800;
        final selectorWidth = narrow
            ? contentWidth - 32
            : (contentWidth - 88) / 2;
        return SwapDesktopScrollArea(
          controller: _mainScrollController,
          scrollViewKey: const Key('taker-form-layout-scroll'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionSwitcher(),
                  const SizedBox(height: 12),
                  if (narrow) ...[
                    const TakerFormSellItem(),
                    DexFlipButton(onTap: () => flipTakerPair(context)),
                    const TakerFormBuyItem(),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(child: TakerFormSellItem()),
                        const SizedBox(width: 8),
                        DexFlipButton(onTap: () => flipTakerPair(context)),
                        const SizedBox(width: 8),
                        const Expanded(child: TakerFormBuyItem()),
                      ],
                    ),
                  const SizedBox(height: 18),
                  const TakerOrderbook(splitSides: true),
                  const SizedBox(height: 20),
                  const Center(child: TakerFormDesktopControls()),
                  const SizedBox(height: 24),
                ],
              ),
              Positioned(
                top: 44,
                left: 16,
                width: selectorWidth,
                child: TakerSellCoinsTable(),
              ),
              Positioned(
                top: narrow ? 184 : 44,
                right: 16,
                width: selectorWidth,
                child: TakerOrdersTable(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TakerFormMobileLayout extends StatefulWidget {
  const _TakerFormMobileLayout();

  @override
  State<_TakerFormMobileLayout> createState() => _TakerFormMobileLayoutState();
}

class _TakerFormMobileLayoutState extends State<_TakerFormMobileLayout> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Dismiss keyboard when user starts scrolling
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: theme.custom.dexFormWidth),
        child: Stack(
          children: [
            const Column(
              children: [
                TakerFormContent(),
                SizedBox(height: 22),
                TakerOrderbook(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 52, 16, 0),
              child: TakerSellCoinsTable(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 167, 16, 0),
              child: TakerOrdersTable(),
            ),
          ],
        ),
      ),
    );
  }
}
