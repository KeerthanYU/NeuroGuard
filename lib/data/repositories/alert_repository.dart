// lib/data/repositories/alert_repository.dart
//
// Provides a simple interface to send alerts. The concrete implementation is
// chosen based on the current AppMode (DemoAlertService or LiveAlertService).

import '../../models/app_mode.dart';
import '../../services/alert_service.dart';

class AlertRepository {
  final AlertService _service;

  AlertRepository({required AppMode mode})
      : _service = mode == AppMode.demo ? DemoAlertService() : LiveAlertService();

  Future<void> sendAlert(String title, String body) => _service.sendAlert(title, body);
}
