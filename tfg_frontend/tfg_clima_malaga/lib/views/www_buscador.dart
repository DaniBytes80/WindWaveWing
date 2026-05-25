import 'package:flutter/material.dart';

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

      // Cuando el usuario selecciona un spot
      onSelected: (String selection) {
        controller.text = selection;
        onSearch(selection);
      },

      // ============================
      //  CAMPO DE TEXTO PERSONALIZADO
      // ============================
      fieldViewBuilder:
          (context, fieldController, focusNode, onFieldSubmitted) {
            if (fieldController.text != controller.text) {
              fieldController.text = controller.text;
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.60),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: fieldController,
                focusNode: focusNode,
                onSubmitted: (valor) => onSearch(valor),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Buscar spot...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white70,
                    ),
                    onPressed: () => onSearch(fieldController.text),
                  ),
                ),
              ),
            );
          },

      // ============================
      //  MENÚ DESPLEGABLE PERSONALIZADO
      // ============================
      optionsViewBuilder: (context, onSelected, opcionesFiltradas) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
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
