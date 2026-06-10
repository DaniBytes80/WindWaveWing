import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tfg_clima_malaga/models/material_usuario.dart';
import 'package:tfg_clima_malaga/services/material_service.dart';

// ============================================================
//  CrearMaterialPage — v2
//  ✅ Campo medida sustituido por campos numéricos específicos
//     según disciplina + tipo, con hints y validación de rango.
//  ✅ El valor guardado en `medida` es siempre numérico (string)
//     para que el script de alertas pueda compararlo.
// ============================================================

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

  // ── Configuración del campo medida según disciplina+tipo ──
  _MedidaConfig? get _medidaConfig {
    if (_disciplina == null || _tipo == null) return null;
    return _getMedidaConfig(_disciplina!, _tipo!);
  }

  static _MedidaConfig? _getMedidaConfig(String disciplina, String tipo) {
    switch (disciplina) {
      case 'surf':
        if (tipo == 'tabla')
          return _MedidaConfig(
            label: 'Volumen de la tabla (litros)',
            hint: 'Ej: 35 · Para 90kg nivel Pro: 30-45L, Principiante: 60-130L',
            unidad: 'L',
            min: 15,
            max: 200,
            teclado: TextInputType.number,
          );
        if (tipo == 'foil')
          return _MedidaConfig(
            label: 'Front wing (cm²)',
            hint: 'Ej: 1450 · Rango habitual: 600-2500 cm²',
            unidad: 'cm²',
            min: 400,
            max: 3000,
            teclado: TextInputType.number,
          );

      case 'wingfoil':
        if (tipo == 'tabla')
          return _MedidaConfig(
            label: 'Volumen de la tabla (litros)',
            hint: 'Ej: 105 · Rango habitual: 60-150L',
            unidad: 'L',
            min: 40,
            max: 200,
            teclado: TextInputType.number,
          );
        if (tipo == 'ala')
          return _MedidaConfig(
            label: 'Superficie del ala (m²)',
            hint: 'Ej: 5.5 · Rango habitual: 2.5-9 m²',
            unidad: 'm²',
            min: 2,
            max: 10,
            decimal: true,
            teclado: const TextInputType.numberWithOptions(decimal: true),
          );
        if (tipo == 'foil')
          return _MedidaConfig(
            label: 'Front wing (cm²)',
            hint: 'Ej: 1450 · Rango habitual: 600-2500 cm²',
            unidad: 'cm²',
            min: 400,
            max: 3000,
            teclado: TextInputType.number,
          );

      case 'kitesurf':
        if (tipo == 'cometa')
          return _MedidaConfig(
            label: 'Superficie de la cometa (m²)',
            hint: 'Ej: 12 · Rango habitual: 5-21 m²',
            unidad: 'm²',
            min: 4,
            max: 25,
            decimal: true,
            teclado: const TextInputType.numberWithOptions(decimal: true),
          );
        if (tipo == 'tabla')
          return _MedidaConfig(
            label: 'Longitud de la tabla (cm)',
            hint: 'Ej: 138 · Rango habitual: 120-165 cm',
            unidad: 'cm',
            min: 100,
            max: 180,
            teclado: TextInputType.number,
          );
        if (tipo == 'foil')
          return _MedidaConfig(
            label: 'Front wing (cm²)',
            hint: 'Ej: 1450 · Rango habitual: 600-2500 cm²',
            unidad: 'cm²',
            min: 400,
            max: 3000,
            teclado: TextInputType.number,
          );

      case 'windsurf':
        if (tipo == 'tabla')
          return _MedidaConfig(
            label: 'Volumen de la tabla (litros)',
            hint: 'Ej: 130 · Rango habitual: 65-250L',
            unidad: 'L',
            min: 50,
            max: 280,
            teclado: TextInputType.number,
          );
        if (tipo == 'vela')
          return _MedidaConfig(
            label: 'Superficie de la vela (m²)',
            hint: 'Ej: 7.5 · Rango habitual: 3-13 m²',
            unidad: 'm²',
            min: 2,
            max: 15,
            decimal: true,
            teclado: const TextInputType.numberWithOptions(decimal: true),
          );
        if (tipo == 'botavara')
          return _MedidaConfig(
            label: 'Longitud de botavara (cm)',
            hint: 'Ej: 185 · Rango habitual: 140-230 cm',
            unidad: 'cm',
            min: 130,
            max: 250,
            teclado: TextInputType.number,
          );
        if (tipo == 'mástil')
          return _MedidaConfig(
            label: 'Altura del mástil (cm)',
            hint: 'Ej: 460 · Rango habitual: 340-550 cm',
            unidad: 'cm',
            min: 300,
            max: 600,
            teclado: TextInputType.number,
          );
        if (tipo == 'foil')
          return _MedidaConfig(
            label: 'Front wing (cm²)',
            hint: 'Ej: 1450 · Rango habitual: 600-2500 cm²',
            unidad: 'cm²',
            min: 400,
            max: 3000,
            teclado: TextInputType.number,
          );
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

    // El valor de medida viene del controller numérico
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
      appBar: AppBar(title: const Text("Añadir Material")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ── DISCIPLINA ───────────────────────────────
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

              // ── TIPO ─────────────────────────────────────
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

              // ── CLASE DE BARCO (vela ligera) ─────────────
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

              // ── NOMBRE ───────────────────────────────────
              if (_tipo != null) ...[
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Nombre (opcional)",
                  ),
                  onSaved: (v) => _nombre = v?.trim(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (!RegExp(
                      r"^[a-zA-Z0-9 áéíóúÁÉÍÓÚñÑ.,_-]{2,}$",
                    ).hasMatch(v.trim()))
                      return "Nombre no válido";
                    return null;
                  },
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
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final y = int.tryParse(v);
                    if (y == null || y < 1980 || y > 2030)
                      return "Año no válido";
                    return null;
                  },
                  onSaved: (v) => _ano = int.tryParse(v ?? ''),
                ),
                const SizedBox(height: 16),

                // ── CAMPO MEDIDA INTELIGENTE ──────────────
                if (config != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.straighten,
                              size: 18,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              config.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          config.hint,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _medidaCtrl,
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
                  decoration: const InputDecoration(
                    labelText: "Descripción (opcional)",
                  ),
                  maxLines: 3,
                  onSaved: (v) => _descripcion = v?.trim(),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
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

// ── Configuración del campo medida ────────────────────────────
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
