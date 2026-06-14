import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tfg_clima_malaga/domain/interpolators/weather_point.dart';

class RainLayer extends StatelessWidget {
  final List<WeatherPoint> points;
  final MapCamera camera;
  const RainLayer({super.key, required this.points, required this.camera});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RainPainter(points: points, camera: camera),
      child: const SizedBox.expand(),
    );
  }
}

class _RainPainter extends CustomPainter {
  final List<WeatherPoint> points;
  final MapCamera camera;
  _RainPainter({required this.points, required this.camera});

  Offset _toPixel(double lat, double lng) {
    final pt = camera.latLngToScreenPoint(LatLng(lat, lng));
    return Offset(pt.x, pt.y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final refA = _toPixel(0.0, 0.0);
    final refB = _toPixel(0.0, 2.5);
    final radius = (refB.dx - refA.dx).abs().clamp(20.0, 200.0);

    for (final p in points) {
      final mm = p.value.clamp(0.0, 100.0);
      if (mm < 1.0) continue;
      final center = _toPixel(p.lat, p.lng);
      if (center.dx < -radius ||
          center.dx > size.width + radius ||
          center.dy < -radius ||
          center.dy > size.height + radius) {
        continue;
      }

      final color = _colorForRain(mm);
      final opacity = (mm / 80.0).clamp(0.08, 0.60);
      final shader = RadialGradient(
        colors: [
          color.withValues(alpha: opacity),
          color.withValues(alpha: opacity * 0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, Paint()..shader = shader);
    }
  }

  Color _colorForRain(double mm) {
    if (mm < 20) return const Color(0xFF90CAF9);
    if (mm < 40) return const Color(0xFF42A5F5);
    if (mm < 60) return const Color(0xFF1565C0);
    if (mm < 80) return const Color(0xFF7B1FA2);
    return const Color(0xFFAD1457);
  }

  @override
  bool shouldRepaint(_RainPainter old) =>
      old.points != points || old.camera != camera;
}
