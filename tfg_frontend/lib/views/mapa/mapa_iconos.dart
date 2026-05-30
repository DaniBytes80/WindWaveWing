import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/views/mapa/mapa_estilos.dart';

/// ===============================================================
///  ICONOS CLEANSPORT MAP
/// ===============================================================
///
///  Este archivo define:
///   - Iconos para spots
///   - Iconos para capas meteorológicas
///   - Iconos de estado (bueno / medio / malo)
///   - Tamaños estándar
///
///  Todos los iconos del mapa deben venir de aquí.
/// ===============================================================

class MapaIconos {
  // ---------------------------------------------------------------
  //  TAMAÑOS ESTÁNDAR
  // ---------------------------------------------------------------

  static const double tamSpot = 32;
  static const double tamCapa = 28;
  static const double tamEstado = 22;

  // ---------------------------------------------------------------
  //  ICONOS DE SPOTS
  // ---------------------------------------------------------------

  static const IconData spot = Icons.location_on;

  static Icon spotIcon(Color color) {
    return Icon(
      spot,
      size: tamSpot,
      color: color,
    );
  }

  // ---------------------------------------------------------------
  //  ICONOS DE CAPAS METEOROLÓGICAS
  // ---------------------------------------------------------------

  static const IconData viento = Icons.air;
  static const IconData olas = Icons.waves;
  static const IconData temperatura = Icons.thermostat;
  static const IconData lluvia = Icons.cloudy_snowing;

  static Icon vientoIcon() => const Icon(viento, size: tamCapa, color: Colors.blueAccent);
  static Icon olasIcon() => const Icon(olas, size: tamCapa, color: Colors.blueAccent);
  static Icon temperaturaIcon() => const Icon(temperatura, size: tamCapa, color: Colors.orange);
  static Icon lluviaIcon() => const Icon(lluvia, size: tamCapa, color: Colors.blueGrey);

  // ---------------------------------------------------------------
  //  ICONOS DE ESTADO (CALIDAD DEL SPOT)
  // ---------------------------------------------------------------

  static Icon estadoBueno() =>
      Icon(Icons.circle, size: tamEstado, color: MapaEstilos.bueno);

  static Icon estadoMedio() =>
      Icon(Icons.circle, size: tamEstado, color: MapaEstilos.medio);

  static Icon estadoMalo() =>
      Icon(Icons.circle, size: tamEstado, color: MapaEstilos.malo);

  // ---------------------------------------------------------------
  //  ICONO DE ALERTA
  // ---------------------------------------------------------------

  static Icon alertaActiva() =>
      const Icon(Icons.notification_important, size: 26, color: Colors.redAccent);

  // ---------------------------------------------------------------
  //  ICONO DE MATERIAL RECOMENDADO
  // ---------------------------------------------------------------

  static Icon materialRecomendado() =>
      Icon(Icons.air, size: 26, color: Colors.deepPurple);
}
