import 'package:web_dex/blocs/update_bloc.dart';

const AppUpdateService appUpdateService = AppUpdateService();

class AppUpdateService {
  const AppUpdateService();

  // Remote updates stay disabled until a Pirate-owned, signed feed exists.
  Future<UpdateVersionInfo?> getUpdateInfo() async => null;
}
