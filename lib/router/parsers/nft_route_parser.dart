import 'package:web_dex/router/parsers/base_route_parser.dart';
import 'package:web_dex/router/routes.dart';

class _NFTsRouteParser implements BaseRouteParser {
  const _NFTsRouteParser();

  @override
  AppRoutePath getRoutePath(Uri uri) => WalletRoutePath.wallet();
}

const nftRouteParser = _NFTsRouteParser();
