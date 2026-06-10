import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tfg_clima_malaga/domain/interpolators/weather_point.dart';

// ============================================================
//  WindLayer — flutter_map v7
//
//  ✅ FIX: Usa CustomPainterLayer en vez de MobileLayerTransformer
//  (eliminado en flutter_map v6+).
//
//  Partículas animadas tipo Windy. Color y grosor según nudos:
//    < 7 kn  → azul claro   < 14 → cian   < 21 → verde
//    < 33 → amarillo   < 47 → naranja   ≥ 47 → rojo
// ============================================================

class WindLayer extends StatefulWidget {
  final List<WeatherPoint> points;
  final TickerProvider vsync;

  const WindLayer({super.key, required this.points, required this.vsync});

  @override
  State<WindLayer> createState() => _WindLayerState();
}

class _WindLayerState extends State<WindLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Particle> _particles;
  final _rnd = math.Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
    _buildParticles();
  }

  @override
  void didUpdateWidget(WindLayer old) {
    super.didUpdateWidget(old);
    if (old.points != widget.points) _buildParticles();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _buildParticles() {
    if (widget.points.isEmpty) {
      _particles = [];
      return;
    }
    final lats = widget.points.map((p) => p.lat);
    final lngs = widget.points.map((p) => p.lng);
    final minLat = lats.reduce(math.min);
    final maxLat = lats.reduce(math.max);
    final minLng = lngs.reduce(math.min);
    final maxLng = lngs.reduce(math.max);

    _particles = List.generate(
      250,
      (_) => _Particle(
        lat: minLat + _rnd.nextDouble() * (maxLat - minLat),
        lng: minLng + _rnd.nextDouble() * (maxLng - minLng),
        age: _rnd.nextDouble(),
        minLat: minLat,
        maxLat: maxLat,
        minLng: minLng,
        maxLng: maxLng,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ flutter_map v7: usar el mapCamera del contexto para proyectar coords
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final camera = MapCamera.of(context);
        return CustomPaint(
          painter: _WindPainter(
            points: widget.points,
            particles: _particles,
            animValue: _ctrl.value,
            camera: camera,
            rnd: _rnd,
          ),
          size: Size.infinite,
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _Particle {
  double lat, lng, age;
  final double minLat, maxLat, minLng, maxLng;
  _Particle({
    required this.lat,
    required this.lng,
    required this.age,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });
  void reset(math.Random rnd) {
    lat = minLat + rnd.nextDouble() * (maxLat - minLat);
    lng = minLng + rnd.nextDouble() * (maxLng - minLng);
    age = 0;
  }
}

class _WindPainter extends CustomPainter {
  final List<WeatherPoint> points;
  final List<_Particle> particles;
  final double animValue;
  final MapCamera camera;
  final math.Random rnd;

  _WindPainter({
    required this.points,
    required this.particles,
    required this.animValue,
    required this.camera,
    required this.rnd,
  });

  // Convierte lat/lng → píxel en el canvas usando la cámara del mapa
  Offset _toPixel(double lat, double lng) {
    final pt = camera.latLngToScreenPoint(LatLng(lat, lng));
    return Offset(pt.x, pt.y);
  }

  WeatherPoint? _nearest(double lat, double lng) {
    WeatherPoint? best;
    double minD = double.infinity;
    for (final wp in points) {
      final d =
          (wp.lat - lat) * (wp.lat - lat) + (wp.lng - lng) * (wp.lng - lng);
      if (d < minD) {
        minD = d;
        best = wp;
      }
    }
    return best;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || particles.isEmpty) return;

    for (final p in particles) {
      final wp = _nearest(p.lat, p.lng);
      if (wp == null) continue;
      final speed = wp.value.clamp(0.0, 60.0);
      if (speed < 0.5) continue;

      final cur = _toPixel(p.lat, p.lng);
      final dt = 0.004 * speed;
      final rad = wp.dir * math.pi / 180;
      final prev = Offset(
        cur.dx - math.sin(rad) * dt * size.width * 0.08,
        cur.dy + math.cos(rad) * dt * size.height * 0.08,
      );

      p.age += 0.012;
      if (p.age > 1.0) p.reset(rnd);
      final opacity = math.sin(p.age * math.pi).clamp(0.0, 1.0);

      canvas.drawLine(
        prev,
        cur,
        Paint()
          ..color = _color(speed).withValues(alpha: opacity * 0.80)
          ..strokeWidth = (speed / 18).clamp(0.8, 3.5)
          ..strokeCap = StrokeCap.round,
      );

      // Actualizar posición de la partícula (en grados)
      p.lat += math.cos(rad) * dt * 0.04;
      p.lng += math.sin(rad) * dt * 0.04;
    }
  }

  Color _color(double kn) {
    if (kn < 7) return const Color(0xFF64B5F6);
    if (kn < 14) return const Color(0xFF26C6DA);
    if (kn < 21) return const Color(0xFF66BB6A);
    if (kn < 33) return const Color(0xFFFFEE58);
    if (kn < 47) return const Color(0xFFFFA726);
    return const Color(0xFFEF5350);
  }

  @override
  bool shouldRepaint(_WindPainter old) => old.animValue != animValue;
}
