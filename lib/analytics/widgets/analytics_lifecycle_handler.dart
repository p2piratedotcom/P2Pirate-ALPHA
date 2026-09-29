import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';

/// Keeps authentication health checks tied to application lifecycle changes.
class AnalyticsLifecycleHandler extends StatefulWidget {
  /// Creates an AnalyticsLifecycleHandler.
  ///
  /// The [child] parameter must not be null.
  const AnalyticsLifecycleHandler({super.key, required this.child});

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  State<AnalyticsLifecycleHandler> createState() =>
      _AnalyticsLifecycleHandlerState();
}

class _AnalyticsLifecycleHandlerState extends State<AnalyticsLifecycleHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    log('AnalyticsLifecycleHandler: App lifecycle state changed to $state');

    if (state == AppLifecycleState.resumed) {
      log(
        'AnalyticsLifecycleHandler: App resumed, triggering health check after backoff',
      );
      // Add 150ms backoff before health check to avoid race where native status
      // reports "running" but HTTP listener hasn't bound yet after iOS backgrounding
      Future.delayed(const Duration(milliseconds: 150), () {
        log(
          'AnalyticsLifecycleHandler: Backoff complete, checking auth status',
        );
        _checkAuthStatus();
      });
    }
  }

  void _checkAuthStatus() {
    try {
      context.read<AuthBloc>().add(const AuthLifecycleCheckRequested());
    } catch (e) {
      log('AnalyticsLifecycleHandler: Failed to check auth status - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
