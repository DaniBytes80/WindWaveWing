import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/models/material_usuario.dart';
import 'package:tfg_clima_malaga/services/material_service.dart';

class EditarMaterialPage extends StatefulWidget {
  final MaterialUsuario material;

  const EditarMaterialPage({super.key, required this.material});

  @override
  State<EditarMaterialPage> createState() => _EditarMaterialPageState();
}

class _EditarMaterialPageState extends State<EditarMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final MaterialService _service = MaterialService();

  // Campos editables
  String? _disciplina;
  String? _tipo;
  String? _nombre;
  String? _marca;
  String? _modelo;
  int? _ano;
  String? _medida;
  String? _descripcion;

  // DISCIPLINAS PERMITIDAS
  final List<String> disciplinas = [
    "kitesurf",
    "wingfoil",
    "windsurf",
    "surf",
    "vela ligera",
  ];

  // TIPOS POR DISCIPLINA
  final Map<String, List<String>> tiposPorDisciplina = {
    "surf": ["tabla", "foil"],
    "wingfoil": ["tabla", "ala", "foil"],
    "kitesurf": ["cometa", "tabla", "foil"],
    "windsurf": ["tabla", "vela", "botavara", "mástil", "foil"],
    "vela ligera": ["tipo de barco"],
  };

  // CLASES DE VELA LIGERA
  final List<String> clasesBarco = [
    "Optimist",
    "Cadete",
    "Laser",
    "Finn",
    "Star",
    "Sunfish",
    "Europa",
    "420",
    "470",
    "Snipe",
    "Vaurien",
    "Raquero",
    "HobieCat",
    "29er",
    "49er",
    "Nacra 17",
    "Tornado",
    "Rs Aero",
    "Patin",
    "Crucero",
    "Dragón",
    "Soling",
    "Vela latina",
  ];

  @override
  void initState() {
    super.initState();

    // Precargar datos del material
    _disciplina = widget.material.disciplina;
    _tipo = widget.material.tipo;
    _nombre = widget.material.nombre;
    _marca = widget.material.marca;
    _modelo = widget.material.modelo;
    _ano = widget.material.ano;
    _medida = widget.material.medida;
    _descripcion = widget.material.descripcion;
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final actualizado = MaterialUsuario(
      id: widget.material.id,
      userId: widget.material.userId,
      disciplina: _disciplina!,
      tipo: _tipo!,
      nombre: _nombre,
      marca: _marca,
      modelo: _modelo,
      ano: _ano,
      medida: _medida,
      descripcion: _descripcion,
    );

    final ok = await _service.actualizarMaterial(actualizado);

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error actualizando material")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Material")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // DISCIPLINA
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Disciplina"),
                items: disciplinas
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                initialValue: _disciplina,
                onChanged: (v) {
                  setState(() {
                    _disciplina = v;
                    _tipo = null;
                    _medida = null;
                  });
                },
                validator: (v) =>
                    v == null ? "Selecciona una disciplina" : null,
              ),

              const SizedBox(height: 16),

              // TIPO
              if (_disciplina != null)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Tipo de material",
                  ),
                  items: tiposPorDisciplina[_disciplina]!
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  initialValue: _tipo,
                  onChanged: (v) {
                    setState(() {
                      _tipo = v;
                      _medida = null;
                    });
                  },
                  validator: (v) => v == null ? "Selecciona un tipo" : null,
                ),

              const SizedBox(height: 16),

              // ⭐ FOIL (front wing = medida)
              if (_tipo == "foil") ...[
                const Text(
                  "Datos del Foil",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  initialValue: _medida,
                  decoration: const InputDecoration(
                    labelText: "Front Wing (cm²)",
                  ),
                  onSaved: (v) => _medida = v,
                  validator: (v) =>
                      v == null || v.isEmpty ? "Introduce el front wing" : null,
                ),

                const SizedBox(height: 16),
              ],

              // ⭐ VELA LIGERA (clase = medida)
              if (_disciplina == "vela ligera" && _tipo == "tipo de barco") ...[
                const Text(
                  "Clase de barco",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Clase"),
                  items: clasesBarco
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  initialValue: _medida,
                  onChanged: (v) => setState(() => _medida = v),
                  validator: (v) =>
                      v == null ? "Selecciona una clase de barco" : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  initialValue: _marca,
                  decoration: const InputDecoration(
                    labelText: "Marca (opcional)",
                  ),
                  onSaved: (v) => _marca = v,
                ),

                const SizedBox(height: 8),

                TextFormField(
                  initialValue: _modelo,
                  decoration: const InputDecoration(
                    labelText: "Modelo (opcional)",
                  ),
                  onSaved: (v) => _modelo = v,
                ),

                const SizedBox(height: 8),

                TextFormField(
                  initialValue: _ano != null ? _ano.toString() : "",
                  decoration: const InputDecoration(labelText: "Año"),
                  keyboardType: TextInputType.number,
                  onSaved: (v) =>
                      _ano = v != null && v.isNotEmpty ? int.tryParse(v) : null,
                ),

                const SizedBox(height: 8),

                TextFormField(
                  initialValue: _descripcion,
                  decoration: const InputDecoration(labelText: "Descripción"),
                  maxLines: 3,
                  onSaved: (v) => _descripcion = v,
                ),

                const SizedBox(height: 16),
              ],

              // ⭐ CAMPOS GENERALES (excepto foil y vela ligera)
              if (_tipo != null &&
                  _tipo != "foil" &&
                  !(_disciplina == "vela ligera")) ...[
                Text(
                  "Detalles de $_tipo",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  initialValue: _marca,
                  decoration: const InputDecoration(labelText: "Marca"),
                  onSaved: (v) => _marca = v,
                ),

                const SizedBox(height: 8),

                TextFormField(
                  initialValue: _modelo,
                  decoration: const InputDecoration(labelText: "Modelo"),
                  onSaved: (v) => _modelo = v,
                ),

                const SizedBox(height: 8),

                TextFormField(
                  initialValue: _ano != null ? _ano.toString() : "",
                  decoration: const InputDecoration(labelText: "Año"),
                  keyboardType: TextInputType.number,
                  onSaved: (v) =>
                      _ano = v != null && v.isNotEmpty ? int.tryParse(v) : null,
                ),

                const SizedBox(height: 8),

                TextFormField(
                  initialValue: _medida,
                  decoration: const InputDecoration(
                    labelText: "Medida (ej: 9m, 85L, 210cm)",
                  ),
                  onSaved: (v) => _medida = v,
                ),

                const SizedBox(height: 8),

                TextFormField(
                  initialValue: _descripcion,
                  decoration: const InputDecoration(labelText: "Descripción"),
                  maxLines: 3,
                  onSaved: (v) => _descripcion = v,
                ),

                const SizedBox(height: 16),
              ],

              ElevatedButton(
                onPressed: _guardarCambios,
                child: const Text("Guardar cambios"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
