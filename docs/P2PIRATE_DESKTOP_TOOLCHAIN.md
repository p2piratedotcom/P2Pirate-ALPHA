# P2Pirate Linux desktop toolchain

The P2Pirate source port targets Flutter 3.47.5 and its bundled Dart 3.13.4
on Linux x86_64. The wallet's `pubspec.yaml` and `pubspec.lock` pin the
Flutter-compatible `intl` 0.20.3 release. Installing a separate Dart SDK is
unnecessary: Flutter includes it.

For Ubuntu 24.04 based systems, including Zorin OS 18, install the desktop
build tools and native libraries:

```sh
sudo apt-get update
sudo apt-get install -y \
  curl git unzip xz-utils zip libglu1-mesa \
  clang cmake ninja-build pkg-config libgtk-3-dev libstdc++-12-dev \
  libsecret-1-dev libjsoncpp-dev libsqlite3-dev \
  libwebkit2gtk-4.1-dev libsoup-3.0-dev
```

Install Flutter into a user-owned directory, then check the toolchain:

```sh
mkdir -p "$HOME/develop"
git clone --depth 1 --branch stable \
  https://github.com/flutter/flutter.git "$HOME/develop/flutter"
export PATH="$HOME/develop/flutter/bin:$PATH"
flutter config --enable-linux-desktop
flutter --version
dart --version
flutter doctor -v
```

For a repeatable release build, use the Flutter revision recorded in the
release manifest rather than allowing `stable` to move. Android SDK and Chrome
warnings from `flutter doctor` do not prevent a Linux desktop build.

After checking out the desired wallet branch and its pinned SDK submodule:

```sh
git submodule sync --recursive
git submodule update --init --recursive
flutter pub get --enforce-lockfile
flutter analyze
flutter build linux --release
```

These commands build the Flutter application. Supplying the approved KDF 2.7
executable and any separately licensed bundled tools remains a release step;
the Flutter build alone is not a complete P2Pirate AppImage.
