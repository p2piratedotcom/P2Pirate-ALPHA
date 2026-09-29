import 'package:flutter/foundation.dart';
import 'package:web_dex/blocs/bloc_base.dart';
import 'package:web_dex/platform/platform.dart';

final updateBloc = UpdateBloc();

class UpdateBloc extends BlocBase {
  @override
  void dispose() {}

  Future<void> init() async {
    // Automatic remote update checks are intentionally unavailable.
  }

  Future<void> update() async {
    if (kIsWeb) reloadPage();
  }
}

enum UpdateStatus { upToDate, available, recommended, required }

class UpdateVersionInfo {
  const UpdateVersionInfo({
    required this.status,
    required this.version,
    required this.changelog,
    required this.downloadUrl,
  });

  final String version;
  final String changelog;
  final String downloadUrl;
  final UpdateStatus status;
}
