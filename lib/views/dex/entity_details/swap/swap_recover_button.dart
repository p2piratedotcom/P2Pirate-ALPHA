import 'dart:async';

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
  Timer? _reviewTimer;

  @override
  void initState() {
    super.initState();
    _reviewTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _reviewTimer?.cancel();
    super.dispose();
  }

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
              if (!bloc.isRecoverySubmitting(widget.uuid))
                Text(LocaleKeys.swapRecoverButtonSuccessMessage.tr()),
              if (bloc.canReviewRecovery(widget.uuid))
                TextButton(
                  onPressed: () => _reviewPendingRecovery(bloc),
                  child: const Text('Review pending recovery'),
                ),
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

  Future<void> _reviewPendingRecovery(TradingEntitiesBloc bloc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Review recovery transaction'),
        content: const Text(
          'Check the wallet and transaction explorer first. If the recovery transaction is still pending, retrying could broadcast a duplicate. P2Pirate will also check recent KDF history before unlocking recovery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('I checked; review status'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final unlocked = await bloc.reviewPendingRecovery(widget.uuid);
    if (mounted && !unlocked) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text(
            'Recovery remains locked: its transaction is visible or its status could not be checked.',
          ),
        ),
      );
    }
  }
}
