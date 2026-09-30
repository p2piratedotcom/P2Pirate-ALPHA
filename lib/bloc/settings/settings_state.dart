import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/model/settings/market_maker_bot_settings.dart';
import 'package:web_dex/model/stored_settings.dart';

class SettingsState extends Equatable {
  const SettingsState({
    required this.themeMode,
    required this.mmBotSettings,
    required this.testCoinsEnabled,
    required this.weakPasswordsAllowed,
    required this.hideZeroBalanceAssets,
    required this.diagnosticLoggingEnabled,
    required this.hideBalances,
    required this.torEnabled,
    required this.showWalletUsdValues,
    required this.customPriceApiUrl,
  });

  factory SettingsState.fromStored(StoredSettings stored) {
    return SettingsState(
      themeMode: stored.mode,
      mmBotSettings: stored.marketMakerBotSettings,
      testCoinsEnabled: stored.testCoinsEnabled,
      weakPasswordsAllowed: stored.weakPasswordsAllowed,
      hideZeroBalanceAssets: stored.hideZeroBalanceAssets,
      diagnosticLoggingEnabled: stored.diagnosticLoggingEnabled,
      hideBalances: stored.hideBalances,
      torEnabled: stored.torEnabled,
      showWalletUsdValues: stored.showWalletUsdValues,
      customPriceApiUrl: stored.customPriceApiUrl,
    );
  }

  final ThemeMode themeMode;
  final MarketMakerBotSettings mmBotSettings;
  final bool testCoinsEnabled;
  final bool weakPasswordsAllowed;
  final bool hideZeroBalanceAssets;
  final bool diagnosticLoggingEnabled;
  final bool hideBalances;
  final bool torEnabled;
  final bool showWalletUsdValues;
  final String customPriceApiUrl;

  @override
  List<Object?> get props => [
    themeMode,
    mmBotSettings,
    testCoinsEnabled,
    weakPasswordsAllowed,
    hideZeroBalanceAssets,
    diagnosticLoggingEnabled,
    hideBalances,
    torEnabled,
    showWalletUsdValues,
    customPriceApiUrl,
  ];

  SettingsState copyWith({
    ThemeMode? mode,
    MarketMakerBotSettings? marketMakerBotSettings,
    bool? testCoinsEnabled,
    bool? weakPasswordsAllowed,
    bool? hideZeroBalanceAssets,
    bool? diagnosticLoggingEnabled,
    bool? hideBalances,
    bool? torEnabled,
    bool? showWalletUsdValues,
    String? customPriceApiUrl,
  }) {
    return SettingsState(
      themeMode: mode ?? themeMode,
      mmBotSettings: marketMakerBotSettings ?? mmBotSettings,
      testCoinsEnabled: testCoinsEnabled ?? this.testCoinsEnabled,
      weakPasswordsAllowed: weakPasswordsAllowed ?? this.weakPasswordsAllowed,
      hideZeroBalanceAssets:
          hideZeroBalanceAssets ?? this.hideZeroBalanceAssets,
      diagnosticLoggingEnabled:
          diagnosticLoggingEnabled ?? this.diagnosticLoggingEnabled,
      hideBalances: hideBalances ?? this.hideBalances,
      torEnabled: torEnabled ?? this.torEnabled,
      showWalletUsdValues: showWalletUsdValues ?? this.showWalletUsdValues,
      customPriceApiUrl: customPriceApiUrl ?? this.customPriceApiUrl,
    );
  }
}
