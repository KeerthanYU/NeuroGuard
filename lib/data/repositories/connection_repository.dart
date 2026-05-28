import '../../models/app_mode.dart';
import '../../services/firebase_service.dart';
import 'dart:async';

class ConnectionRepository {
  final AppMode mode;
  FirebaseService? _firebaseService;

  ConnectionRepository({required this.mode, required String uid}) {
    if (mode == AppMode.live) {
      _firebaseService = FirebaseService(); // assuming default constructor works
    }
  }

  Stream<bool> get isConnected {
    if (mode == AppMode.demo) {
      return Stream<bool>.periodic(const Duration(seconds: 5), (_) => true);
    } else {
      return _firebaseService!.connectionStatus;
    }
  }

  void dispose() {
    _firebaseService?.dispose();
  }
}
