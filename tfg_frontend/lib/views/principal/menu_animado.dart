import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/utils/tema.dart';

class MenuAnimado extends StatelessWidget {  
  final bool abierto;// Indica si el menu está abierto o cerrado
  final Function() onClose; // Callback para cerrar el menu

// Callbacks para cada opción del menú
  final VoidCallback onViento;
  final VoidCallback onOlas;
  final VoidCallback onLluvia;
  final VoidCallback onTemp;

  const MenuAnimado({
    // Constructor del widget MenuAnimado
    super.key,
    required this.abierto,
    required this.onClose,
    required this.onViento,
    required this.onOlas,
    required this.onLluvia,
    required this.onTemp,
  });

  @override
  Widget build(BuildContext context) {
    // Devuelve un widget que representa el menu animado con las opciones de capas (viento, olas, lluvia, temperatura)
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      top: abierto ? 80 : 10,
      right: 15,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: abierto ? 1 : 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _item("Temperatura", "assets/icons/icoTemperatura.gif", () {
              onTemp();
              onClose();
            }),
            const SizedBox(height: 10),

            _item("Lluvia", "assets/icons/icoLluvia.gif", () {
              onLluvia();
              onClose();
            }),
            const SizedBox(height: 10),

            _item("Viento", "assets/icons/icoViento.gif", () {
              onViento();
              onClose();
            }),
            const SizedBox(height: 10),

            _item("Olas", "assets/icons/icoOla.gif", () {
              onOlas();
              onClose();
            }),
          ],
        ),
      ),
    );
  }

  Widget _item(String texto, String icono, Function() accion) {
    // Devuelve un widget que representa un item del menu animado, con texto y icono, y que ejecuta la accion al pulsarlo
    return GestureDetector(
      onTap: accion,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            texto,
            style: TextStyle(
              color: EstilosWWW.colorLetraMenuMapa,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(width: 8),

          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: EstilosWWW.colorLetraMenuMapa,
                width: 1.2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(icono, fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }
}
