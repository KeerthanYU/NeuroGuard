import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:neuroguard/core/utils/app_theme.dart';

/// Animated real-time heartbeat line chart
class HeartRateChart extends StatelessWidget {
  final List<double> data;
  final double minY;
  final double maxY;

  const HeartRateChart({
    super.key,
    required this.data,
    this.minY = 40,
    this.maxY = 180,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Telemetry offline or buffering...',
          style: AppTheme.label.copyWith(fontSize: 10, color: AppTheme.textMuted),
        ),
      );
    }

    final cleanData = data.where((x) => !x.isNaN && !x.isInfinite).toList();
    if (cleanData.isEmpty) {
      return Center(
        child: Text(
          'Awaiting stable vitals data...',
          style: AppTheme.label.copyWith(fontSize: 10, color: AppTheme.textMuted),
        ),
      );
    }

    final spots = cleanData.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 40,
          getDrawingHorizontalLine: (_) =>
              // ignore: prefer_const_constructors
              FlLine(
            color: AppTheme.divider,
            strokeWidth: 1,
          ),
        ),

        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 40,
              getTitlesWidget: (val, meta) => Text(
                val.toInt().toString(),
                style: AppTheme.label.copyWith(fontSize: 9),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),

        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (cleanData.length - 1).toDouble().clamp(1, 100),
        minY: minY,
        maxY: maxY,

        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppTheme.emergencyRed,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.emergencyRed.withValues(alpha: 0.3),
                  AppTheme.emergencyRed.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],

        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppTheme.bgCard,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toInt()} bpm',
                  const TextStyle(
                    color: AppTheme.textPrimary,
                    fontFamily: AppTheme.fontPoppins,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

/// Animated real-time motion bar chart
class MotionChart extends StatelessWidget {
  final List<double> data;
  /// Color is driven ONLY by seizure state — never by raw value thresholds.
  final bool seizureDetected;

  const MotionChart({
    super.key,
    required this.data,
    required this.seizureDetected,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Telemetry offline or buffering...',
          style: AppTheme.label.copyWith(fontSize: 10, color: AppTheme.textMuted),
        ),
      );
    }

    final cleanData = data.where((x) => !x.isNaN && !x.isInfinite).toList();
    if (cleanData.isEmpty) {
      return Center(
        child: Text(
          'Awaiting stable motion data...',
          style: AppTheme.label.copyWith(fontSize: 10, color: AppTheme.textMuted),
        ),
      );
    }

    // Color depends ONLY on seizureDetected — not on raw motion magnitude.
    final barColor = seizureDetected ? AppTheme.emergencyRed : AppTheme.safeGreen;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 10,
        minY: 0,

        barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: AppTheme.bgCard,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              rod.toY.toStringAsFixed(2),
              const TextStyle(
                color: AppTheme.primaryCyan,
                fontFamily: AppTheme.fontPoppins,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            );
          },
        ),
      ),

        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 5,
              getTitlesWidget: (val, meta) => Text(
                val.toInt().toString(),
                style: AppTheme.label.copyWith(fontSize: 9),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),

        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (_) =>
              // ignore: prefer_const_constructors
              FlLine(
            color: AppTheme.divider,
            strokeWidth: 1,
          ),
        ),

        borderData: FlBorderData(show: false),

        barGroups: cleanData.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.clamp(0.0, 10.0),
                color: barColor,
                width: 6,
                borderRadius: BorderRadius.circular(3),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 10,
                  color: AppTheme.bgCardLight,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}


/// Radial gauge for a single metric
class RadialGauge extends StatelessWidget {
  final double value;
  final double max;
  final String label;
  final Color color;
  final double size;

  const RadialGauge({
    super.key,
    required this.value,
    required this.max,
    required this.label,
    required this.color,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value / max).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sections: [
                PieChartSectionData(
                  value: pct * 100,
                  color: color,
                  radius: 12,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: (1 - pct) * 100,
                  color: AppTheme.bgCardLight,
                  radius: 12,
                  showTitle: false,
                ),
              ],
              centerSpaceRadius: size / 2 - 14,
              sectionsSpace: 0,
            ),
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(pct * 100).toInt()}%',
                style: TextStyle(
                  fontFamily: AppTheme.fontPoppins,
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: AppTheme.label.copyWith(fontSize: 8),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dynamic animated real-time sinus rhythm ECG waveform widget
class ECGChart extends StatefulWidget {
  final int heartRate;
  final bool isCritical;

  const ECGChart({
    super.key,
    required this.heartRate,
    this.isCritical = false,
  });

  @override
  State<ECGChart> createState() => _ECGChartState();
}

class _ECGChartState extends State<ECGChart> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  final List<double> _points = [];
  double _time = 0.0;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Run 60 fps simulation tick
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tick)..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _tick() {
    setState(() {
      // Advance time depending on the current heart rate
      // Higher heart rate moves sinus cycles faster
      final speedFactor = 0.015 * (widget.heartRate / 75.0);
      _time += speedFactor;
      if (_time > 1.0) _time = 0.0;

      // Sinus PQRST curve generation formula
      double y = 0.0;
      final t = _time;

      if (t >= 0.08 && t < 0.16) {
        // P Wave
        y = 0.12 * sin((t - 0.08) / 0.08 * pi);
      } else if (t >= 0.22 && t < 0.25) {
        // Q Wave
        y = -0.15 * sin((t - 0.22) / 0.03 * pi);
      } else if (t >= 0.25 && t < 0.29) {
        // R Wave (Massive ventricles depolarization spike)
        y = 1.0 * sin((t - 0.25) / 0.04 * pi);
      } else if (t >= 0.29 && t < 0.32) {
        // S Wave
        y = -0.30 * sin((t - 0.29) / 0.03 * pi);
      } else if (t >= 0.42 && t < 0.58) {
        // T Wave
        y = 0.22 * sin((t - 0.42) / 0.16 * pi);
      }

      // Add high-frequency muscle tremor noise
      y += (_random.nextDouble() - 0.5) * 0.04;

      _points.add(y);
      if (_points.length > 150) {
        _points.removeAt(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.bgDark.withValues(alpha: 0.4),
          border: Border.all(color: AppTheme.glassBorder.withValues(alpha: 0.4)),
        ),
        child: CustomPaint(
          painter: ECGPainter(
            points: _points,
            color: widget.isCritical ? AppTheme.emergencyRed : AppTheme.accentCyan,
          ),
          child: Container(),
        ),
      ),
    );
  }
}

class ECGPainter extends CustomPainter {
  final List<double> points;
  final Color color;

  ECGPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final stepX = size.width / 150;
    final centerY = size.height * 0.5;

    bool firstPoint = true;
    for (int i = 0; i < points.length; i++) {
      final val = points[i];
      if (val.isNaN || val.isInfinite) continue;

      final x = i * stepX;
      // Invert Y coordinate space of canvas, scale by 40 units height
      final y = centerY - (val * (size.height * 0.4));
      
      if (x.isNaN || x.isInfinite || y.isNaN || y.isInfinite) continue;

      if (firstPoint) {
        path.moveTo(x, y);
        firstPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }

    // Glow Effect
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = 5.0
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
    );

    // Baseline Grid Reference lines
    final gridPaint = Paint()
      ..color = AppTheme.glassBorder.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ECGPainter oldDelegate) => true;
}

/// Premium Oxygen saturation SpO2 trend chart
class SpO2TrendChart extends StatelessWidget {
  final List<double> data;

  const SpO2TrendChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Telemetry offline or buffering...',
          style: AppTheme.label.copyWith(fontSize: 10, color: AppTheme.textMuted),
        ),
      );
    }

    final cleanData = data.where((x) => !x.isNaN && !x.isInfinite).toList();
    if (cleanData.isEmpty) {
      return Center(
        child: Text(
          'Awaiting stable oxygen data...',
          style: AppTheme.label.copyWith(fontSize: 10, color: AppTheme.textMuted),
        ),
      );
    }

    final spots = cleanData.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppTheme.divider.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 5,
              getTitlesWidget: (val, meta) => Text(
                '${val.toInt()}%',
                style: AppTheme.label.copyWith(fontSize: 8),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (cleanData.length - 1).toDouble().clamp(1, 100),
        minY: 80,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppTheme.primaryCyan,
            barWidth: 2.0,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryCyan.withValues(alpha: 0.2),
                  AppTheme.primaryCyan.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
