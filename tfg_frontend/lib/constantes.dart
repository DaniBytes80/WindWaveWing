import 'package:flutter/material.dart' show Icons, IconData;
// Clase que contiene constantes utilizadas en la aplicación
class Constantes {
  static const String urlBase = 'https://api.themoviedb.org/3';
  static const String apiKey =
      'd1c8e9b0c5a7e1f2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t1u2v3w4x5y6z7';
  static Map<String, IconData> iconosDeportes = {
    "Windsurf": Icons.sailing,
    "Kitesurf": Icons.kayaking,
    "Wingfoil": Icons.airplanemode_active,
    "Surf": Icons.surfing,
    "Vela": Icons.directions_boat,
  };
}
