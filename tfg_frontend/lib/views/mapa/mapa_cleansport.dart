import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:tfg_clima_malaga/views/mapa/mapa_menu.dart';
import 'package:tfg_clima_malaga/views/mapa/mapa_fuentes.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';

class MapaCleanSport extends StatefulWidget {
  final double lat;
  final double lng;

  const MapaCleanSport({super.key, required this.lat, required this.lng});

  @override
  State<MapaCleanSport> createState() => _MapaCleanSportState();
}

class _MapaCleanSportState extends State<MapaCleanSport> {
  MapLibreMapController? _controller;
  late _MapaCapas capas;

  String modoActual = "viento";

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ⭐ MAPA BASE MAPLIBRE
        MapLibreMap(
          styleString: 'assets/mapa/cleansport_style.json',
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.lat, widget.lng),
            zoom: 11.5,
          ),
          onMapCreated: (controller) async {
            _controller = controller;
            capas = _MapaCapas(controller);

            await capas.inicializarCapas();
            await _cargarFuenteInicial();
            await capas.mostrarViento(); // modo por defecto
          },
        ),

        // ⭐ BOTÓN DEL MENÚ DEL MAPA
        Positioned(
          top: 15,
          right: 15,
          child: GestureDetector(
            onTap: () async {
              final modo = await showDialog(
                context: context,
                builder: (_) => const MapaMenu(),
              );

              if (modo != null) {
                setState(() => modoActual = modo);
                await _cambiarModo(modo);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Image.network(
                'https://okflmihhfryuwgfqiqen.supabase.co/storage/v1/object/public/WindWaveWing/wwwIcono2.png',
                width: 28,
                height: 28,
                errorBuilder: (context, error, stack) =>
                    const Icon(Icons.map, size: 28),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ⭐ CARGA INICIAL DE FUENTE SEGÚN SPOT
  Future<void> _cargarFuenteInicial() async {
    final spot = SpotManager().spotActual;
    if (spot == null) return;

    final fuente = MapaFuentes.fuentePara(spot, "viento");
    final url = MapaFuentes.urlTiles(fuente, "viento");

    await capas.actualizarFuente("viento-source", url);
  }

  // ⭐ CAMBIO DE CAPAS SEGÚN MODO
  Future<void> _cambiarModo(String modo) async {
    if (_controller == null) return;

    final spot = SpotManager().spotActual;
    if (spot == null) return;

    // 1. Seleccionar fuente según variable y ubicación
    final fuente = MapaFuentes.fuentePara(spot, modo);
    final url = MapaFuentes.urlTiles(fuente, modo);

    // 2. Actualizar la fuente correspondiente
    switch (modo) {
      case "viento":
        await capas.actualizarFuente("viento-source", url);
        await capas.mostrarViento();
        break;

      case "olas":
        await capas.actualizarFuente("olas-source", url);
        await capas.mostrarOlas();
        break;

      case "temperatura":
        await capas.actualizarFuente("temp-source", url);
        await capas.mostrarTemperatura();
        break;

      case "lluvia":
        await capas.actualizarFuente("lluvia-source", url);
        await capas.mostrarLluvia();
        break;
    }
  }
}

//
// ─────────────────────────────────────────────────────────────
//   INTERNAL CLASS: CONTROLADOR DE CAPAS
// ─────────────────────────────────────────────────────────────
//

class _MapaCapas {
  final MapLibreMapController controller;

  _MapaCapas(this.controller);

  // ⭐ Inicializa todas las capas (creadas pero ocultas)
  Future<void> inicializarCapas() async {
    try {
      // Capa de viento
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

  // ⭐ Cambia dinámicamente la URL de tiles de una fuente
  Future<void> actualizarFuente(String sourceId, String nuevaUrl) async {
    try {
      // 1. Eliminar la fuente anterior si existe
      final sources = await controller.getSourceIds();
      if (sources.contains(sourceId)) {
        await controller.removeSource(sourceId);
      }

      // 2. Crear la nueva fuente con la URL actualizada
      await controller.addSource(
        sourceId,
        RasterSourceProperties(tiles: [nuevaUrl], tileSize: 256),
      );

      debugPrint("Fuente $sourceId actualizada a: $nuevaUrl");
    } catch (e) {
      debugPrint("Error al actualizar fuente $sourceId: $e");
    }
  }

  // ⭐ Oculta todas las capas
  Future<void> _ocultarTodas() async {
    await controller.setLayerVisibility("viento-layer", "none" as bool);
    await controller.setLayerVisibility("olas-layer", "none" as bool);
    await controller.setLayerVisibility("temp-layer", "none" as bool);
    await controller.setLayerVisibility("lluvia-layer", "none" as bool);
  }

  // ⭐ Mostrar capa de viento
  Future<void> mostrarViento() async {
    await _ocultarTodas();
    await controller.setLayerVisibility("viento-layer", "visible" as bool);
  }

  // ⭐ Mostrar capa de olas
  Future<void> mostrarOlas() async {
    await _ocultarTodas();
    await controller.setLayerVisibility("olas-layer", "visible" as bool);
  }

  // ⭐ Mostrar capa de temperatura
  Future<void> mostrarTemperatura() async {
    await _ocultarTodas();
    await controller.setLayerVisibility("temp-layer", "visible" as bool);
  }

  // ⭐ Mostrar capa de lluvia
  Future<void> mostrarLluvia() async {
    await _ocultarTodas();
    await controller.setLayerVisibility("lluvia-layer", "visible" as bool);
  }
}
