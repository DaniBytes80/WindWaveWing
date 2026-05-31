import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/models/material_usuario.dart';
import 'package:tfg_clima_malaga/services/material_service.dart';

class CrearMaterialPage extends StatefulWidget {
  const CrearMaterialPage({super.key});

  @override
  State<CrearMaterialPage> createState() => _CrearMaterialPageState();
}

class _CrearMaterialPageState extends State<CrearMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final MaterialService _service = MaterialService();

  // Campos del formulario
  String? _disciplina;
  String? _tipo;
  String? _nombre;
  String? _marca;
  String? _modelo;
  int? _ano;
  String? _medida;
  String? _descripcion;

  final List<String> disciplinas = [
    "kitesurf",
    "wingfoil",
    "windsurf",
    "surf",
    "vela ligera",
  ];

  final Map<String, List<String>> tiposPorDisciplina = {
    "surf": ["tabla", "foil"],
    "wingfoil": ["tabla", "ala", "foil"],
    "kitesurf": ["cometa", "tabla", "foil"],
    "windsurf": ["tabla", "vela", "botavara", "mástil", "foil"],
    "vela ligera": ["tipo de barco"],
  };

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

  Future<void> _guardarMaterial() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final userId = _service.supabase.auth.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: usuario no identificado")),
      );
      return;
    }

    final material = MaterialUsuario(
      userId: userId,
      disciplina: _disciplina!,
      tipo: _tipo!,
      nombre: _nombre,
      marca: _marca,
      modelo: _modelo,
      ano: _ano,
      medida: _medida,
      descripcion: _descripcion,
    );

    final ok = await _service.insertarMaterial(material);

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error guardando material")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Añadir Material")),
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

              // NOMBRE (opcional pero limpio)
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Nombre (opcional)",
                ),
                onSaved: (v) => _nombre = v?.trim(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (!RegExp(
                    r"^[a-zA-Z0-9 áéíóúÁÉÍÓÚñÑ.,_-]{2,}$",
                  ).hasMatch(v.trim())) {
                    return "Nombre no válido";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ⭐ FOIL
              if (_tipo == "foil") ...[
                const Text(
                  "Datos del Foil",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Front Wing (cm²)",
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Introduce el tamaño" : null,
                  onSaved: (v) => _medida = v?.trim(),
                ),

                const SizedBox(height: 16),
              ],

              // ⭐ VELA LIGERA
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
                  validator: (v) =>
                      v == null ? "Selecciona una clase de barco" : null,
                  onChanged: (v) => setState(() => _medida = v),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  decoration: const InputDecoration(labelText: "Marca"),
                  onSaved: (v) => _marca = v?.trim(),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  decoration: const InputDecoration(labelText: "Modelo"),
                  onSaved: (v) => _modelo = v?.trim(),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  decoration: const InputDecoration(labelText: "Año"),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (int.tryParse(v) == null) return "Año no válido";
                    return null;
                  },
                  onSaved: (v) =>
                      _ano = v != null && v.isNotEmpty ? int.tryParse(v) : null,
                ),

                const SizedBox(height: 8),

                TextFormField(
                  decoration: const InputDecoration(labelText: "Descripción"),
                  maxLines: 3,
                  onSaved: (v) => _descripcion = v?.trim(),
                ),

                const SizedBox(height: 16),
              ],

              // ⭐ CAMPOS GENERALES
              if (_tipo != null &&
                  _tipo != "foil" &&
                  !(_disciplina == "vela ligera")) ...[
                Text(
                  "Detalles de $_tipo",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  decoration: const InputDecoration(labelText: "Marca"),
                  onSaved: (v) => _marca = v?.trim(),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  decoration: const InputDecoration(labelText: "Modelo"),
                  onSaved: (v) => _modelo = v?.trim(),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  decoration: const InputDecoration(labelText: "Año"),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (int.tryParse(v) == null) return "Año no válido";
                    return null;
                  },
                  onSaved: (v) =>
                      _ano = v != null && v.isNotEmpty ? int.tryParse(v) : null,
                ),

                const SizedBox(height: 8),

                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Medida (ej: 9m, 85L, 210cm)",
                  ),
                  onSaved: (v) => _medida = v?.trim(),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  decoration: const InputDecoration(labelText: "Descripción"),
                  maxLines: 3,
                  onSaved: (v) => _descripcion = v?.trim(),
                ),

                const SizedBox(height: 16),
              ],

              ElevatedButton(
                onPressed: _guardarMaterial,
                child: const Text("Guardar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
