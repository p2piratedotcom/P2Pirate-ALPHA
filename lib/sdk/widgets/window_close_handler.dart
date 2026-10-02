import 'dart:io'
    if (dart.library.js_interop) 'window_close_handler_exit_stub.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:get_it/get_it.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/mm2/mm2.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/services/mm_engine/mm_engine_service.dart';
import 'package:web_dex/services/tor/pirate_tor_service.dart';
import 'package:web_dex/shared/utils/platform_tuner.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/utils/window/window.dart';

/// A widget that handles window close events and SDK disposal across all platforms.
///
/// This widget uses different strategies based on the platform:
/// - Desktop (Windows, macOS, Linux): Uses flutter_window_close for native window close handling
///   On Linux, native code uses workaround to bypass GTK cleanup to prevent crashes
/// - Web: Uses showMessageBeforeUnload for browser beforeunload event
/// - Mobile (iOS, Android): Uses WidgetsBindingObserver for lifecycle management
///   and PopScope for exit confirmation
///
/// In all cases, it ensures the SDK is properly disposed when the app is closed.
class WindowCloseHandler extends StatefulWidget {
  /// Creates a WindowCloseHandler.
  ///
  /// The [child] parameter must not be null.
  const WindowCloseHandler({super.key, required this.child});

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  State<WindowCloseHandler> createState() => _WindowCloseHandlerState();
}

class _WindowCloseHandlerState extends State<WindowCloseHandler>
    with WidgetsBindingObserver {
  static _WindowCloseHandlerState? _registeredDesktopHandler;

  /// Share one shutdown across repeated window-close events.
  Future<void>? _shutdown;

  @override
  void initState() {
    super.initState();
    _setupCloseHandler();
  }

  /// Sets up the appropriate close handler based on the platform.
  void _setupCloseHandler() {
    if (PlatformTuner.isNativeDesktop) {
      _registeredDesktopHandler = this;
      // Desktop platforms: Use flutter_window_close for all platforms
      // On Linux, we use flutter_window_close for dialog, but return false to prevent
      // standard window closing, then manually trigger exit via SystemNavigator
      FlutterWindowClose.setWindowShouldCloseHandler(() async {
        final shouldClose = await _handleWindowClose();

        // On Linux, if user confirmed, we need to manually exit instead of letting
        // flutter_window_close handle it, to avoid GTK cleanup issues
        if (!kIsWeb &&
            defaultTargetPlatform == TargetPlatform.linux &&
            shouldClose) {
          // Hide window immediately
          // Then exit after a short delay to allow any final cleanup
          Future.delayed(const Duration(milliseconds: 200), () {
            exit(0);
          });
          // Return false to prevent flutter_window_close from closing the window
          return false;
        }

        return shouldClose;
      });
    } else if (kIsWeb) {
      // Web platform: Use beforeunload event
      showMessageBeforeUnload(
        'This will close P2Pirate and stop all trading activities.',
      );
    } else {
      // Mobile platforms: Use lifecycle observer
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Dispose SDK when app is terminated or detached from UI
    // This applies to mobile platforms
    if (state == AppLifecycleState.detached) {
      _disposeSDKIfNeeded();
    }
  }

  /// Handles the window close event.
  /// Returns true if the window should close, false otherwise.
  Future<bool> _handleWindowClose() async {
    final context =
        scaffoldKey.currentContext ?? (mounted ? this.context : null);
    final navigator = context == null ? null : Navigator.maybeOf(context);

    // Show confirmation dialog
    // Bootstrap screens place this handler above MaterialApp, so they have no
    // Navigator. In that case, close directly after shutting down Tor.
    final shouldClose = (navigator == null)
        ? true
        : await showDialog<bool>(
            context: context!,
            builder: (context) {
              return AlertDialog(
                title: const Text('Do you really want to quit?'),
                content: const Text(
                  'This will close P2Pirate and stop all trading activities.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Yes'),
                  ),
                ],
              );
            },
          );

    log('Window close handler: User confirmed close - $shouldClose');

    // If user confirmed, dispose the SDK
    if (shouldClose == true) {
      try {
        await _disposeSDKIfNeeded();
        return true;
      } catch (error) {
        if (context != null && context.mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Trading engine needs attention'),
              content: Text('$error'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Keep wallet open'),
                ),
              ],
            ),
          );
        }
        return false;
      }
    }

    return false;
  }

  Future<void> _handlePop() async {
    final shouldClose = await _handleWindowClose();
    if (shouldClose) {
      await SystemNavigator.pop();
    }
  }

  /// Disposes the SDK if it hasn't been disposed already.
  Future<void> _disposeSDKIfNeeded() async {
    final pending = _shutdown ??= _disposeSDKAndTor();
    try {
      await pending;
    } catch (_) {
      if (identical(_shutdown, pending)) _shutdown = null;
      rethrow;
    }
  }

  Future<void> _disposeSDKAndTor() async {
    // Keep both KDF and Tor available if the engine cannot reconcile or cancel
    // its orders. Closing a wallet during an active hedge would strand it.
    await MmEngineService.instance.stop();
    try {
      await _disposeSDK().timeout(const Duration(seconds: 5));
      log('Window close handler: SDK disposed successfully');
    } catch (e, s) {
      log('Window close handler: error during SDK disposal - $e');
      log('Stack trace: ${s.toString()}');
    } finally {
      // Linux exits the Dart process explicitly after this callback. Stop its
      // child Tor process first, even when SDK cleanup fails or stalls.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
        try {
          await PirateTorService.instance.shutdown().timeout(
            const Duration(seconds: 15),
          );
          log('Window close handler: Tor stopped');
        } catch (e, s) {
          log('Window close handler: error stopping Tor - $e');
          log('Stack trace: ${s.toString()}');
        }
      }
    }
  }

  Future<void> _disposeSDK() async {
    final getIt = GetIt.I;
    if (getIt.isRegistered<Mm2Api>()) {
      await getIt<Mm2Api>().dispose();
      getIt.unregister<Mm2Api>();
    }

    if (getIt.isRegistered<SparklineRepository>()) {
      await getIt<SparklineRepository>().dispose();
      getIt.unregister<SparklineRepository>();
    }

    await mm2.dispose();
  }

  @override
  void dispose() {
    // Clean up based on platform
    if (PlatformTuner.isNativeDesktop) {
      // A bootstrap handler can be disposed after its replacement is mounted.
      // Do not clear the new handler in that case.
      if (identical(_registeredDesktopHandler, this)) {
        _registeredDesktopHandler = null;
        FlutterWindowClose.setWindowShouldCloseHandler(null);
      }
    } else if (!kIsWeb) {
      // Mobile platforms: Remove lifecycle observer
      WidgetsBinding.instance.removeObserver(this);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformTuner.isNativeMobile) {
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (!didPop) {
            _handlePop();
          }
        },
        child: widget.child,
      );
    }

    return widget.child;
  }
}
