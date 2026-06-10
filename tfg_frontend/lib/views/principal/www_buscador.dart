import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/utils/tema.dart';

class WWWBuscador extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final List<String> opciones;

  const WWWBuscador({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.opciones,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return opciones.where(
          (String option) => option.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          ),
        );
      },

      onSelected: (String selection) {
        controller.text = selection;
        onSearch(selection);
      },

      fieldViewBuilder:
          (context, fieldController, focusNode, onFieldSubmitted) {
            // ⭐ Sincronización perfecta del texto y cursor
            if (fieldController.text != controller.text) {
              fieldController.value = controller.value;
            }

            return Container(
              decoration: BoxDecoration(
                color: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: EstilosWWW.colorBordeTabla.withValues(alpha: 0.7),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: fieldController,
                focusNode: focusNode,
                onSubmitted: (valor) => onSearch(valor),
                style: const TextStyle(color: EstilosWWW.colorLetra),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Buscar spot...",
                  hintStyle: TextStyle(color: EstilosWWW.colorLetra),
                  prefixIcon: Icon(Icons.search, color: EstilosWWW.colorEnlace),
                ),
              ),
            );
          },

      optionsViewBuilder: (context, onSelected, opcionesFiltradas) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.85),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(15), // ⭐ encaja visualmente
                ),
                border: Border.all(
                  color: EstilosWWW.colorBordeTabla.withValues(alpha: 0.7),
                ),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: opcionesFiltradas.length,
                itemBuilder: (context, index) {
                  final opcion = opcionesFiltradas.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(opcion),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 15,
                      ),
                      child: Text(
                        opcion,
                        style: const TextStyle(
                          color: EstilosWWW.colorLetra,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
