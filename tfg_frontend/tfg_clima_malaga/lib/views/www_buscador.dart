import 'package:flutter/material.dart';

class WWWBuscador extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final List<String> opciones; // Lista con todos los nombres de spots

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
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        // Sincronizamos tu controlador externo con el interno del Autocomplete
        if (fieldController.text != controller.text) {
          fieldController.text = controller.text;
        }

        return TextField(
          controller: fieldController,
          focusNode: focusNode,
          onSubmitted: (valor) => onSearch(valor),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: "Buscar spot...",
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => onSearch(fieldController.text),
            ),
          ),
        );
      },
    );
  }
}
