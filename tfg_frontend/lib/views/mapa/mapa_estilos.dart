import 'package:flutter/material.dart';

/// ===============================================================
///  ESTILOS Y PALETA CLEANSPORT MAP
/// ===============================================================
///
///  Este archivo define:
///   - Colores base del mapa
///   - Gradientes para capas meteorológicas
///   - Opacidades recomendadas
///   - Paleta deportiva y moderna
///
///  Todas las capas del mapa deben usar estos valores.
/// ===============================================================

class MapaEstilos {
  // ---------------------------------------------------------------
  //  COLORES BASE DEL MAPA
  // ---------------------------------------------------------------

  /// Fondo general del mapa (gris claro deportivo)
  static const Color fondo = Color(0xFFEEF2F5);

  /// Color del agua (azul suave)
  static const Color agua = Color(0xFFB9D9FF);

  /// Terreno claro
  static const Color terreno = Color(0xFFE8EDF0);

  /// Terreno secundario
  static const Color terreno2 = Color(0xFFE3E7EA);

  /// Líneas de carreteras
  static const Color lineas = Color(0xFFC9CED3);

  /// Líneas principales
  static const Color lineasFuerte = Color(0xFFB0B5BA);

  /// Líneas de fronteras
  static const Color fronteras = Color(0xFFD0D5D9);

  // ---------------------------------------------------------------
  //  COLORES DE ESTADO (para spots, calidad, etc.)
  // ---------------------------------------------------------------

  static const Color bueno = Color(0xFF2ECC71);     // verde
  static const Color medio = Color(0xFFF1C40F);     // amarillo
  static const Color malo = Color(0xFFE74C3C);      // rojo

  // ---------------------------------------------------------------
  //  GRADIENTES PARA CAPAS METEOROLÓGICAS
  // ---------------------------------------------------------------

  /// Gradiente de viento (nudos)
  static const List<Color> viento = [
    Color(0xFFB3E5FC), // azul muy claro
    Color(0xFF4FC3F7),
    Color(0xFF0288D1),
    Color(0xFF01579B),
  ];

  /// Gradiente de olas (altura)
  static const List<Color> olas = [
    Color(0xFFBBDEFB),
    Color(0xFF64B5F6),
    Color(0xFF1E88E5),
    Color(0xFF0D47A1),
  ];

  /// Gradiente de temperatura (°C)
  static const List<Color> temperatura = [
    Color(0xFF4FC3F7), // frío
    Color(0xFFFFF176), // templado
    Color(0xFFFFA726), // cálido
    Color(0xFFE53935), // muy cálido
  ];

  /// Gradiente de lluvia (mm)
  static const List<Color> lluvia = [
    Color(0xFFE3F2FD),
    Color(0xFF90CAF9),
    Color(0xFF42A5F5),
    Color(0xFF1E88E5),
  ];

  // ---------------------------------------------------------------
  //  OPACIDADES RECOMENDADAS
  // ---------------------------------------------------------------

  static const double opacidadCapa = 0.85;
  static const double opacidadIconos = 0.95;
  static const double opacidadPanel = 0.92;

  // ---------------------------------------------------------------
  //  SOMBRAS Y BORDES
  // ---------------------------------------------------------------

  static const BoxShadow sombraSuave = BoxShadow(
    color: Colors.black26,
    blurRadius: 6,
    offset: Offset(0, 3),
  );

  static BorderRadius bordeRedondo = BorderRadius.circular(14);
}
