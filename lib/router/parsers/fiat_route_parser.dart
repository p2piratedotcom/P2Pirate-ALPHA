import 'package:web_dex/router/parsers/base_route_parser.dart';
import 'package:web_dex/router/routes.dart';

class _FiatRouteParser implements BaseRouteParser {
  const _FiatRouteParser();

  @override
  AppRoutePath getRoutePath(Uri uri) => WalletRoutePath.wallet();
}

const fiatRouteParser = _FiatRouteParser();
