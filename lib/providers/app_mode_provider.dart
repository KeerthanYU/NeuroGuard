import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_mode.dart';

class AppModeNotifier extends StateNotifier<AppMode> {
  AppModeNotifier() : super(AppMode.demo);

  void setMode(AppMode mode) {
    state = mode;
  }

  void reset() {
    state = AppMode.demo;
  }
}

final appModeProvider =
    StateNotifierProvider<AppModeNotifier, AppMode>(
  (ref) => AppModeNotifier(),
);