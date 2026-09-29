class AnalyticsSettings {
  const AnalyticsSettings({required this.isSendAllowed});

  static AnalyticsSettings initial() {
    return const AnalyticsSettings(isSendAllowed: false);
  }

  final bool isSendAllowed;

  AnalyticsSettings copyWith({bool? isSendAllowed}) {
    return AnalyticsSettings(
      isSendAllowed: isSendAllowed ?? this.isSendAllowed,
    );
  }

  static AnalyticsSettings fromJson(Map<String, dynamic>? json) {
    // Ignore legacy opt-in values; this edition has no analytics collection.
    return AnalyticsSettings.initial();
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'send_allowed': isSendAllowed,
  };
}
