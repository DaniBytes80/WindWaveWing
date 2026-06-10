import 'package:flutter/material.dart';
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
  DateTime? _horaSeleccionada; // ✅ hora pulsada en tabla → actualiza mapa

  @override
  void initState() {
    super.initState();
    SpotManager().cargarFavoritos();
    _cargarClimaInicial();
  }

  void _toggleMenu() => setState(() => _menuAbierto = !_menuAbierto);

  Future<void> _cargarClimaInicial() async {
    final spot = SpotManager().spotActual;
    if (spot != null) {
      await SpotManager().cargarPrediccion(spot.id);
      setState(() {});
    }
  }

  Future<void> actualizarSpot(Spot spotEncontrado) async {
    final spotManager = SpotManager();
    await spotManager.cambiarSpot(spotEncontrado);
    // Al cambiar de spot volvemos a la hora actual
    setState(() => _horaSeleccionada = null);
    FocusScope.of(context).unfocus();
    _controllerBuscador.clear();
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
                // ── 0. MAPA ────────────────────────────────
                Positioned.fill(
                  child: WwwMapScreen(
                    spots: listaSpots,
                    spotActual: spotActual,
                    clima: clima,
                    capaActiva: _capaActiva,
                    horaSeleccionada: _horaSeleccionada,
                    onSpotTap: actualizarSpot,
                  ),
                ),

                // ── 1. BUSCADOR ────────────────────────────
                Positioned(
                  top: 15,
                  left: 15,
                  right: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: EstilosWWW.colorBordeTabla.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: EstilosWWW.colorBordeTabla),
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

                // ── 2. BOTÓN MENÚ ──────────────────────────
                Positioned(
                  top: 10,
                  right: 5,
                  child: GestureDetector(
                    onTap: _toggleMenu,
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

                // ── 3. MENÚ ANIMADO ────────────────────────
                MenuAnimado(
                  abierto: _menuAbierto,
                  onClose: _toggleMenu,
                  onViento: () {
                    setState(() {
                      _capaActiva = 'viento';
                      _menuAbierto = false;
                    });
                  },
                  onOlas: () {
                    setState(() {
                      _capaActiva = 'olas';
                      _menuAbierto = false;
                    });
                  },
                  onLluvia: () {
                    setState(() {
                      _capaActiva = 'lluvia';
                      _menuAbierto = false;
                    });
                  },
                  onTemp: () {
                    setState(() {
                      _capaActiva = 'temperatura';
                      _menuAbierto = false;
                    });
                  },
                ),

                // ── 4. TABLA CLIMA ─────────────────────────
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: WWWTablaClima(
                      datosMeteorologicos: clima,
                      // ✅ Cuando el usuario pulsa una hora en la
                      // tabla de horas, se actualiza el mapa
                      onHoraSeleccionada: (hora) =>
                          setState(() => _horaSeleccionada = hora),
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
