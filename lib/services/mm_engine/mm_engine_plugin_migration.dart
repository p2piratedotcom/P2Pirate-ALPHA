/// Coordinate installation without discarding an unresolved live session.
/// Callbacks retain the engine's authoritative pause/reconciliation/stop guards.
Future<void> migrateCexPlugins({
  required bool needsRecovery,
  required bool isRunning,
  required bool catalogAvailable,
  required Future<void> Function() download,
  required Future<void> Function() recoverLive,
  required Future<void> Function() pauseAndStop,
  required Future<void> Function() clearLivePreference,
  required Future<void> Function() connectPreview,
}) async {
  var downloaded = false;
  if (needsRecovery && !isRunning) {
    // First-use migration cannot recover without the newly verified adapters.
    if (!catalogAvailable) {
      await download();
      downloaded = true;
    }
    await recoverLive();
    await pauseAndStop();
  } else if (isRunning) {
    await pauseAndStop();
  }
  // Never clear remembered live recovery before a guarded shutdown succeeds.
  await clearLivePreference();
  if (!downloaded) await download();
  await connectPreview();
}
