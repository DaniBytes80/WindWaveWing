import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tfg_clima_malaga/models/spot.dart';
import 'package:tfg_clima_malaga/services/user_manager.dart';
import 'package:tfg_clima_malaga/utils/auth_gate.dart';
import 'package:tfg_clima_malaga/views/tema.dart';
import 'package:tfg_clima_malaga/views/www_buscador.dart';
import 'package:tfg_clima_malaga/views/www_tabla_clima.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';

class VentanaInicioUsuario extends StatefulWidget {
  const VentanaInicioUsuario({super.key});
  @override
  State<VentanaInicioUsuario> createState() => _VentanaInicioUsuarioState();
}

class _VentanaInicioUsuarioState extends State<VentanaInicioUsuario> {
  late GoogleMapController mapController;
  final TextEditingController _controllerBuscador = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarClimaInicial();
  }

  Future<void> _cargarClimaInicial() async {
    final spot = SpotManager().spotActual;
    await SpotManager().cargarPrediccion(spot.id);
    setState(() {});
  }

  Future<void> actualizarSpot(Spot spotEncontrado) async {
    await SpotManager().cambiarSpot(spotEncontrado);

    mapController.animateCamera(
      CameraUpdate.newLatLng(LatLng(spotEncontrado.lat, spotEncontrado.lng)),
    );

    FocusScope.of(context).unfocus();
    _controllerBuscador.clear();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final spotActual = SpotManager().spotActual;
    final listaSpots = SpotManager().spots;
    final clima = SpotManager().prediccionActual;

    void onMapCreated(GoogleMapController controller) {
      mapController = controller;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(spotActual.nombre, style: EstilosWWW.tituloApp),
        backgroundColor: EstilosWWW.colorFondoPantalla,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      drawer: Drawer(
        width: 280,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.only(top: 100),
            height: 500,
            decoration: BoxDecoration(
              color: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.9),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  "Menú usuario",
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
                  "Email: ${UserManager().perfil?.email ?? 'No logueado'}",
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await UserManager().logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthGate()),
                        (_) => false,
                      );
                    }
                  },
                  child: const Text("Cerrar sesión"),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(spotActual.lat, spotActual.lng),
              zoom: 12,
            ),
          ),

          Positioned(
            top: 15,
            left: 15,
            right: 15,
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

                  final spot = SpotManager().buscarSpot(valor);
                  if (spot != null) {
                    actualizarSpot(spot);
                  } else {
                    debugPrint('Spot no encontrado: $valor');
                  }
                },
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: WWWTablaClima(datosMeteorologicos: clima),
            ),
          ),
        ],
      ),
    );
  }
}
