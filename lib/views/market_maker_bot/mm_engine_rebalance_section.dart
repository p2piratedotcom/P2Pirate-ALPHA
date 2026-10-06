import 'mm_engine_balance_source.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_balance_refresh.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_rebalance_panel.dart';

/// Independent venue, balance display and collapse state from MY CEXs.
class MmEngineRebalanceSection extends StatefulWidget {
  const MmEngineRebalanceSection({
    super.key,
    required this.venues,
    required this.balanceSource,
    required this.credentials,
    required this.strategies,
    required this.busy,
    required this.live,
    required this.onBusy,
    required this.onChanged,
    required this.onConfigure,
    this.credentialsLoading = false,
  });
  final Map<String, String> venues;
  final MmEngineBalanceSource balanceSource;
  final Map credentials;
  final List<Map<String, dynamic>> strategies;
  final bool busy, live;
  final bool credentialsLoading;
  final ValueChanged<bool> onBusy;
  final VoidCallback onChanged;
  final ValueChanged<String>? onConfigure;
  @override
  State<MmEngineRebalanceSection> createState() =>
      _MmEngineRebalanceSectionState();
}

class _MmEngineRebalanceSectionState extends State<MmEngineRebalanceSection> {
  late final MmEngineBalanceRefresh _balances;
  @override
  void initState() {
    super.initState();
    _balances = MmEngineBalanceRefresh(
      shared: widget.balanceSource,
      viewKey: 'rebalance',
      initialVenue: widget.venues.containsKey('MEXC') || widget.venues.isEmpty
          ? 'MEXC'
          : widget.venues.keys.first,
    )..addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(widget.balanceSource.refresh(_balances.venue, force: false));
      }
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _balances.removeListener(_changed);
    _balances.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final venue = _balances.venue;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'CEX REBALANCE',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.busy ? null : _balances.toggleExpanded,
                  icon: Icon(
                    _balances.expanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  label: Text(_balances.expanded ? 'Hide' : 'Show'),
                ),
              ],
            ),
            Visibility(
              visible: _balances.expanded,
              maintainState: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (final entry in widget.venues.entries)
                        ChoiceChip(
                          label: Text(entry.value),
                          selected: venue == entry.key,
                          showCheckmark: false,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          onSelected: widget.busy || _balances.loading
                              ? null
                              : (_) => _balances.selectVenue(entry.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  if (widget.credentialsLoading)
                    const Text('Checking saved CEX configuration…'),
                  if (!widget.credentialsLoading &&
                      widget.credentials[venue] != true)
                    TextButton(
                      onPressed: widget.busy || widget.onConfigure == null
                          ? null
                          : () => widget.onConfigure!(venue),
                      child: Text('Configure $venue API credentials'),
                    ),
                  OverflowBar(
                    alignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ListenableBuilder(
                        listenable: _balances.clock,
                        builder: (context, child) => Text(
                          _balances.loading
                              ? 'Refreshing $venue balances…'
                              : 'Next balance refresh in ${_balances.secondsRemaining}s',
                        ),
                      ),
                      TextButton.icon(
                        onPressed: widget.busy || _balances.loading
                            ? null
                            : _balances.refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh balances'),
                      ),
                    ],
                  ),
                  if (_balances.updatedAt != null)
                    Text(
                      'Last received: ${_balances.updatedAt!.toLocal().toIso8601String().split('.').first.replaceAll('T', ' ')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (_balances.loading) const LinearProgressIndicator(),
                  if (_balances.error != null)
                    SelectableText(
                      _balances.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 20),
                  MmEngineRebalancePanel(
                    key: ValueKey(venue),
                    venue: venue,
                    busy: widget.busy,
                    live: widget.live,
                    configured: widget.credentials[venue] == true,
                    strategies: widget.strategies,
                    balances: _balances.balances,
                    balanceLoading: _balances.loading,
                    onBusy: widget.onBusy,
                    onChanged: () {
                      widget.onChanged();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
