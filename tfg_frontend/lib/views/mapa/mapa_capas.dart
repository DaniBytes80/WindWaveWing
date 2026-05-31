import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:tfg_clima_malaga/models/spot.dart';
import 'package:tfg_clima_malaga/views/mapa/mapa_fuentes.dart';

/// ===============================================================
///   CONTROLADOR DE CAPAS METEOROLÓGICAS (compatible MapLibre 0.26)
/// ===============================================================
///
///  - Recarga dinámica de tiles eliminando y recreando fuentes
///  - Capas: viento, olas, temperatura, lluvia
///  - Opacidad estilo Windy (0.85)
///  - Visibilidad correcta ("visible" / "none")
///
/// ===============================================================

class MapaCapas {
  final MapLibreMapController controller;

  MapaCapas(this.controller);

  // ---------------------------------------------------------------
  //  Inicializa las capas (vacías y ocultas)
  // ---------------------------------------------------------------
  Future<void> inicializarCapas() async {
    await _crearFuenteYCapa("viento");
    await _crearFuenteYCapa("olas");
    await _crearFuenteYCapa("temperatura");
    await _crearFuenteYCapa("lluvia");
  }

  // ---------------------------------------------------------------
  //  Crea una fuente + capa vacía (tiles = [])
  // ---------------------------------------------------------------
  Future<void> _crearFuenteYCapa(String variable) async {
    final sourceId = "$variable-source";
    final layerId = "$variable-layer";

    try {
      // Si ya existen, las eliminamos
      await controller.removeLayer(layerId).catchError((_) {});
      await controller.removeSource(sourceId).catchError((_) {});

      // Creamos la fuente vacía
      await controller.addSource(
        sourceId,
        const RasterSourceProperties(tiles: [], tileSize: 256),
      );

      // Creamos la capa
      await controller.addLayer(
        sourceId,
        layerId,
        const RasterLayerProperties(visibility: "none", rasterOpacity: 0.85),
      );
    } catch (e) {
      debugPrint("Error creando fuente/capa $variable: $e");
    }
  }

  // ---------------------------------------------------------------
  //  Recarga la fuente con la URL correcta
  // ---------------------------------------------------------------
  Future<void> _recargarFuente(Spot spot, String variable) async {
    final sourceId = "$variable-source";
    final layerId = "$variable-layer";

    final fuente = MapaFuentes.fuentePara(spot, variable);
    final url = MapaFuentes.urlTiles(fuente, variable);

    // Eliminamos y recreamos la fuente con la nueva URL
    await controller.removeLayer(layerId).catchError((_) {});
    await controller.removeSource(sourceId).catchError((_) {});

    await controller.addSource(
      sourceId,
      RasterSourceProperties(tiles: [url], tileSize: 256),
    );

    await controller.addLayer(
      sourceId,
      layerId,
      const RasterLayerProperties(visibility: "visible", rasterOpacity: 0.85),
    );
  }

  // ---------------------------------------------------------------
  //  Oculta todas las capas
  // ---------------------------------------------------------------
  Future<void> ocultarTodas() async {
    await controller.setLayerVisibility("viento-layer", "none" as bool);
    await controller.setLayerVisibility("olas-layer", "none" as bool);
    await controller.setLayerVisibility("temperatura-layer", "none" as bool);
    await controller.setLayerVisibility("lluvia-layer", "none" as bool);
  }

  // ---------------------------------------------------------------
  //  Mostrar capas (Windy-like)
  // ---------------------------------------------------------------
  Future<void> mostrarViento(Spot spot) async {
    await ocultarTodas();
    await _recargarFuente(spot, "viento");
  }

  Future<void> mostrarOlas(Spot spot) async {
    await ocultarTodas();
    await _recargarFuente(spot, "olas");
  }

  Future<void> mostrarTemperatura(Spot spot) async {
    await ocultarTodas();
    await _recargarFuente(spot, "temperatura");
  }

  Future<void> mostrarLluvia(Spot spot) async {
    await ocultarTodas();
    await _recargarFuente(spot, "lluvia");
  }
}
