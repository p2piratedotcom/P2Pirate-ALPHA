import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/analytics/analytics_repo.dart';
import 'package:web_dex/bloc/analytics/analytics_event.dart';
import 'package:web_dex/bloc/analytics/analytics_state.dart';
import 'package:web_dex/bloc/settings/settings_repository.dart';
import 'package:web_dex/model/stored_settings.dart';

// Kept for existing widget dependencies; Pirate Wallet does not collect events.
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  AnalyticsBloc({
    required AnalyticsRepo analytics,
    required StoredSettings storedData,
    required SettingsRepository repository,
  }) : super(AnalyticsState.initial()) {
    on<AnalyticsEvent>((event, emit) {});
  }

  void logEvent(AnalyticsEventData event) {}
}
