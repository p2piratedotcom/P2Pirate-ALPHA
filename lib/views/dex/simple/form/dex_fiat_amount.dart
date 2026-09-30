import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/utils/formatters.dart';

class DexFiatAmount extends StatelessWidget {
  const DexFiatAmount({
    super.key,
    required this.coin,
    required this.amount,
    this.padding,
    this.textStyle,
  });

  final Coin? coin;
  final Rational? amount;
  final EdgeInsets? padding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final Rational estAmount = amount ?? Rational.zero;
    if (!context.watch<SettingsBloc>().state.showWalletUsdValues) {
      return const SizedBox.shrink();
    }
    final state = context.watch<CoinsBloc>().state;
    final usdPrice = coin == null
        ? null
        : state.getPriceForAsset(coin!.id)?.price?.toDouble();
    final fiatAmount = usdPrice == null
        ? null
        : estAmount.toDouble() * usdPrice;
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text(
        fiatAmount == null ? 'N/A' : '~ \$${formatAmt(fiatAmount)}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: theme.custom.fiatAmountColor,
        ).merge(textStyle),
      ),
    );
  }
}
