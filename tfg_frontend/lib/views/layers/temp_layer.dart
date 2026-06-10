import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tfg_clima_malaga/domain/interpolators/weather_point.dart';

// ============================================================
//  TempLayer — flutter_map v7
//  Heatmap de temperatura. Gradiente frío→calor.
//  Zonas peligrosas (< 0°C o > 35°C) → más opacas.
//  Zona óptima deportes náuticos (18-24°C) → casi transparente.
// ============================================================

class TempLayer extends StatelessWidget {
  final List<WeatherPoint> points;
  const TempLayer({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return CustomPaint(
      painter: _TempPainter(points: points, camera: camera),
      size: Size.infinite,
      child: const SizedBox.expand(),
    );
  }
}

class _TempPainter extends CustomPainter {
  final List<WeatherPoint> points;
  final MapCamera camera;

  _TempPainter({required this.points, required this.camera});

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
      final temp = p.value.clamp(-30.0, 50.0);

      final center = _toPixel(p.lat, p.lng);
      if (center.dx < -radius ||
          center.dx > size.width + radius ||
          center.dy < -radius ||
          center.dy > size.height + radius) {
        continue;
      }

      final color = _colorForTemp(temp);
      final opacity = _opacityForTemp(temp);

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

  Color _colorForTemp(double t) {
    if (t < -10) return const Color(0xFF4A148C); // violeta oscuro
    if (t < 0) return const Color(0xFF1A237E); // azul oscuro
    if (t < 10) return const Color(0xFF1565C0); // azul
    if (t < 18) return const Color(0xFF00ACC1); // cian
    if (t < 24) return const Color(0xFF43A047); // verde ← óptimo náutico
    if (t < 30) return const Color(0xFFFDD835); // amarillo
    if (t < 38) return const Color(0xFFFB8C00); // naranja
    return const Color(0xFFB71C1C); // rojo peligro
  }

  double _opacityForTemp(double t) {
    if (t >= 18 && t <= 24) return 0.25; // zona óptima → casi transparente
    if (t < 0 || t > 35) return 0.55; // zona peligro → más visible
    return 0.40;
  }

  @override
  bool shouldRepaint(_TempPainter old) =>
      old.points != points || old.camera != camera;
}
