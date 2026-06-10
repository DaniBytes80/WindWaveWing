import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tfg_clima_malaga/domain/interpolators/weather_point.dart';

// ============================================================
//  WaveLayer — flutter_map v7
//
//  Las olas se muestran como manchas de color en el mar,
//  NO como flechas. Color según altura:
//    0-0.5m → transparente (calma, no se pinta)
//    0.5-1m  → azul muy pálido
//    1-2m    → azul
//    2-3m    → azul intenso
//    3-4m    → violeta
//    > 4m    → magenta (oleaje peligroso)
//
//  La opacidad varía con la altura para que el mapa base
//  siempre sea visible debajo.
// ============================================================

class WaveLayer extends StatelessWidget {
  final List<WeatherPoint> points;
  const WaveLayer({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return CustomPaint(
      painter: _WavePainter(points: points, camera: camera),
      size: Size.infinite,
      child: const SizedBox.expand(),
    );
  }
}

class _WavePainter extends CustomPainter {
  final List<WeatherPoint> points;
  final MapCamera camera;

  _WavePainter({required this.points, required this.camera});

  Offset _toPixel(double lat, double lng) {
    final pt = camera.latLngToScreenPoint(LatLng(lat, lng));
    return Offset(pt.x, pt.y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Radio de difuminado: equivalente a ~2.5° en la pantalla actual
    final refA = _toPixel(0.0, 0.0);
    final refB = _toPixel(0.0, 2.5);
    final radius = (refB.dx - refA.dx).abs().clamp(20.0, 200.0);

    for (final p in points) {
      final height = p.value.clamp(0.0, 8.0);
      if (height < 0.3) continue; // no pintar calma absoluta

      final center = _toPixel(p.lat, p.lng);

      // Fuera del canvas → saltar
      if (center.dx < -radius ||
          center.dx > size.width + radius ||
          center.dy < -radius ||
          center.dy > size.height + radius) {
        continue;
      }

      final color = _colorForHeight(height);
      final opacity = _opacityForHeight(height);

      final shader = RadialGradient(
        colors: [
          color.withValues(alpha: opacity),
          color.withValues(alpha: opacity * 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawCircle(center, radius, Paint()..shader = shader);
    }
  }

  Color _colorForHeight(double m) {
    if (m < 0.5) return const Color(0xFFB3E5FC); // azul muy pálido
    if (m < 1.0) return const Color(0xFF4FC3F7); // azul claro
    if (m < 2.0) return const Color(0xFF0288D1); // azul
    if (m < 3.0) return const Color(0xFF01579B); // azul intenso
    if (m < 4.0) return const Color(0xFF6A1B9A); // violeta
    return const Color(0xFFAD1457); // magenta — peligroso
  }

  double _opacityForHeight(double m) {
    // Proporcional a la altura, máx 0.60 para que el mapa sea visible
    return (m / 6.0).clamp(0.08, 0.60);
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.points != points || old.camera != camera;
}
