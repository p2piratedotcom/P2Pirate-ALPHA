import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/blocs/trading_entities_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class SwapRecoverButton extends StatefulWidget {
  const SwapRecoverButton({super.key, required this.uuid});

  final String uuid;

  @override
  State<SwapRecoverButton> createState() => _SwapRecoverButtonState();
}

class _SwapRecoverButtonState extends State<SwapRecoverButton> {
  bool _isLoading = false;
  bool _resultUnconfirmed = false;

  @override
  Widget build(BuildContext context) {
    final bloc = RepositoryProvider.of<TradingEntitiesBloc>(context);
    return StreamBuilder<void>(
      stream: bloc.outRecoveries,
      builder: (context, _) {
        if (bloc.isRecoveryConfirmed(widget.uuid)) {
          return const SizedBox.shrink();
        }
        if (bloc.isRecoveryPending(widget.uuid)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LocaleKeys.swapRecoveryInProgress.tr(),
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 6),
              Text(LocaleKeys.swapRecoverButtonSuccessMessage.tr()),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(LocaleKeys.swapRecoverButtonTitle.tr()),
            const SizedBox(height: 10),
            UiPrimaryButton(
              text: LocaleKeys.swapRecoverButtonText.tr(),
              onPressed: _isLoading ? null : () => _recover(bloc),
            ),
            if (_resultUnconfirmed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  LocaleKeys.swapRecoveryUnconfirmed.tr(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _recover(TradingEntitiesBloc bloc) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _resultUnconfirmed = false;
    });
    try {
      final response = await bloc.recoverFundsOfSwap(widget.uuid);
      if (!mounted) return;
      setState(() => _resultUnconfirmed = response == null);
    } catch (_) {
      if (!mounted) return;
      setState(() => _resultUnconfirmed = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
