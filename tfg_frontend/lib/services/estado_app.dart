import 'package:tfg_clima_malaga/models/spot.dart';

class EstadoApp {
  static final EstadoApp _instancia = EstadoApp._internal();
  factory EstadoApp() => _instancia;
  EstadoApp._internal();
  // Variables globales de estado
  String nombreUsuarioLogueado = "Visitante";
  bool isLogueado = false;
  /*Spot spotActual = Spot(
    id: 'be36a269-6d7e-4b00-a610-693a9f46e813',
    nombre: 'Málaga Puerto',
    lat: 36.7213,
    lng: -4.4214,*/
  dynamic datosClimaSpot = {
    "temperatura": 20,
    "viento": 15,
    "oleaje": 1.5,
    "direccion_viento": "Noroeste",
    "direccion_oleaje": "Oeste",
  };
  double anchoDrawer = 150.0; // Solo acceso
  double altoDrawer = 300.0; // Solo acceso
  List<Spot> listaDeSpots = [];
  // leer EstadoApp().nombreUsuarioLogueado
  // escribir EstadoApp().nombreUsuarioLogueado = "Pepe";
}
