import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/model/swap.dart';
import 'package:web_dex/shared/utils/utils.dart';

/// A bounded, per-wallet copy of completed swaps for the History screen.
class SwapHistoryStorage {
  const SwapHistoryStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _key(WalletId walletId) =>
      'pirate_swap_history_v1_${walletId.compoundId}';

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
