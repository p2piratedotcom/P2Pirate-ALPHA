import 'package:decimal/decimal.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/model/coin.dart';

class WalletUsdValuation {
  const WalletUsdValuation({
    required this.knownTotal,
    required this.hasMissingPrices,
    required this.hasMissingBalances,
  });

  final double? knownTotal;
  final bool hasMissingPrices;
  final bool hasMissingBalances;

  bool get isPartial => hasMissingPrices || hasMissingBalances;

  String? get partialLabel {
    if (hasMissingPrices) return 'partial, some prices not available';
    if (hasMissingBalances) return 'partial, some balances not available';
    return null;
  }
}

double? coinUsdValue(Coin coin, KomodoDefiSdk sdk, CoinsState state) {
  final balance = coin.lastKnownBalance(sdk)?.spendable;
  final price = state.getPriceForAsset(coin.id)?.price;
  if (balance == null || price == null || price <= Decimal.zero) return null;
  return (balance * price).toDouble();
}

WalletUsdValuation walletUsdValuation(
  Iterable<Coin> coins,
  KomodoDefiSdk sdk,
  CoinsState state,
) {
  return calculateKnownUsdTotal(
    coins
        .where((coin) => !coin.isTestCoin)
        .map(
          (coin) => (
            balance: coin.lastKnownBalance(sdk)?.spendable,
            price: state.getPriceForAsset(coin.id)?.price,
          ),
        ),
  );
}

WalletUsdValuation calculateKnownUsdTotal(
  Iterable<({Decimal? balance, Decimal? price})> holdings,
) {
  var total = 0.0;
  var hasKnownValue = false;
  var hasMissingPrices = false;
  var hasMissingBalances = false;

  for (final holding in holdings) {
    final balance = holding.balance;
    if (balance == null) {
      hasMissingBalances = true;
      continue;
    }
    if (balance == Decimal.zero) {
      hasKnownValue = true;
      continue;
    }
    final price = holding.price;
    if (price == null || price <= Decimal.zero) {
      hasMissingPrices = true;
      continue;
    }
    total += (balance * price).toDouble();
    hasKnownValue = true;
  }

  return WalletUsdValuation(
    knownTotal: hasKnownValue
        ? (total > 0 && total < 0.01 ? 0.01 : total)
        : null,
    hasMissingPrices: hasMissingPrices,
    hasMissingBalances: hasMissingBalances,
  );
}
