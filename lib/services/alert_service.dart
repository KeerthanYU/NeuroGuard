import 'notification_service.dart';

abstract class AlertService {
  Future<void> sendAlert(String title, String body);
}

class DemoAlertService implements AlertService {
  final NotificationService _notificationService = NotificationService();

  @override
  Future<void> sendAlert(String title, String body) async {
    await _notificationService.showEmergencyAlert(
      title: '[Demo] $title',
      body: body,
    );
  }
}

class LiveAlertService implements AlertService {
  final NotificationService _notificationService = NotificationService();

  @override
  Future<void> sendAlert(String title, String body) async {
    await _notificationService.showEmergencyAlert(
      title: title,
      body: body,
    );
  }
}
