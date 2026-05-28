import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroguard/providers/patient_provider.dart';
import 'package:neuroguard/core/utils/app_theme.dart';
import 'package:neuroguard/core/widgets/common_widgets.dart';

class GpsTrackingScreen extends ConsumerStatefulWidget {
  const GpsTrackingScreen({super.key});

  @override
  ConsumerState<GpsTrackingScreen> createState() => _GpsTrackingScreenState();
}

class _GpsTrackingScreenState extends ConsumerState<GpsTrackingScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    final patientState = ref.watch(patientProvider);
    final patient = patientState.patient;
    final target = LatLng(patient.latitude, patient.longitude);

    // Listen to patient location changes to center the map
    ref.listen<PatientState>(patientProvider, (previous, next) {
      final prevPat = previous?.patient;
      final nextPat = next.patient;
      if (prevPat == null ||
          prevPat.latitude != nextPat.latitude ||
          prevPat.longitude != nextPat.longitude) {
        _mapController.move(LatLng(nextPat.latitude, nextPat.longitude), _mapController.camera.zoom);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        title: const Row(children: [
          Icon(Icons.map_rounded, color: AppTheme.primaryCyan, size: 22),
          SizedBox(width: 8),
          Text('GPS Tracking'),
        ]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Row(children: [
              PulseIndicator(color: AppTheme.primaryCyan),
              SizedBox(width: 6),
              Text('TRACKING',
                  style: TextStyle(
                      fontFamily: AppTheme.fontInter,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryCyan,
                      letterSpacing: 1.2)),
            ]),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Column(
          children: [
            // ─── Map ─────────────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  // OpenStreetMap with Premium Dark Tinting
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: target,
                        initialZoom: 15.5,
                        minZoom: 3.0,
                        maxZoom: 19.0,
                      ),
                      children: [
                        // Midnight Blue Sci-Fi Dark Mode styling via ColorFiltered matrix
                        ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            -0.2126, -0.7152, -0.0722, 0, 25.5,
                            -0.2126, -0.7152, -0.0722, 0, 45.9,
                            -0.2126, -0.7152, -0.0722, 0, 71.4,
                            0, 0, 0, 1, 0,
                          ]),
                          child: TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.neuroguard.neuroguard',
                          ),
                        ),
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: target,
                              radius: 80,
                              useRadiusInMeter: true,
                              color: AppTheme.emergencyRed.withValues(alpha: 0.08),
                              borderColor: AppTheme.emergencyRed.withValues(alpha: 0.35),
                              borderStrokeWidth: 1,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: target,
                              width: 80,
                              height: 80,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: (patient.seizureDetected
                                              ? AppTheme.emergencyRed
                                              : AppTheme.primaryCyan)
                                          .withValues(alpha: 0.25),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: patient.seizureDetected
                                            ? AppTheme.emergencyRed
                                            : AppTheme.primaryCyan,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (patient.seizureDetected
                                                  ? AppTheme.emergencyRed
                                                  : AppTheme.primaryCyan)
                                              .withValues(alpha: 0.4),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppTheme.bgCard,
                                      child: Icon(
                                        Icons.person_pin_circle_rounded,
                                        color: patient.seizureDetected
                                            ? AppTheme.emergencyRed
                                            : AppTheme.primaryCyan,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Recenter button
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: GestureDetector(
                      onTap: () {
                        _mapController.move(target, 15.5);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.glassBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.my_location_rounded,
                            color: AppTheme.primaryCyan, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Info Panel ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Location card
                  GlassCard(
                    borderColor: AppTheme.primaryCyan.withValues(alpha: 0.3),
                    child: Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.location_on_rounded,
                            color: AppTheme.primaryCyan, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const Text('Current Location',
                              style: TextStyle(
                                  fontFamily: AppTheme.fontPoppins,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary)),
                          Text(
                            '${patient.latitude.toStringAsFixed(6)}, ${patient.longitude.toStringAsFixed(6)}',
                            style: AppTheme.bodyMD,
                          ),
                        ]),
                      ),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                        Text('Updated', style: AppTheme.label),
                        Text(patient.formattedTimestamp,
                            style: AppTheme.bodySM),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // Stats row
                  Row(children: [
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const Text('Patient',
                              style: TextStyle(
                                  fontFamily: AppTheme.fontInter,
                                  fontSize: 10,
                                  color: AppTheme.textMuted)),
                          const SizedBox(height: 4),
                          Text(patient.patientName,
                              style: const TextStyle(
                                  fontFamily: AppTheme.fontPoppins,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(14),
                        borderColor: patient.seizureDetected
                            ? AppTheme.emergencyRed.withValues(alpha: 0.4)
                            : AppTheme.safeGreen.withValues(alpha: 0.3),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const Text('Status',
                              style: TextStyle(
                                  fontFamily: AppTheme.fontInter,
                                  fontSize: 10,
                                  color: AppTheme.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            patient.seizureDetected
                                ? '⚠ ALERT'
                                : '✓ Safe',
                            style: TextStyle(
                                fontFamily: AppTheme.fontPoppins,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: patient.seizureDetected
                                    ? AppTheme.emergencyRed
                                    : AppTheme.safeGreen),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const Text('HR',
                              style: TextStyle(
                                  fontFamily: AppTheme.fontInter,
                                  fontSize: 10,
                                  color: AppTheme.textMuted)),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: '${patient.heartRate}',
                                style: const TextStyle(
                                    fontFamily: AppTheme.fontPoppins,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.emergencyRed),
                              ),
                              const TextSpan(
                                text: ' bpm',
                                style: TextStyle(
                                    fontFamily: AppTheme.fontInter,
                                    fontSize: 10,
                                    color: AppTheme.textMuted),
                              ),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
