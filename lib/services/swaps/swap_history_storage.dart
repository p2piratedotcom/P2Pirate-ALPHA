import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/model/swap.dart';
import 'package:web_dex/shared/utils/utils.dart';

class SwapRecoveryReceipt {
  const SwapRecoveryReceipt({
    required this.coin,
    required this.txHash,
    required this.confirmed,
  });

  final String coin;
  final String txHash;
  final bool confirmed;

  Map<String, dynamic> toJson() => {
    'coin': coin,
    'tx_hash': txHash,
    'confirmed': confirmed,
  };

  static SwapRecoveryReceipt? fromJson(Object? value) {
    if (value is! Map) return null;
    final coin = value['coin'];
    final txHash = value['tx_hash'];
    if (coin is! String ||
        txHash is! String ||
        coin.isEmpty ||
        txHash.isEmpty) {
      return null;
    }
    return SwapRecoveryReceipt(
      coin: coin,
      txHash: txHash,
      confirmed: value['confirmed'] == true,
    );
  }
}

/// A bounded, per-wallet copy of completed swaps for the History screen.
class SwapHistoryStorage {
  const SwapHistoryStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _key(WalletId walletId) =>
      'pirate_swap_history_v1_${walletId.compoundId}';
  String _recoveryKey(WalletId walletId) =>
      'pirate_swap_recovery_v1_${walletId.compoundId}';

  Future<Map<String, SwapRecoveryReceipt>> readRecoveries(
    WalletId walletId,
  ) async {
    final raw = await _storage.read(key: _recoveryKey(walletId));
    if (raw == null) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    final receipts = <String, SwapRecoveryReceipt>{};
    for (final entry in decoded.entries) {
      if (entry.key is! String) continue;
      final receipt = SwapRecoveryReceipt.fromJson(entry.value);
      if (receipt != null) receipts[entry.key as String] = receipt;
    }
    return receipts;
  }

  Future<void> writeRecoveries(
    WalletId walletId,
    Map<String, SwapRecoveryReceipt> recoveries,
  ) => _storage.write(
    key: _recoveryKey(walletId),
    value: jsonEncode(
      recoveries.map((uuid, receipt) => MapEntry(uuid, receipt.toJson())),
    ),
  );

  Future<List<Swap>> read(WalletId walletId) async {
    final raw = await _storage.read(key: _key(walletId));
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    final swaps = <Swap>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      try {
        swaps.add(Swap.fromJson(item));
      } catch (_) {
        // A damaged record must not hide the rest of the saved history.
      }
    }
    return swaps;
  }

  Future<void> write(WalletId walletId, List<Swap> swaps) => _storage.write(
    key: _key(walletId),
    value: jsonEncode(swaps.take(500).map(_cacheSwap).toList()),
  );

  Map<String, dynamic> _cacheSwap(Swap swap) => {
    'type': swap.isTaker ? 'Taker' : 'Maker',
    'uuid': swap.uuid,
    'my_order_uuid': swap.myOrderUuid,
    'events': swap.events
        .map(
          (event) => {
            'timestamp': event.timestamp,
            'event': {'type': event.event.type},
          },
        )
        .toList(),
    'maker_amount_fraction': rat2fract(swap.makerAmount),
    'maker_coin': swap.makerCoin,
    'taker_amount_fraction': rat2fract(swap.takerAmount),
    'taker_coin': swap.takerCoin,
    'success_events': swap.successEvents,
    'error_events': swap.errorEvents,
    'recoverable': swap.recoverable,
    if (swap.myInfo != null)
      'my_info': {
        'my_coin': swap.myInfo!.myCoin,
        'other_coin': swap.myInfo!.otherCoin,
        'my_amount': swap.myInfo!.myAmount.toString(),
        'other_amount': swap.myInfo!.otherAmount.toString(),
        'started_at': swap.myInfo!.startedAt,
      },
  };
}
