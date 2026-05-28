// lib/models/app_mode.dart

enum AppMode { demo, live }

extension AppModeExtension on AppMode {
  String toShortString() => name;
  static AppMode fromString(String s) => s == 'live' ? AppMode.live : AppMode.demo;
}
