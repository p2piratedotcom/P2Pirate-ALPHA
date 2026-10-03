/// The live permission and the decision to publish individual maker orders are
/// separate. All requests still use the engine's authenticated API.
typedef MmEngineControlRequest =
    Future<Map<String, dynamic>> Function(
      String method,
      String path, {
      required Map<String, Object?> body,
    });

const mmEngineStartLiveNotice =
    'P2Pirate Trading Engine can publish funded KDF maker orders and place real '
    'hedges on the selected CEX. Starting live mode keeps all orders paused. '
    'Select the orders you want and press Start selected orders to activate them. '
    'Check balances, CEX API permissions and order limits first. '
    'Orders you explicitly start may resume when you next open this wallet.';

Set<String> startableMakerOrderIds(
  List<Map<String, dynamic>> strategies,
  List<Map<String, dynamic>> orders,
) {
  final active = orders.map((order) => order['strategy_id']).toSet();
  return {
    for (final row in strategies)
      if (row['id'] is String &&
          row['enabled'] == 0 &&
          row['state'] == 'PAUSED' &&
          !active.contains(row['id']))
        row['id'] as String,
  };
}

Future<void> switchMmEngineTradingMode({
  required bool enabled,
  required MmEngineControlRequest request,
  required Future<void> Function() stop,
  required Future<void> Function(bool enabled) start,
  required Future<void> Function() clearLivePreference,
}) async {
  // Pause persisted configurations BEFORE restarting with publication enabled.
  // Pausing after startup would allow the worker to publish during startup.
  await request(
    'POST',
    '/v1/strategies/pause-all',
    body: {'confirmation': 'PAUSA TUTTE'},
  );
  await stop();
  if (!enabled) await clearLivePreference();
  await start(enabled);
}

class MmEngineActivationResult {
  const MmEngineActivationResult(this.started, this.error);
  final Set<String> started;
  final Object? error;
}

Future<MmEngineActivationResult> startSelectedMakerOrders({
  required List<String> ids,
  required Set<String> eligible,
  required bool live,
  required MmEngineControlRequest request,
}) async {
  if (!live) throw StateError('Start live trading before activating orders.');
  final unique = ids.toSet();
  if (unique.isEmpty || !eligible.containsAll(unique)) {
    throw StateError(
      'Select only paused maker orders that are ready to start.',
    );
  }
  final started = <String>{};
  for (final id in unique) {
    try {
      await request(
        'POST',
        '/v1/strategies/start',
        body: {'strategy_id': id, 'confirmation': 'AVVIA $id'},
      );
      started.add(id);
    } catch (error) {
      // Existing API performs one activation at a time. Expose partial success
      // and stop sending further requests rather than claiming atomic success.
      return MmEngineActivationResult(started, error);
    }
  }
  return MmEngineActivationResult(started, null);
}
