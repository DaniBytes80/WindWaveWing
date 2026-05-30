import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:tfg_clima_malaga/models/spot.dart';
import 'package:tfg_clima_malaga/views/tema.dart';
import 'package:tfg_clima_malaga/views/www_buscador.dart';
import 'package:tfg_clima_malaga/views/www_tabla_clima.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';
import 'package:tfg_clima_malaga/services/user_manager.dart';
import 'package:tfg_clima_malaga/drawer/www_drawer.dart';

import 'package:tfg_clima_malaga/views/menu_animado.dart';

class VentanaInicioUsuario extends StatefulWidget {
  const VentanaInicioUsuario({super.key});

  @override
  State<VentanaInicioUsuario> createState() => VentanaInicioUsuarioState();
}

class VentanaInicioUsuarioState extends State<VentanaInicioUsuario> {
  MapLibreMapController? mapController;
  final TextEditingController _controllerBuscador = TextEditingController();

  bool menuAbierto = false;

  void toggleMenu() {
    setState(() {
      menuAbierto = !menuAbierto;
    });
  }

  @override
  void initState() {
    super.initState();
    SpotManager().cargarFavoritos();
    _cargarClimaInicial();
  }

  Future<void> _cargarClimaInicial() async {
    final spot = SpotManager().spotActual;
    if (spot != null) {
      await SpotManager().cargarPrediccion(spot.id);
      setState(() {});
    }
  }

  // ⭐ SE EJECUTA SOLO CUANDO EL ESTILO ESTÁ LISTO
  Future<void> _pintarMarcadoresIniciales() async {
    if (mapController == null) return;

    final bytes = await rootBundle.load('assets/images/pointSurf.png');
    final list = bytes.buffer.asUint8List();

    await mapController!.addImage('spot-icon', list);

    final spots = SpotManager().spots;

    for (final s in spots) {
      await mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(s.lat, s.lng),
          iconImage: 'spot-icon',
          iconSize: 0.40,
        ),
      );
    }
  }

  // ⭐ CAMBIAR SPOT
  Future<void> actualizarSpot(Spot spotEncontrado) async {
    final spotManager = SpotManager();

    await spotManager.cambiarSpot(spotEncontrado);

    if (mounted && mapController != null) {
      mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(spotEncontrado.lat, spotEncontrado.lng),
            zoom: 12.5,
          ),
        ),
      );

      await mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(spotEncontrado.lat, spotEncontrado.lng),
          iconImage: 'spot-icon',
          iconSize: 0.60,
        ),
      );
    }

    FocusScope.of(context).unfocus();
    _controllerBuscador.clear();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final userManager = UserManager();
    final spotManager = SpotManager();

    return AnimatedBuilder(
      animation: Listenable.merge([userManager, spotManager]),
      builder: (context, _) {
        final spotActual = spotManager.spotActual;

        if (spotActual == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final listaSpots = spotManager.spots;
        final clima = spotManager.prediccionActual;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => userManager.actividadDetectada(),
          onPanDown: (_) => userManager.actividadDetectada(),

          child: Scaffold(
            appBar: AppBar(
              backgroundColor: EstilosWWW.colorFondoPantalla,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await spotManager.toggleFavorito(spotActual.id);
                    },
                    child: Icon(
                      spotManager.favoritos.contains(spotActual.id)
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.yellow,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(spotActual.nombre, style: EstilosWWW.tituloApp),
                ],
              ),
            ),

            drawer: const WWWDrawer(),

            body: Stack(
              children: [
                // ⭐ MAPA MAPLIBRE
                MapLibreMap(
                  styleString: 'assets/mapa/cleansport_style.json',
                  initialCameraPosition: CameraPosition(
                    target: LatLng(spotActual.lat, spotActual.lng),
                    zoom: 11.5,
                  ),

                  // ⭐ AQUÍ ESTÁ LA CLAVE: onStyleLoaded
                  onMapCreated: (controller) {
                    mapController = controller;
                  },

                  onStyleLoadedCallback: () async {
                    await _pintarMarcadoresIniciales();
                  },

                  rotateGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                ),

                // ⭐ BUSCADOR
                Positioned(
                  top: 15,
                  left: 15,
                  right: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: EstilosWWW.colorLetra,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: WWWBuscador(
                      controller: _controllerBuscador,
                      opciones: listaSpots.map((s) => s.nombre).toList(),
                      onSearch: (String valor) {
                        if (valor.trim().isEmpty) return;

                        final spot = spotManager.buscarSpot(valor);
                        if (spot != null) {
                          actualizarSpot(spot);
                        }
                      },
                    ),
                  ),
                ),

                // ⭐ BOTÓN DEL MENÚ DEL MAPA
                Positioned(
                  top: 10,
                  right: 5,
                  child: GestureDetector(
                    onTap: toggleMenu,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/images/wwwIcono2.png',
                        width: 50,
                        height: 50,
                      ),
                    ),
                  ),
                ),

                // ⭐ MENÚ ANIMADO
                MenuAnimado(abierto: menuAbierto, onClose: toggleMenu),

                // ⭐ TABLA CLIMA
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: WWWTablaClima(datosMeteorologicos: clima),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
