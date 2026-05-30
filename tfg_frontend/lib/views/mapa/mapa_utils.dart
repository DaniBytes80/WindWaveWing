import 'dart:math';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// ===============================================================
///  MAPA UTILS — Funciones auxiliares para CleanSport Map
/// ===============================================================
///
///  Este archivo contiene:
///   - Conversión de direcciones de viento
///   - Cálculos matemáticos (interpolación, clamp, mapRange)
///   - Conversión de valores meteorológicos a colores
///   - Distancias y zoom recomendado
///   - Utilidades generales para MapLibre
///
/// ===============================================================

class MapaUtils {
  // ---------------------------------------------------------------
  //  DIRECCIÓN DEL VIENTO (grados → texto)
  // ---------------------------------------------------------------

  static String direccionViento(double grados) {
    const direcciones = [
      "N", "NNE", "NE", "ENE",
      "E", "ESE", "SE", "SSE",
      "S", "SSO", "SO", "OSO",
      "O", "ONO", "NO", "NNO"
    ];

    final index = ((grados % 360) / 22.5).round() % 16;
    return direcciones[index];
  }

  // ---------------------------------------------------------------
  //  INTERPOLACIÓN Y MATEMÁTICAS
  // ---------------------------------------------------------------

  /// Limita un valor entre un mínimo y un máximo
  static double clamp(double v, double min, double max) {
    return v < min ? min : (v > max ? max : v);
  }

  /// Interpolación lineal
  static double lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  /// Convierte un valor de un rango a otro
  static double mapRange(double value, double inMin, double inMax, double outMin, double outMax) {
    final t = (value - inMin) / (inMax - inMin);
    return outMin + (outMax - outMin) * t;
  }

  // ---------------------------------------------------------------
  //  DISTANCIA ENTRE DOS COORDENADAS
  // ---------------------------------------------------------------

  static double distanciaKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // radio de la Tierra en km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _deg2rad(double deg) => deg * pi / 180;

  // ---------------------------------------------------------------
  //  ZOOM RECOMENDADO SEGÚN DISTANCIA
  // ---------------------------------------------------------------

  static double zoomParaDistancia(double km) {
    if (km < 2) return 14;
    if (km < 5) return 13;
    if (km < 10) return 12;
    if (km < 20) return 11;
    if (km < 50) return 10;
    return 9;
  }

  // ---------------------------------------------------------------
  //  CONVERSIÓN DE VALORES METEO → COLORES
  // ---------------------------------------------------------------

  /// Viento (nudos) → color
  static Color colorViento(double nudos) {
    if (nudos < 5) return Colors.lightBlue.shade100;
    if (nudos < 10) return Colors.lightBlue.shade300;
    if (nudos < 15) return Colors.blue.shade400;
    if (nudos < 20) return Colors.blue.shade700;
    return Colors.indigo.shade900;
  }

  /// Olas (metros) → color
  static Color colorOlas(double metros) {
    if (metros < 0.5) return Colors.blue.shade100;
    if (metros < 1.0) return Colors.blue.shade300;
    if (metros < 2.0) return Colors.blue.shade600;
    return Colors.blue.shade900;
  }

  /// Temperatura (°C) → color
  static Color colorTemperatura(double t) {
    if (t < 5) return Colors.blue.shade300;
    if (t < 15) return Colors.green.shade300;
    if (t < 25) return Colors.orange.shade400;
    return Colors.red.shade700;
  }

  /// Lluvia (mm) → color
  static Color colorLluvia(double mm) {
    if (mm < 1) return Colors.blueGrey.shade100;
    if (mm < 5) return Colors.blueGrey.shade300;
    if (mm < 15) return Colors.blueGrey.shade600;
    return Colors.blueGrey.shade900;
  }

  // ---------------------------------------------------------------
  //  UTILIDADES PARA MAPLIBRE
  // ---------------------------------------------------------------

  /// Espera a que el mapa esté completamente listo
  static Future<void> esperarMapaListo() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Comprueba si una capa existe
  static Future<bool> capaExiste(MapLibreMapController c, String id) async {
    final capas = await c.getLayerIds();
    return capas.contains(id);
  }

  /// Comprueba si una fuente existe
  static Future<bool> fuenteExiste(MapLibreMapController c, String id) async {
    final fuentes = await c.getSourceIds();
    return fuentes.contains(id);
  }
}
