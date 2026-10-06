part of 'portfolio_growth_bloc.dart';

sealed class PortfolioGrowthEvent extends Equatable {
  const PortfolioGrowthEvent();

  @override
  List<Object> get props => [];
}

class PortfolioGrowthClearRequested extends PortfolioGrowthEvent {
  const PortfolioGrowthClearRequested();
}

class PortfolioGrowthSessionChanged extends PortfolioGrowthEvent {
  const PortfolioGrowthSessionChanged(this.walletId);
  final String? walletId;
  @override
  List<Object> get props => [walletId ?? ''];
}

class PortfolioGrowthViewChanged extends PortfolioGrowthEvent {
  const PortfolioGrowthViewChanged(this.owner, this.visible);
  final Object owner;
  final bool visible;
  @override
  List<Object> get props => [owner, visible];
}

class PortfolioGrowthLoadRequested extends PortfolioGrowthEvent {
  const PortfolioGrowthLoadRequested({
    required this.coins,
    required this.fiatCoinId,
    required this.selectedPeriod,
    required this.walletId,
  });

  final List<Coin> coins;
  final String fiatCoinId;
  final Duration selectedPeriod;
  final String walletId;

  @override
  List<Object> get props => [coins, fiatCoinId, selectedPeriod, walletId];
}

class PortfolioGrowthPeriodChanged extends PortfolioGrowthEvent {
  const PortfolioGrowthPeriodChanged({
    required this.selectedPeriod,
    required this.coins,
    required this.walletId,
  });

  final Duration selectedPeriod;
  final List<Coin> coins;
  final String walletId;

  @override
  List<Object> get props => [selectedPeriod, coins, walletId];
}
