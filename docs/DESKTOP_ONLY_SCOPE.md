# Desktop-only scope and platform cleanup

P2Pirate's intended app targets are Linux, macOS and Windows. Linux is the
current build and release target. macOS and Windows need native-host builds and runtime
checks before they can be described as supported releases. The desktop CI
and release-triggered build currently produce a Linux artifact only; the
macOS and Windows runner sources remain for a later phase. The Android and
Web app runners were removed in the desktop-only cleanup. The iOS runner is
still present but is not a supported P2Pirate target.

## Removed from the app repository

- Root `android/` and `web/` runners, icons and platform metadata.
- Android APK/Docker jobs, browser UI and Firebase Hosting jobs, Web preview
  job, their dedicated actions, Firebase configuration and nginx deployment
  role. The old Docker Linux job also used an Android SDK image and Flutter
  3.41.4, so it was retired; the primary desktop build job remains.
- Android/Web entries in `.metadata`, the Android icon generator and the Web
  build checks embedded in generic CI jobs. Unit tests and static analysis now
  resolve packages without building a Web application.

All removed material remains available in the upstream Git history. The
desktop application source, SDK pin, Linux AppImage packaging and licenses
remain in place.

## Shared code deliberately retained

- `pubspec.yaml` includes `assets/packages/flutter_inappwebview_web/assets/web/`.
  This is a package asset, not a file in the removed root `web/`. It remains
  until desktop WebView behavior has been checked on each target.
- `lib/` and the SDK use conditional Web imports and mobile platform branches.
  They remain during runner cleanup. Removing them is a separate code refactor
  needing desktop compile and wallet-flow checks. Packages such as `web` and
  `flutter_inappwebview` also remain because shared Dart code uses them.
- The browser-based test groups in `test_integration/tests/` remain as
  historical source. The active Linux UI smoke test is in `integration_test/`;
  see `docs/INTEGRATION_TESTING.md`.
- `ios/` remains for a separate mobile cleanup. It is not built by CI or
  described as a supported release.
- The shared SDK's `copy_platform_assets` step still writes two generated
  files under `web/kdf/res/` during desktop builds. They are ignored and do
  not restore a Web app runner; changing that step belongs in the SDK fork.
- Flutter can preserve local Android plugin registration files and its Android
  analyzer exclusion after the runner is removed. These generated files are
  ignored; the exclusion does not enable an Android build.

Avoid running unrestricted `flutter create .`, which could recreate runners.
Flutter's desktop guide uses
  [`flutter create --platforms=windows,macos,linux .`](https://docs.flutter.dev/platform-integration/desktop)
when desktop files need to be generated.

## Verification and next cleanup

Resolve dependencies, check that no active workflow points at the deleted
runners, analyze the changed configuration and build Linux. Native macOS and
Windows builds and runtime checks are still required before their releases.
The next source cleanup can remove the iOS runner and browser test harness;
only then consider pruning conditional Dart code and plugin packages based on
evidence from each supported desktop target.
