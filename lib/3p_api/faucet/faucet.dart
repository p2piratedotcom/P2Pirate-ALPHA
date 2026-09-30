import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_dex/3p_api/faucet/faucet_response.dart';

const faucetBaseUrl = String.fromEnvironment('P2PIRATE_FAUCET_BASE_URL');
const hasConfiguredFaucet = faucetBaseUrl != '';

Future<FaucetResponse> callFaucet(String coin, String address) async {
  if (!hasConfiguredFaucet) {
    return FaucetResponse.error('No faucet provider is configured');
  }
  try {
    final response = await http.get(
      Uri.parse('$faucetBaseUrl/faucet/$coin/$address'),
    );

    final Map<String, dynamic> json = jsonDecode(response.body);
    return FaucetResponse.fromJson(json);
  } catch (e) {
    return FaucetResponse.error(e.toString());
  }
}
