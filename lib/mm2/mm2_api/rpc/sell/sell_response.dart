import 'package:web_dex/model/text_error.dart';

class SellResponse {
  SellResponse({this.error, this.result, this.outcomeUnknown = false});

  factory SellResponse.fromJson(Map<String, dynamic> json) {
    return SellResponse(
      error: TextError.fromString(json['error']),
      result: SellResponseResult.fromJson(json['result']),
    );
  }

  final TextError? error;
  final SellResponseResult? result;

  /// The transport failed after submission may have reached KDF.
  final bool outcomeUnknown;
}

class SellResponseResult {
  SellResponseResult({required this.uuid});

  static SellResponseResult? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    return SellResponseResult(uuid: json['uuid']);
  }

  final String uuid;
}
