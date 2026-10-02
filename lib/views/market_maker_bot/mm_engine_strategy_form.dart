import 'package:flutter/material.dart';

/// Builds a protocol-1 strategy specification. The engine validates all
/// exchange limits, available balances and hedge coverage during preview.
class MmEngineStrategyForm extends StatefulWidget {
  const MmEngineStrategyForm({super.key, required this.markets});

  final List<String> markets;

  @override
  State<MmEngineStrategyForm> createState() => _MmEngineStrategyFormState();
}

class _MmEngineStrategyFormState extends State<MmEngineStrategyForm> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
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
    _market = widget.markets.isEmpty ? null : widget.markets.first;
    _updateRoute();
  }

  void _updateRoute() {
    final quote = _market?.split('-').skip(1).join('-') ?? '';
    _quoteAsset.text = quote == 'USDT-BEP20'
        ? 'USDT'
        : (quote.contains('-') ? '' : quote);
  }

  @override
  void dispose() {
    for (final controller in [
      _id,
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

  Widget _numberField(
    String label,
    TextEditingController controller, {
    bool required = true,
  }) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
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
    final premiumPercent = double.parse(_premium.text.trim());
    final spec = <String, Object?>{
      'strategy_id': _id.text.trim(),
      'base': {
        'ticker': baseTicker,
        'asset': baseAsset,
        'symbol': '${baseAsset}USDT',
      },
      'quote': {
        'ticker': quoteTicker,
        'asset': quoteAsset,
        'symbol': quoteAsset == 'USDT' ? null : '${quoteAsset}USDT',
      },
      'side': _side,
      'premium': (premiumPercent / 100).toStringAsFixed(6),
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
      'impact': '0.01',
      'depth_fraction': '0.50',
      'quantity_threshold': '0.10',
      'price_threshold': '0.0025',
      'update_seconds': _updateSeconds.text.trim(),
      'confirmations': 3,
      'scale_group': '',
      'auto_fraction': '1',
      'cex': _venue,
    };
    Navigator.of(context).pop(spec);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('New maker strategy'),
    content: SizedBox(
      width: 520,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _id,
                decoration: const InputDecoration(labelText: 'Strategy name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty || value.length > 100
                    ? 'Enter a name (max 100 characters)'
                    : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: _market,
                decoration: const InputDecoration(labelText: 'KDF market'),
                items: widget.markets
                    .map(
                      (market) =>
                          DropdownMenuItem(value: market, child: Text(market)),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _market = value;
                  _updateRoute();
                }),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _baseAsset,
                      decoration: const InputDecoration(
                        labelText: 'Base CEX asset',
                      ),
                      validator: _asset,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _quoteAsset,
                      decoration: const InputDecoration(
                        labelText: 'Quote CEX asset',
                      ),
                      validator: _asset,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _venue,
                decoration: const InputDecoration(labelText: 'Hedge exchange'),
                items: const [
                  DropdownMenuItem(value: 'MEXC', child: Text('MEXC Spot')),
                  DropdownMenuItem(value: 'GATE', child: Text('Gate Spot')),
                ],
                onChanged: (value) => setState(() => _venue = value ?? 'MEXC'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _side,
                decoration: const InputDecoration(labelText: 'KDF maker side'),
                items: const [
                  DropdownMenuItem(
                    value: 'SELL_ARRR',
                    child: Text('Sell base'),
                  ),
                  DropdownMenuItem(value: 'BUY_ARRR', child: Text('Buy base')),
                ],
                onChanged: (value) =>
                    setState(() => _side = value ?? 'SELL_ARRR'),
              ),
              TextFormField(
                controller: _premium,
                decoration: const InputDecoration(labelText: 'Premium (%)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                validator: _premiumPercent,
              ),
              SwitchListTile(
                title: const Text('Automatic price'),
                value: _autoPrice,
                onChanged: (value) => setState(() => _autoPrice = value),
              ),
              if (!_autoPrice) _numberField('Fixed KDF price', _fixedPrice),
              SwitchListTile(
                title: const Text('Automatic quantity'),
                value: _autoQuantity,
                onChanged: (value) => setState(() => _autoQuantity = value),
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
                title: const Text('Replenish within budget'),
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
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      ElevatedButton(onPressed: _submit, child: const Text('Preview')),
    ],
  );
}
