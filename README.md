# NeuroGuard — 24/7 Smart Epilepsy Guardian

> **Production-level Flutter + Firebase healthcare app for real-time epilepsy seizure detection and emergency monitoring via ESP32 wearable.**

---

## 📱 Screenshots & Features

| Splash | Dashboard | Emergency Alert |
|--------|-----------|-----------------|
| Animated ECG + pulse rings | Live stats cards + charts | Full-screen SOS with pulse anim |

| GPS Tracking | History | Caregiver |
|---|---|---|
| Dark Google Maps + live marker | Timeline UI with severity | Remote monitoring + contacts |

---

## 🏗️ Architecture

```
neuroguard/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── firebase_options.dart        # Firebase config (replace with yours)
│   ├── models/
│   │   ├── patient_model.dart       # Real-time patient data model
│   │   └── alert_model.dart         # Seizure event model
│   ├── providers/
│   │   ├── patient_provider.dart    # Real-time state (streams Firebase)
│   │   ├── auth_provider.dart       # Auth state
│   │   └── theme_provider.dart      # Dark/light toggle
│   ├── services/
│   │   ├── firebase_service.dart    # DB streams + writes
│   │   ├── auth_service.dart        # Email + Google auth
│   │   └── notification_service.dart # FCM + local notifs
│   ├── screens/
│   │   ├── splash_screen.dart       # Animated with ECG
│   │   ├── login_screen.dart        # Email + Google sign-in
│   │   ├── home_dashboard.dart      # Main dashboard
│   │   ├── emergency_alert_screen.dart # Red SOS screen
│   │   ├── live_monitoring_screen.dart # Live charts
│   │   ├── gps_tracking_screen.dart    # Google Maps
│   │   ├── history_screen.dart         # Timeline alerts
│   │   ├── caregiver_dashboard.dart    # Remote monitoring
│   │   └── settings_screen.dart        # Preferences
│   ├── widgets/
│   │   ├── common_widgets.dart      # GlassCard, StatCard, buttons
│   │   └── charts.dart              # fl_chart wrappers
│   └── utils/
│       ├── app_theme.dart           # Design system
│       └── constants.dart           # Routes + constants
├── esp32/
│   └── neuroguard_firmware.ino     # ESP32 Arduino code
├── firebase/
│   └── database.rules.json         # DB security rules
└── android/
    └── app/src/main/AndroidManifest.xml
```

---

## 🚀 Quick Setup

### Step 1 — Clone the project
```bash
cd d:\SApp\neuroguard
flutter pub get
```

### Step 2 — Firebase Setup
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project: **NeuroGuard**
3. Enable:
   - ✅ Authentication (Email/Password + Google)
   - ✅ Realtime Database
   - ✅ Cloud Messaging (FCM)
4. Add an **Android app**:
   - Package: `com.neuroguard.neuroguard`
   - Download `google-services.json` → place in `android/app/`
5. Open `lib/firebase_options.dart` and replace **all placeholder values**

### Step 3 — Google Maps API
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Enable **Maps SDK for Android** + **Maps SDK for iOS**
3. Create an API key
4. In `android/app/src/main/AndroidManifest.xml` replace:
   ```xml
   android:value="YOUR_GOOGLE_MAPS_API_KEY"
   ```

### Step 4 — Firebase Database Rules
Import `firebase/database.rules.json` into your Firebase Realtime Database rules.

### Step 5 — Seed Mock Data (for demo without ESP32)
In `HomeDashboard`, tap **"Test SOS"** to simulate a seizure,  
or call `provider.startMockSimulation()` to stream periodic data.

### Step 6 — Run the App
```bash
flutter run --debug
# For release:
flutter run --release
```

---

## 📡 Firebase Database Structure

```json
{
  "patients": {
    "patient_001": {
      "patientName": "Alex Johnson",
      "deviceId": "ESP32-NG-001",
      "heartRate": 78,
      "motionLevel": 2.3,
      "seizureDetected": false,
      "battery": 85,
      "latitude": 28.6139,
      "longitude": 77.2090,
      "timestamp": 1716115200,
      "connected": true
    }
  },
  "alerts": {
    "alert_001": {
      "time": 1716115200,
      "severity": "CRITICAL",
      "heartRate": 162,
      "motionLevel": 9.4,
      "latitude": 28.6145,
      "longitude": 77.2088,
      "patientId": "patient_001",
      "notes": "Tonic-clonic seizure detected"
    }
  }
}
```

---

## 🔌 ESP32 Hardware Setup

### Components
| Component | Purpose |
|-----------|---------|
| ESP32 DevKit v1 | Main microcontroller |
| MAX30102 | Heart Rate + SpO2 |
| MPU6050 | Accelerometer (motion/tremor) |
| Neo-6M GPS | Location tracking |
| LiPo 3.7V | Battery |

### Wiring
```
MAX30102:  SDA → GPIO21  |  SCL → GPIO22
MPU6050:   SDA → GPIO21  |  SCL → GPIO22  (shared I2C)
GPS:       TX  → GPIO16  |  RX  → GPIO17
Battery:   Analog         →  GPIO34
```

### Flash Firmware
1. Install Arduino IDE + ESP32 board support
2. Install required libraries (listed in firmware comments)
3. Fill in WiFi + Firebase credentials in `neuroguard_firmware.ino`
4. Upload and open Serial Monitor (115200 baud)

---

## 🎨 Design System

| Token | Value |
|-------|-------|
| Background | `#050A18` deep space |
| Card | `#0D1B2E` glass dark |
| Primary Blue | `#0066FF` |
| Accent Cyan | `#00D4FF` |
| Emergency Red | `#FF1744` |
| Safe Green | `#00E676` |
| Font | Poppins + Inter |

---

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| firebase_core | ^2.24.2 | Firebase init |
| firebase_auth | ^4.16.0 | Authentication |
| firebase_database | ^10.4.9 | Realtime data |
| firebase_messaging | ^14.7.10 | Push notifications |
| provider | ^6.1.1 | State management |
| google_maps_flutter | ^2.5.3 | GPS maps |
| fl_chart | ^0.66.2 | Heart/motion charts |
| flutter_local_notifications | ^16.3.2 | Local alerts |
| lottie | ^3.0.0 | Animations |

---

## 🏆 Hackathon Presentation Tips

1. **Demo Flow**: Launch → Splash → Login (Google) → Dashboard → tap "Test SOS" → Emergency screen → GPS → History → Settings
2. **Offline Demo**: All screens work with mock data — no ESP32 needed
3. **Key Selling Points**: Real-time Firebase streaming, automated seizure detection, one-tap caregiver alert, dark healthcare UI
4. **Social Impact**: 50M+ epilepsy patients worldwide; 30% have uncontrolled seizures

---

## 👥 Team

Built with ❤️ for healthcare innovation.  
**NeuroGuard** — _"Because every second matters."_
