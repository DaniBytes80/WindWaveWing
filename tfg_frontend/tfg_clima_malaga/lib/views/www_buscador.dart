import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/views/tema.dart';

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
            if (fieldController.text != controller.text) {
              fieldController.text = controller.text;
            }

            return Container(
              decoration: BoxDecoration(
                color: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: fieldController,
                focusNode: focusNode,
                onSubmitted: (valor) => onSearch(valor),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Buscar spot...",
                  hintStyle: TextStyle(color: Colors.white54),
                  prefixIcon: Icon(Icons.search, color: Colors.white70),
                  suffixIcon: null, // solo quitamos la flecha
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
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white24),
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
                          color: Colors.white,
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
