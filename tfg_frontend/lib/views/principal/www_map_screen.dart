import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:tfg_clima_malaga/models/spot.dart';
import 'package:tfg_clima_malaga/models/clima_modelo.dart';
// ✅ FIX: import explícito de MapGridData y MapGridRepository
import 'package:tfg_clima_malaga/repositories/map_grid_repository.dart';
import 'package:tfg_clima_malaga/domain/interpolators/weather_point.dart';
import 'package:tfg_clima_malaga/views/layers/wind_layer.dart';
import 'package:tfg_clima_malaga/views/layers/wave_layer.dart';
import 'package:tfg_clima_malaga/views/layers/rain_layer.dart';
import 'package:tfg_clima_malaga/views/layers/temp_layer.dart';

class WwwMapScreen extends StatefulWidget {
  final List<Spot>          spots;
  final Spot                spotActual;
  final List<ClimaModelo>?  clima;
  final String              capaActiva;
  final DateTime?           horaSeleccionada;
  final void Function(Spot) onSpotTap;

  const WwwMapScreen({
    super.key,
    required this.spots,
    required this.spotActual,
    required this.clima,
    required this.capaActiva,
    required this.onSpotTap,
    this.horaSeleccionada,
  });

  @override
  State<WwwMapScreen> createState() => _WwwMapScreenState();
}

class _WwwMapScreenState extends State<WwwMapScreen>
    with SingleTickerProviderStateMixin {

  late final MapController _mapController;
  final _gridRepo = MapGridRepository();

  MapGridData _gridData = MapGridData.empty();
  bool        _cargando = false;
  String?     _errorMsg;

  // Para evitar recargas continuas mientras el usuario mueve el mapa
  DateTime _ultimaCarga = DateTime(2000);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarGrid());
  }

  @override
  void didUpdateWidget(WwwMapScreen old) {
    super.didUpdateWidget(old);
    if (old.spotActual.id != widget.spotActual.id) {
      _mapController.move(
        LatLng(widget.spotActual.lat, widget.spotActual.lng), 11.5,
      );
    }
  }

  Future<void> _cargarGrid() async {
    if (_cargando || !mounted) return;

    // Evitar recarga si hace menos de 30 segundos que se cargó
    final ahora = DateTime.now();
    if (ahora.difference(_ultimaCarga).inSeconds < 30) return;

    setState(() { _cargando = true; _errorMsg = null; });

    try {
      final camara = _mapController.camera;
      final delta  = _deltaParaZoom(camara.zoom);
      final centro = camara.center;

      final grid = await _gridRepo.obtenerGrid(
        minLat: centro.latitude  - delta,
        maxLat: centro.latitude  + delta,
        minLng: centro.longitude - delta,
        maxLng: centro.longitude + delta,
      );

      _ultimaCarga = DateTime.now();

      if (mounted) {
        setState(() {
          _gridData = grid;
          _errorMsg = grid.isEmpty
              ? 'Sin datos — ejecuta ingesta_grid en GitHub Actions'
              : null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMsg = 'Error cargando mapa');
      debugPrint('❌ _cargarGrid: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  double _deltaParaZoom(double zoom) {
    if (zoom < 4)  return 25.0;
    if (zoom < 6)  return 15.0;
    if (zoom < 8)  return 8.0;
    if (zoom < 10) return 4.0;
    return 2.0;
  }

  List<WeatherPoint> _puntosParaCapa() {
    switch (widget.capaActiva) {
      case 'viento':      return _gridData.wind;
      case 'olas':        return _gridData.wave;
      case 'lluvia':      return _gridData.rain;
      case 'temperatura': return _gridData.temp;
      default:            return _gridData.wind;
    }
  }

  Widget _buildMarker(Spot spot) {
    final isActual = spot.id == widget.spotActual.id;
    return GestureDetector(
      onTap: () => widget.onSpotTap(spot),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width:  isActual ? 36 : 28,
        height: isActual ? 36 : 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          border: isActual
              ? Border.all(color: Colors.amber, width: 1.5)
              : null,
        ),
        child: Center(
          child: Image.asset(
            _iconoParaSpot(spot),
            width:  isActual ? 28 : 22,
            height: isActual ? 28 : 22,
            fit: BoxFit.contain,
            errorBuilder: (_, e, __) => Icon(  // ✅ FIX: _ no __ para unused
              Icons.place,
              size:  isActual ? 24 : 18,
              color: isActual ? Colors.amber : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  String _iconoParaSpot(Spot spot) {
    switch (spot.icono?.toLowerCase()) {
      case 'kitesurf':  return 'assets/icons/kitesurf.png';
      case 'windsurf':  return 'assets/icons/icono_windsurf.png';
      case 'surf':      return 'assets/icons/surf.png';
      default:          return 'assets/icons/icon.png';
    }
  }

  String _formatHora(DateTime dt) {
    final l = dt.toLocal();
    return '${l.day}/${l.month}  ${l.hour.toString().padLeft(2, '0')}:00';
  }

  @override
  Widget build(BuildContext context) {
    final puntos = _puntosParaCapa();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(
                widget.spotActual.lat, widget.spotActual.lng),
            initialZoom:   11.5,
            minZoom:        3.0,
            maxZoom:       16.0,
            // ✅ FIX: onMapIdle no existe en flutter_map ^7
            // Usamos onMapEvent y filtramos solo cuando termina el movimiento
            onMapEvent: (event) {
              if (event is MapEventMoveEnd ||
                  event is MapEventScrollWheelZoom ||
                  event is MapEventDoubleTapZoomEnd) {
                _cargarGrid();
              }
            },
          ),
          children: [

            // 1. Tiles base OSM
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.danibytes.windwavewing',
              subdomains: const ['a', 'b', 'c'],
            ),

            // 2. Capa meteorológica activa
            if (!_cargando && !_gridData.isEmpty && puntos.isNotEmpty) ...[
              if (widget.capaActiva == 'viento')
                WindLayer(points: puntos, vsync: this),
              if (widget.capaActiva == 'olas')
                WaveLayer(points: puntos),
              if (widget.capaActiva == 'lluvia')
                RainLayer(points: puntos),
              if (widget.capaActiva == 'temperatura')
                TempLayer(points: puntos),
            ],

            // 3. Marcadores de spots
            MarkerLayer(
              markers: widget.spots.map((spot) => Marker(
                point:  LatLng(spot.lat, spot.lng),
                width:  40,
                height: 40,
                child:  _buildMarker(spot),
              )).toList(),
            ),
          ],
        ),

        // Indicador de carga
        if (_cargando)
          Positioned(
            top: 8, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Text('Cargando mapa...',
                        style: TextStyle(
                            color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),

        // Etiqueta hora seleccionada
        if (widget.horaSeleccionada != null)
          Positioned(
            top: 8, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatHora(widget.horaSeleccionada!),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Error
        if (!_cargando && _errorMsg != null)
          Positioned(
            top: 8, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_errorMsg!,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }
}
