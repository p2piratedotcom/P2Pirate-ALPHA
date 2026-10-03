import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

/// Editing retains the saved route even when no markets are currently offered.
/// New orders can only use the markets reported by the engine.
List<String> makerOrderMarkets(
  Object? availableMarkets, {
  Map<String, dynamic>? existingSpec,
}) {
  final markets = <String>{
    if (availableMarkets is Map) ...availableMarkets.keys.whereType<String>(),
  };
  final base = existingSpec?['base'];
  final quote = existingSpec?['quote'];
  if (base is Map &&
      quote is Map &&
      base['ticker'] is String &&
      quote['ticker'] is String) {
    markets.add('${base['ticker']}-${quote['ticker']}');
  }
  return markets.toList();
}

/// Builds a protocol-1 strategy specification. The engine validates all
/// exchange limits, available balances and hedge coverage during preview.
class MmEngineStrategyForm extends StatefulWidget {
  const MmEngineStrategyForm({
    super.key,
    required this.markets,
    required this.strategyId,
    this.venues = const {'MEXC': 'MEXC', 'GATE': 'Gate'},
    this.initialSpec,
    this.availableBalances = const {},
  });

  final List<String> markets;
  final Map<String, String> venues;
  final String strategyId;
  final Map<String, dynamic>? initialSpec;
  final Map<String, String> availableBalances;

  @override
  State<MmEngineStrategyForm> createState() => _MmEngineStrategyFormState();
}

class _MmEngineStrategyFormState extends State<MmEngineStrategyForm> {
  final _form = GlobalKey<FormState>();
  final _baseAsset = TextEditingController(text: 'ARRR');
  final _quoteAsset = TextEditingController();
  final _premium = TextEditingController(text: '2');
  final _budget = TextEditingController();
  final _maxSold = TextEditingController();
  final _dailyCap = TextEditingController();
  final _fixedPrice = TextEditingController();
  final _fixedSold = TextEditingController();
  final _updateSeconds = TextEditingController(text: '60');
  String? _market;
  String _venue = 'MEXC';
  String _side = 'SELL_ARRR';
  bool _replenish = true;
  bool _autoPrice = true;
  bool _autoQuantity = true;

  @override
  void initState() {
    super.initState();
    _venue = widget.venues.containsKey('MEXC')
        ? 'MEXC'
        : widget.venues.keys.first;
    _market = widget.markets.isEmpty ? null : widget.markets.first;
    _updateRoute();
    final spec = widget.initialSpec;
    if (spec != null) {
      final base = spec['base'] as Map;
      final quote = spec['quote'] as Map;
      _market = '${base['ticker']}-${quote['ticker']}';
      _baseAsset.text = '${base['asset']}';
      _quoteAsset.text = '${quote['asset']}';
      _venue = '${spec['cex']}';
      _side = '${spec['side']}';
      _premium.text =
          (Decimal.parse('${spec['premium']}') * Decimal.fromInt(100))
              .toString();
      _autoPrice = spec['price_mode'] == 'auto';
      _autoQuantity = spec['quantity_mode'] == 'auto';
      _replenish = spec['replenish'] == true;
      for (final pair in [
        (_budget, 'total_sold_budget'),
        (_maxSold, 'max_sold'),
        (_dailyCap, 'daily_sold_cap'),
        (_fixedPrice, 'fixed_price'),
        (_fixedSold, 'fixed_sold'),
        (_updateSeconds, 'update_seconds'),
      ]) {
        pair.$1.text = spec[pair.$2]?.toString() ?? '';
      }
    }
  }

  void _updateRoute() {
    _baseAsset.text = _market?.split('-').first ?? '';
    final quote = _market?.split('-').skip(1).join('-') ?? '';
    _quoteAsset.text = quote == 'USDT-BEP20'
        ? 'USDT'
        : (quote.contains('-') ? '' : quote);
  }

  @override
  void dispose() {
    for (final controller in [
      _baseAsset,
      _quoteAsset,
      _premium,
      _budget,
      _maxSold,
      _dailyCap,
      _fixedPrice,
      _fixedSold,
      _updateSeconds,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _positive(String? raw, {bool required = true}) {
    final value = raw?.trim() ?? '';
    if (!required && value.isEmpty) return null;
    final number = double.tryParse(value);
    if (number == null || !number.isFinite || number <= 0) {
      return 'Enter a positive number';
    }
    return null;
  }

  String? _asset(String? raw) {
    final value = raw?.trim().toUpperCase() ?? '';
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value)) {
      return 'Enter the exact CEX Spot asset';
    }
    return null;
  }

  String? _premiumPercent(String? raw) {
    final value = double.tryParse(raw?.trim() ?? '');
    if (value == null || !value.isFinite || value.abs() >= 100) {
      return 'Enter a premium between -100% and 100%';
    }
    return null;
  }

  static const _help = <String, String>{
    'KDF market':
        'Wallet coin pair. Both coins must be active. Routing is locked when modifying an existing order.',
    'Base CEX asset':
        'Exact exchange asset code for the base wallet coin, for example ARRR. It may differ from the wallet ticker.',
    'Quote CEX asset':
        'Exact exchange asset code for the quote wallet coin, for example USDT for USDT-BEP20.',
    'Hedge exchange':
        'Exchange where the engine hedges completed KDF swaps. Requires Spot read and trading API permissions.',
    'KDF maker side':
        'Sell base spends base and receives quote; Buy base spends quote and receives base.',
    'Premium (%)':
        'Markup relative to the exchange reference price. Fees and risk limits also affect the final quote.',
    'Automatic price':
        'Recalculate KDF price from current exchange order books and the premium. Off uses a fixed quote-per-base price.',
    'Fixed KDF price':
        'Fixed quote coin units per one base coin. Exchange hedge and safety checks still apply.',
    'Automatic quantity':
        'Size each order from wallet funds, exchange hedge balances, market depth and budget limits.',
    'Fixed sold amount':
        'Amount of the coin you sell on KDF. Safety limits may reduce the publishable amount.',
    'Maximum sold per order (optional)':
        'Upper limit on the sold coin amount of each individual maker order. Empty leaves sizing to other limits.',
    'Total sold budget':
        'Lifetime sold-coin budget for this order configuration. Completed swaps consume it; modification does not reset consumption.',
    'Daily sold cap (optional)':
        'Maximum sold coin volume per day. Empty means no additional daily cap.',
    'Update interval (seconds)':
        'Minimum time between normal price or quantity updates. Safety pauses can happen sooner.',
    'Replenish within budget':
        'After fills, replenish maker orders while budget and safety checks permit. Off avoids replenishing consumed quantity.',
  };
  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    suffixIcon: Tooltip(
      message: _help[label]!,
      child: const Icon(Icons.help_outline, size: 18),
    ),
  );
  Widget _helpTitle(String label) => Row(
    children: [
      Flexible(child: Text(label)),
      const SizedBox(width: 8),
      Tooltip(
        message: _help[label]!,
        child: const Icon(Icons.help_outline, size: 18),
      ),
    ],
  );

  Widget _numberField(
    String label,
    TextEditingController controller, {
    bool required = true,
  }) => TextFormField(
    controller: controller,
    decoration: _decoration(label),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    validator: (value) => _positive(value, required: required),
  );

  void _submit() {
    if (!_form.currentState!.validate() || _market == null) return;
    final tickers = _market!.split('-');
    final baseTicker = tickers.first;
    final quoteTicker = tickers.skip(1).join('-');
    if (quoteTicker.isEmpty) return;
    final baseAsset = _baseAsset.text.trim().toUpperCase();
    final quoteAsset = _quoteAsset.text.trim().toUpperCase();
    final premiumPercent = Decimal.parse(_premium.text.trim());
    final spec = <String, Object?>{
      ...?(widget.initialSpec?.cast<String, Object?>()),
      'strategy_id': widget.strategyId,
      'base':
          widget.initialSpec?['base'] ??
          {
            'ticker': baseTicker,
            'asset': baseAsset,
            'symbol': '${baseAsset}USDT',
          },
      'quote':
          widget.initialSpec?['quote'] ??
          {
            'ticker': quoteTicker,
            'asset': quoteAsset,
            'symbol': quoteAsset == 'USDT' ? null : '${quoteAsset}USDT',
          },
      'side': _side,
      'premium': (premiumPercent / Decimal.fromInt(100)).toDecimal().toString(),
      'price_mode': _autoPrice ? 'auto' : 'fixed',
      'fixed_price': _autoPrice ? null : _fixedPrice.text.trim(),
      'quantity_mode': _autoQuantity ? 'auto' : 'fixed',
      'fixed_sold': _autoQuantity ? null : _fixedSold.text.trim(),
      'max_sold': _maxSold.text.trim().isEmpty ? null : _maxSold.text.trim(),
      'replenish': _replenish,
      'total_sold_budget': _budget.text.trim(),
      'daily_sold_cap': _dailyCap.text.trim().isEmpty
          ? null
          : _dailyCap.text.trim(),
      'impact': widget.initialSpec?['impact'] ?? '0.01',
      'depth_fraction': widget.initialSpec?['depth_fraction'] ?? '0.50',
      'quantity_threshold': widget.initialSpec?['quantity_threshold'] ?? '0.10',
      'price_threshold': widget.initialSpec?['price_threshold'] ?? '0.0025',
      'update_seconds': _updateSeconds.text.trim(),
      'confirmations': widget.initialSpec?['confirmations'] ?? 3,
      'scale_group': widget.initialSpec?['scale_group'] ?? '',
      'auto_fraction': widget.initialSpec?['auto_fraction'] ?? '1',
      'cex': _venue,
    };
    Navigator.of(context).pop(spec);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.initialSpec == null ? 'New Maker Order' : 'Modify Maker Order',
    ),
    content: SizedBox(
      width: 520,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _market,
                decoration: _decoration('KDF market'),
                items:
                    {
                          ...widget.markets,
                          if (widget.initialSpec != null && _market != null)
                            _market!,
                        }
                        .map(
                          (market) => DropdownMenuItem(
                            value: market,
                            child: Text(market),
                          ),
                        )
                        .toList(),
                onChanged: widget.initialSpec != null
                    ? null
                    : (value) => setState(() {
                        _market = value;
                        _updateRoute();
                      }),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _baseAsset,
                      decoration: _decoration('Base CEX asset'),
                      readOnly: widget.initialSpec != null,
                      validator: _asset,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _quoteAsset,
                      decoration: _decoration('Quote CEX asset'),
                      readOnly: widget.initialSpec != null,
                      validator: _asset,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _venue,
                decoration: _decoration('Hedge exchange'),
                items: [
                  for (final entry in widget.venues.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(
                        entry.value.toLowerCase().endsWith('spot')
                            ? entry.value
                            : '${entry.value} Spot',
                      ),
                    ),
                ],
                onChanged: widget.initialSpec != null
                    ? null
                    : (value) => setState(() => _venue = value ?? _venue),
              ),
              DropdownButtonFormField<String>(
                initialValue: _side,
                decoration: _decoration('KDF maker side'),
                items: const [
                  DropdownMenuItem(
                    value: 'SELL_ARRR',
                    child: Text('Sell base'),
                  ),
                  DropdownMenuItem(value: 'BUY_ARRR', child: Text('Buy base')),
                ],
                onChanged: widget.initialSpec != null
                    ? null
                    : (value) => setState(() => _side = value ?? 'SELL_ARRR'),
              ),
              TextFormField(
                controller: _premium,
                decoration: _decoration('Premium (%)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                validator: _premiumPercent,
              ),
              SwitchListTile(
                title: _helpTitle('Automatic price'),
                value: _autoPrice,
                onChanged: (value) => setState(() => _autoPrice = value),
              ),
              if (!_autoPrice) _numberField('Fixed KDF price', _fixedPrice),
              SwitchListTile(
                title: _helpTitle('Automatic quantity'),
                value: _autoQuantity,
                onChanged: (value) => setState(() => _autoQuantity = value),
              ),
              Tooltip(
                message:
                    'Spendable base coin in the wallet, refreshed when this form opens. Hedge capacity is checked separately in preview.',
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Available base coin: ${widget.availableBalances[_market?.split('-').first] ?? 'unavailable'} ${_market?.split('-').first ?? ''}',
                    ),
                  ),
                ),
              ),
              if (!_autoQuantity) _numberField('Fixed sold amount', _fixedSold),
              _numberField(
                'Maximum sold per order (optional)',
                _maxSold,
                required: false,
              ),
              _numberField('Total sold budget', _budget),
              _numberField(
                'Daily sold cap (optional)',
                _dailyCap,
                required: false,
              ),
              _numberField('Update interval (seconds)', _updateSeconds),
              SwitchListTile(
                title: _helpTitle('Replenish within budget'),
                value: _replenish,
                onChanged: (value) => setState(() => _replenish = value),
              ),
              const Text(
                'The engine will preview exchange depth, balances and hedge '
                'coverage before saving. The strategy remains paused.',
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      Tooltip(
        message: 'Close without saving or publishing.',
        child: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
      Tooltip(
        message:
            'Read market depth and balances, validate hedge capacity and show the proposed order. This does not publish it.',
        child: ElevatedButton(onPressed: _submit, child: const Text('Preview')),
      ),
    ],
  );
}
