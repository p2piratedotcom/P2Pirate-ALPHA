import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/bloc/settings/settings_event.dart';
import 'package:web_dex/bloc/settings/settings_state.dart';
import 'package:web_dex/mm2/mm2.dart';
import 'package:web_dex/views/settings/widgets/common/settings_section.dart';

class SettingsMarketPrices extends StatefulWidget {
  const SettingsMarketPrices({super.key});

  @override
  State<SettingsMarketPrices> createState() => _SettingsMarketPricesState();
}

class _SettingsMarketPricesState extends State<SettingsMarketPrices> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: context.read<SettingsBloc>().state.customPriceApiUrl,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String? _validateUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return 'Enter a public HTTPS URL without embedded credentials';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final url = _urlController.text.trim();
    if (url == context.read<SettingsBloc>().state.customPriceApiUrl) return;
    context.read<SettingsBloc>().add(CustomPriceApiUrlChanged(url));
    setState(() => _testResult = null);
  }

  Future<void> _testApi() async {
    if (!_formKey.currentState!.validate()) return;
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final prices = await KomodoPriceProvider(
        mainTickersUrl: url,
      ).getKomodoPrices();
      if (!mounted) return;
      setState(() {
        _testResult = prices.isEmpty
            ? 'No tickers returned by this API'
            : '${prices.length} tickers available';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _testResult = 'API unavailable or response is invalid');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Market prices',
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UiSwitcher(
                  key: const Key('show-wallet-usd-values'),
                  value: state.showWalletUsdValues,
                  onChanged: (enabled) => context.read<SettingsBloc>().add(
                    ShowWalletUsdValuesChanged(enabled),
                  ),
                ),
                const SizedBox(width: 15),
                const Flexible(child: Text('Show USD values in Wallet')),
              ],
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Form(
                key: _formKey,
                child: TextFormField(
                  key: const Key('custom-price-api-url'),
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Price API URL',
                    hintText: 'https://example.org/api/v2/tickers',
                    helperText:
                        'Blank: automatic sources. Custom: ticker JSON.',
                  ),
                  validator: _validateUrl,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(onPressed: _save, child: const Text('Save')),
                TextButton(
                  onPressed: () {
                    _urlController.clear();
                    _save();
                  },
                  child: const Text('Use automatic sources'),
                ),
                OutlinedButton.icon(
                  onPressed: _testing ? null : _testApi,
                  icon: const Icon(Icons.network_check),
                  label: const Text('Test API'),
                ),
              ],
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 8),
              Text(_testResult!),
            ],
            if (state.customPriceApiUrl != mm2.configuredPriceApiUrl) ...[
              const SizedBox(height: 8),
              const Text('Restart P2Pirate to use the saved price API.'),
            ],
          ],
        ),
      ),
    );
  }
}
