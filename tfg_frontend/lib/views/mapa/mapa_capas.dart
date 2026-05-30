import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter/material.dart';

class MapaCapas {
  final MapLibreMapController controller;

  MapaCapas(this.controller);

  // ⭐ Inicializa todas las capas (las crea pero ocultas)
  Future<void> inicializarCapas() async {
    try {
      // Capa de viento (vector tiles o raster)
      await controller.addSource(
        "viento-source",
        const RasterSourceProperties(tiles: [], tileSize: 256),
      );

      await controller.addLayer(
        "viento-source",
        "viento-layer",
        const RasterLayerProperties(visibility: "none", rasterOpacity: 0.85),
      );

      // Capa de olas
      await controller.addSource(
        "olas-source",
        const RasterSourceProperties(tiles: [], tileSize: 256),
      );

      await controller.addLayer(
        "olas-source",
        "olas-layer",
        const RasterLayerProperties(visibility: "none", rasterOpacity: 0.85),
      );

      // Capa de temperatura
      await controller.addSource(
        "temp-source",
        const RasterSourceProperties(tiles: [], tileSize: 256),
      );

      await controller.addLayer(
        "temp-source",
        "temp-layer",
        const RasterLayerProperties(visibility: "none", rasterOpacity: 0.85),
      );

      // Capa de lluvia
      await controller.addSource(
        "lluvia-source",
        const RasterSourceProperties(tiles: [], tileSize: 256),
      );

      await controller.addLayer(
        "lluvia-source",
        "lluvia-layer",
        const RasterLayerProperties(visibility: "none", rasterOpacity: 0.85),
      );
    } catch (e) {
      debugPrint("Error inicializando capas: $e");
    }
  }

  // ⭐ Oculta todas las capas
  Future<void> ocultarTodas() async {
    await controller.setLayerVisibility("viento-layer", "none" as bool);
    await controller.setLayerVisibility("olas-layer", "none" as bool);
    await controller.setLayerVisibility("temp-layer", "none" as bool);
    await controller.setLayerVisibility("lluvia-layer", "none" as bool);
  }

  // ⭐ Mostrar capa de viento
  Future<void> mostrarViento() async {
    await ocultarTodas();
    await controller.setLayerVisibility("viento-layer", "visible" as bool);
  }

  // ⭐ Mostrar capa de olas
  Future<void> mostrarOlas() async {
    await ocultarTodas();
    await controller.setLayerVisibility("olas-layer", "visible" as bool);
  }

  // ⭐ Mostrar capa de temperatura
  Future<void> mostrarTemperatura() async {
    await ocultarTodas();
    await controller.setLayerVisibility("temp-layer", "visible" as bool);
  }

  // ⭐ Mostrar capa de lluvia
  Future<void> mostrarLluvia() async {
    await ocultarTodas();
    await controller.setLayerVisibility("lluvia-layer", "visible" as bool);
  }
}
