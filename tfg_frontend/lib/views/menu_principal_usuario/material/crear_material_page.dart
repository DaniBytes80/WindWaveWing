import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tfg_clima_malaga/models/material_usuario.dart';
import 'package:tfg_clima_malaga/services/material_service.dart';
import 'package:tfg_clima_malaga/utils/tema.dart';

class CrearMaterialPage extends StatefulWidget {
  const CrearMaterialPage({super.key});
  @override
  State<CrearMaterialPage> createState() => _CrearMaterialPageState();
}

class _CrearMaterialPageState extends State<CrearMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = MaterialService();
  final _medidaCtrl = TextEditingController();

  String? _disciplina;
  String? _tipo;
  String? _nombre;
  String? _marca;
  String? _modelo;
  int? _ano;
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

  _MedidaConfig? get _medidaConfig {
    if (_disciplina == null || _tipo == null) return null;
    return _getMedidaConfig(_disciplina!, _tipo!);
  }

  String? get _descripcionHint {
    if (_tipo == 'foil') {
      return 'Ej: Mástil 75cm · Stab 280cm² · Fuselaje 60cm\n'
          'Recuerda añadir el mástil y el stabilizer como materiales separados';
    }
    if (_tipo == 'vela') return 'Ej: Compatible con mástil RDM 460cm';
    if (_tipo == 'botavara') return 'Ej: Regulable 160-220cm';
    if (_tipo == 'mástil') return 'Ej: RDM, IMCS 25, compatible con vela 7.5m²';
    return null;
  }

  static _MedidaConfig? _getMedidaConfig(String disciplina, String tipo) {
    switch (disciplina) {
      case 'surf':
        if (tipo == 'tabla') {
          return _MedidaConfig(
            label: 'Volumen de la tabla (litros)',
            hint: 'Ej: 35 · Para 90kg nivel Pro: 30-45L, Principiante: 60-130L',
            unidad: 'L',
            min: 15,
            max: 200,
            teclado: TextInputType.number,
          );
        }
        if (tipo == 'foil') {
          return _MedidaConfig(
            label: 'Front wing (cm²)',
            hint: 'Ej: 1450 · Rango habitual: 600-2500 cm²',
            unidad: 'cm²',
            min: 400,
            max: 3000,
            teclado: TextInputType.number,
          );
        }

      case 'wingfoil':
        if (tipo == 'tabla') {
          return _MedidaConfig(
            label: 'Volumen de la tabla (litros)',
            hint: 'Ej: 105 · Rango habitual: 60-150L',
            unidad: 'L',
            min: 40,
            max: 200,
            teclado: TextInputType.number,
          );
        }
        if (tipo == 'ala') {
          return _MedidaConfig(
            label: 'Superficie del ala (m²)',
            hint: 'Ej: 5.5 · Rango habitual: 2.5-9 m²',
            unidad: 'm²',
            min: 2,
            max: 10,
            decimal: true,
            teclado: const TextInputType.numberWithOptions(decimal: true),
          );
        }
        if (tipo == 'foil') {
          return _MedidaConfig(
            label: 'Front wing (cm²)',
            hint: 'Ej: 1450 · Rango habitual: 600-2500 cm²',
            unidad: 'cm²',
            min: 400,
            max: 3000,
            teclado: TextInputType.number,
          );
        }

      case 'kitesurf':
        if (tipo == 'cometa') {
          return _MedidaConfig(
            label: 'Superficie de la cometa (m²)',
            hint: 'Ej: 12 · Rango habitual: 5-21 m²',
            unidad: 'm²',
            min: 4,
            max: 25,
            decimal: true,
            teclado: const TextInputType.numberWithOptions(decimal: true),
          );
        }
        if (tipo == 'tabla') {
          return _MedidaConfig(
            label: 'Longitud de la tabla (cm)',
            hint: 'Ej: 138 · Rango habitual: 120-165 cm',
            unidad: 'cm',
            min: 100,
            max: 180,
            teclado: TextInputType.number,
          );
        }
        if (tipo == 'foil') {
          return _MedidaConfig(
            label: 'Front wing (cm²)',
            hint: 'Ej: 1450 · Rango habitual: 600-2500 cm²',
            unidad: 'cm²',
            min: 400,
            max: 3000,
            teclado: TextInputType.number,
          );
        }

      case 'windsurf':
        if (tipo == 'tabla') {
          return _MedidaConfig(
            label: 'Volumen de la tabla (litros)',
            hint: 'Ej: 130 · Rango habitual: 65-250L',
            unidad: 'L',
            min: 50,
            max: 280,
            teclado: TextInputType.number,
          );
        }
        if (tipo == 'vela') {
          return _MedidaConfig(
            label: 'Superficie de la vela (m²)',
            hint: 'Ej: 7.5 · Rango habitual: 3-13 m²',
            unidad: 'm²',
            min: 2,
            max: 15,
            decimal: true,
            teclado: const TextInputType.numberWithOptions(decimal: true),
          );
        }
        if (tipo == 'botavara') {
          return _MedidaConfig(
            label: 'Longitud de botavara (cm)',
            hint: 'Ej: 185 · Rango habitual: 140-230 cm',
            unidad: 'cm',
            min: 130,
            max: 250,
            teclado: TextInputType.number,
          );
        }
        if (tipo == 'mástil') {
          return _MedidaConfig(
            label: 'Altura del mástil (cm)',
            hint: 'Ej: 460 · Rango habitual: 340-550 cm',
            unidad: 'cm',
            min: 300,
            max: 600,
            teclado: TextInputType.number,
          );
        }
        if (tipo == 'foil') {
          return _MedidaConfig(
            label: 'Front wing (cm²)',
            hint: 'Ej: 1450 · Rango habitual: 600-2500 cm²',
            unidad: 'cm²',
            min: 400,
            max: 3000,
            teclado: TextInputType.number,
          );
        }
    }
    return null;
  }

  Future<void> _guardarMaterial() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final userId = _service.supabase.auth.currentUser?.id;
    if (userId == null) {
      _snack("Error: usuario no identificado");
      return;
    }

    final medidaFinal = _medidaCtrl.text.trim().isEmpty
        ? null
        : _medidaCtrl.text.trim();

    final material = MaterialUsuario(
      userId: userId,
      disciplina: _disciplina!,
      tipo: _tipo!,
      nombre: _nombre,
      marca: _marca,
      modelo: _modelo,
      ano: _ano,
      medida: medidaFinal,
      descripcion: _descripcion,
    );

    final ok = await _service.insertarMaterial(material);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      _snack("Error guardando material");
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  void dispose() {
    _medidaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _medidaConfig;

    return Scaffold(
      backgroundColor: EstilosWWW.colorFondoPantalla,
      appBar: AppBar(
        title: const Text("Añadir Material"),
        backgroundColor: EstilosWWW.colorFondoPantalla,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Disciplina"),
                items: disciplinas
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _disciplina = v;
                  _tipo = null;
                  _medidaCtrl.clear();
                }),
                validator: (v) =>
                    v == null ? "Selecciona una disciplina" : null,
              ),
              const SizedBox(height: 16),

              if (_disciplina != null) ...[
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Tipo de material",
                  ),
                  items: tiposPorDisciplina[_disciplina]!
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _tipo = v;
                    _medidaCtrl.clear();
                  }),
                  validator: (v) => v == null ? "Selecciona un tipo" : null,
                ),
                const SizedBox(height: 16),
              ],

              if (_disciplina == 'vela ligera' && _tipo == 'tipo de barco') ...[
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Clase de barco",
                  ),
                  items: clasesBarco
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  validator: (v) => v == null ? "Selecciona una clase" : null,
                  onChanged: (v) => setState(() => _medidaCtrl.text = v ?? ''),
                ),
                const SizedBox(height: 16),
              ],

              if (_tipo != null) ...[
                TextFormField(
                  style: const TextStyle(color: EstilosWWW.colorLetra),
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
                const SizedBox(height: 8),

                TextFormField(
                  style: const TextStyle(color: EstilosWWW.colorLetra),
                  decoration: const InputDecoration(labelText: "Marca"),
                  onSaved: (v) => _marca = v?.trim(),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  style: const TextStyle(color: EstilosWWW.colorLetra),
                  decoration: const InputDecoration(labelText: "Modelo"),
                  onSaved: (v) => _modelo = v?.trim(),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  style: const TextStyle(color: EstilosWWW.colorLetra),
                  decoration: const InputDecoration(labelText: "Año"),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final y = int.tryParse(v);
                    if (y == null || y < 1980 || y > 2030) {
                      return "Año no válido";
                    }
                    return null;
                  },
                  onSaved: (v) => _ano = int.tryParse(v ?? ''),
                ),
                const SizedBox(height: 16),

                if (config != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: EstilosWWW.decoracionSeccion,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.straighten,
                              size: 18,
                              color: EstilosWWW.colorAccent,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                config.label,
                                style: const TextStyle(
                                  color: EstilosWWW.colorLetra,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          config.hint,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _medidaCtrl,
                          style: const TextStyle(color: EstilosWWW.colorLetra),
                          keyboardType: config.teclado,
                          inputFormatters: config.decimal
                              ? [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d*'),
                                  ),
                                ]
                              : [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            suffixText: config.unidad,
                            hintText:
                                '${config.min.toStringAsFixed(config.decimal ? 1 : 0)}'
                                ' - '
                                '${config.max.toStringAsFixed(config.decimal ? 1 : 0)}',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Introduce la medida en ${config.unidad}';
                            }
                            final num = double.tryParse(v.trim());
                            if (num == null) return 'Valor numérico inválido';
                            if (num < config.min || num > config.max) {
                              return 'Rango válido: ${config.min.toStringAsFixed(0)}'
                                  ' - ${config.max.toStringAsFixed(0)} ${config.unidad}';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  style: const TextStyle(color: EstilosWWW.colorLetra),
                  decoration: InputDecoration(
                    labelText: "Descripción (opcional)",
                    hintText: _descripcionHint,
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                    hintMaxLines: 3,
                  ),
                  maxLines: 3,
                  onSaved: (v) => _descripcion = v?.trim(),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  style: EstilosWWW.botonOscuro,
                  onPressed: _guardarMaterial,
                  child: const Text("Guardar material"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MedidaConfig {
  final String label;
  final String hint;
  final String unidad;
  final double min;
  final double max;
  final bool decimal;
  final TextInputType teclado;

  const _MedidaConfig({
    required this.label,
    required this.hint,
    required this.unidad,
    required this.min,
    required this.max,
    this.decimal = false,
    this.teclado = TextInputType.number,
  });
}
