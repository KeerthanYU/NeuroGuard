import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:neuroguard/firebase_options.dart';
import 'package:neuroguard/services/notification_service.dart';

class AppInitializer {
  static late FirebaseApp firebaseApp;
  static late FirebaseDatabase database;

  static const String _dbUrl =
      "https://neuroguard-5dda9-default-rtdb.asia-southeast1.firebasedatabase.app";

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1️⃣ Firebase Core init (safe)
    firebaseApp = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2️⃣ FORCE correct RTDB instance (THIS FIXES YOUR ISSUE)
    database = FirebaseDatabase.instanceFor(
      app: firebaseApp,
      databaseURL: _dbUrl,
    );

    // 3️⃣ Enable persistence (safe for medical monitoring apps)
    database.setPersistenceEnabled(true);

    // 4️⃣ Optional cache tuning (prevents memory spikes in telemetry apps)
    database.setPersistenceCacheSizeBytes(10 * 1024 * 1024); // 10MB

    // 5️⃣ SharedPreferences warmup
    await SharedPreferences.getInstance();

    // 6️⃣ Notification system init
    await NotificationService().initialize();

    debugPrint("✅ NeuroGuard initialized with RTDB: $_dbUrl");
  }
}