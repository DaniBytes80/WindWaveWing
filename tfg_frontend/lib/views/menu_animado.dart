import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/views/tema.dart';

class MenuAnimado extends StatelessWidget {
  final bool abierto;
  final Function() onClose;

  const MenuAnimado({super.key, required this.abierto, required this.onClose});

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
            _item("Temperatura", "assets/images/icoTemperatura.gif"),
            const SizedBox(height: 10),
            _item("Lluvia", "assets/images/icoLluvia.gif"),
            const SizedBox(height: 10),
            _item("Viento", "assets/images/icoViento.gif"),
            const SizedBox(height: 10),
            _item("Olas", "assets/images/icoOla.gif"),
          ],
        ),
      ),
    );
  }

  Widget _item(String texto, String icono) {
    return GestureDetector(
      onTap: onClose,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ⭐ TEXTO EN AZUL DEL TEMA
          Text(
            texto,
            style: TextStyle(
              color: EstilosWWW.colorLetraMenuMapa,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(width: 8),

          // ⭐ ICONO 35x35 CUADRADO CON ESQUINAS REDONDEADAS Y BORDE FINO
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
