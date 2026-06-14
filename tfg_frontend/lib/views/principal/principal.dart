import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tfg_clima_malaga/models/spot.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';
import 'package:tfg_clima_malaga/services/user_manager.dart';
import 'package:tfg_clima_malaga/utils/tema.dart';
import 'package:tfg_clima_malaga/views/principal/www_buscador.dart';
import 'package:tfg_clima_malaga/views/principal/www_tabla_clima.dart';
import 'package:tfg_clima_malaga/drawer/www_drawer.dart';
import 'package:tfg_clima_malaga/views/principal/menu_animado.dart';
import 'package:tfg_clima_malaga/views/principal/webcam_viewer.dart';
import 'package:tfg_clima_malaga/views/principal/www_map_screen.dart';

class VentanaInicioUsuario extends StatefulWidget {
  const VentanaInicioUsuario({super.key});

  @override
  State<VentanaInicioUsuario> createState() => VentanaInicioUsuarioState();
}

class VentanaInicioUsuarioState extends State<VentanaInicioUsuario> {
  final TextEditingController _controllerBuscador = TextEditingController();

  bool _menuAbierto = false;
  String _capaActiva = 'viento';
  DateTime? _horaSeleccionada;

  @override
  void initState() {
    // Carga los favoritos y la predicción inicial para el spot actual al iniciar la app
    super.initState();
    SpotManager().cargarFavoritos();
    _cargarClimaInicial();
  }

  void _toggleMenu() => setState(() => _menuAbierto = !_menuAbierto);

  Future<void> _cargarClimaInicial() async {
    // Carga la predicción para el spot actual al iniciar la app
    final spot = SpotManager().spotActual;
    if (spot != null) {
      await SpotManager().cargarPrediccion(spot.id);
      setState(() {});
    }
  }

  Future<void> actualizarSpot(Spot spotEncontrado) async {
    // Cambia el spot actual y recarga la predicción para ese spot
    final spotManager = SpotManager();
    await spotManager.cambiarSpot(spotEncontrado);
    setState(() => _horaSeleccionada = null);
    FocusScope.of(context).unfocus();
    _controllerBuscador.clear();
  }

  String _labelMapa() {
    // Devuelve la etiqueta de la hora seleccionada en formato "EEE d MMM  HH:00h"
    if (_horaSeleccionada == null) return '';
    final l = _horaSeleccionada!.toLocal();
    final dia = DateFormat('EEE d MMM', 'es_ES').format(l);
    final h = l.hour.toString().padLeft(2, '0');
    return '$dia  $h:00h';
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

        return Listener(
          onPointerDown: (_) => userManager.actividadDetectada(),
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: EstilosWWW.colorFondoPantalla,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Row(
                children: [
                  GestureDetector(
                    onTap: () async =>
                        spotManager.toggleFavorito(spotActual.id),
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
                  const Spacer(),
                  if (spotActual.camUrl != null &&
                      spotActual.camUrl!.isNotEmpty)
                    GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (_) => WebcamViewer(url: spotActual.camUrl!),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.videocam,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            drawer: const WWWDrawer(),

            body: Stack(
              children: [
                // Muestra el mapa con la capa activa y los datos del clima
                // para el spot actual y la hora seleccionada
                Positioned.fill(
                  child: WwwMapScreen(
                    // Muestra el mapa con la capa activa y los datos del clima
                    spots: listaSpots, // lista de spots para mostrar en el mapa
                    spotActual: spotActual, // spot actual seleccionado
                    clima: clima, // datos meteorológicos del spot actual
                    capaActiva:
                        _capaActiva, // capa activa (viento, olas, lluvia, temperatura)
                    horaSeleccionada:
                        _horaSeleccionada, // hora seleccionada para mostrar los datos del clima
                    onSpotTap:
                        actualizarSpot, // al tocar un spot en el mapa, se actualiza el spot actual
                  ),
                ),

                // Muestra el buscador y el botón de menú en la parte superior
                Positioned(
                  top: 15,
                  left: 15,
                  right: 15,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: EstilosWWW.colorBordeTabla.withValues(
                              alpha: 0.9,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: EstilosWWW.colorBordeTabla,
                            ),
                          ),
                          child: WWWBuscador(
                            controller: _controllerBuscador,
                            opciones: listaSpots.map((s) => s.nombre).toList(),
                            onSearch: (String valor) {
                              if (valor.trim().isEmpty) return;
                              final spot = spotManager.buscarSpot(valor);
                              if (spot != null) actualizarSpot(spot);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Botón menú de capas que llama a MenuAnimado
                      GestureDetector(
                        onTap: _toggleMenu,
                        child: Image.asset(
                          'assets/images/wwwIcono2.png',
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ],
                  ),
                ),

                // Muestra el menu animado con las opciones de capas (viento, olas, lluvia, temperatura)
                // Se comunica con www_map_screen.dart para cambiar la capa activa.
                MenuAnimado(
                  abierto: _menuAbierto,
                  onClose: _toggleMenu,
                  onViento: () => setState(() {
                    _capaActiva = 'viento';
                    _menuAbierto = false;
                  }),
                  onOlas: () => setState(() {
                    _capaActiva = 'olas';
                    _menuAbierto = false;
                  }),
                  onLluvia: () => setState(() {
                    _capaActiva = 'lluvia';
                    _menuAbierto = false;
                  }),
                  onTemp: () => setState(() {
                    _capaActiva = 'temperatura';
                    _menuAbierto = false;
                  }),
                ),

                // Presenta la tabla de clima en la parte inferior, con la hora seleccionada encima de la tabla.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Muestra la hora seleccionada en un contenedor con estilo, y permite deseleccionarla al tocarla.
                        if (_horaSeleccionada != null)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _horaSeleccionada = null),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.90),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.black87,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _labelMapa(),
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Muestra la tabla de clima con los datos meteorológicos del spot actual
                        WWWTablaClima(
                          datosMeteorologicos: clima,
                          onHoraSeleccionada: (hora) =>
                              setState(() => _horaSeleccionada = hora),
                        ),
                      ],
                    ),
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
