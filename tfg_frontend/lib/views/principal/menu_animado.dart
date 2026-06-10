import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/utils/tema.dart';

class MenuAnimado extends StatelessWidget {
  final bool abierto;
  final Function() onClose;

  // ⭐ Callbacks reales para activar capas (los pasa principal.dart)
  final VoidCallback onViento;
  final VoidCallback onOlas;
  final VoidCallback onLluvia;
  final VoidCallback onTemp;

  const MenuAnimado({
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
