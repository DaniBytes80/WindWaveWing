import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/services/alertas_service.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';
import 'package:tfg_clima_malaga/models/spot.dart';

class CrearAlertaPage extends StatefulWidget {
  const CrearAlertaPage({super.key});
  @override
  State<CrearAlertaPage> createState() => _CrearAlertaPageState();
}

class _CrearAlertaPageState extends State<CrearAlertaPage> {
  final _formKey = GlobalKey<FormState>();
  final _alertasService = AlertasService();
  final _spotManager = SpotManager();

  String? _spotId;
  String? _disciplina;
  String? _nivel;
  String? _mensaje;
  String? _nombre;
  int _frecuenciaHoras = 4; // por defecto 4h
  int _horaInicio = 7; // 7:00
  int _horaFin = 22; // 22:00

  final nivelesTecnicos = ["Principiante", "Ocasional", "Intensivo", "Pro"];
  final frecuencias = [1, 2, 4, 8, 12, 24];

  List<Spot> _spotsFavoritos = [];

  @override
  void initState() {
    super.initState();
    _spotsFavoritos = _spotManager.spots
        .where((s) => _spotManager.favoritos.contains(s.id))
        .toList();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final userId = _alertasService.supabase.auth.currentUser?.id;
    if (userId == null) return;

    final ok = await _alertasService.crearAlerta({
      "user_id": userId,
      "spot_id": _spotId,
      "nombre": _nombre,
      "disciplina": _disciplina,
      "nivel": _nivel,
      "mensaje": _mensaje,
      "activa": true,
      "frecuencia_horas": _frecuenciaHoras,
      "hora_inicio": _horaInicio,
      "hora_fin": _horaFin,
    });

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error guardando alerta")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Alerta")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Nombre
              TextFormField(
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (v) => v == null || v.trim().isEmpty
                    ? "Introduce un nombre"
                    : null,
                onSaved: (v) => _nombre = v?.trim(),
              ),
              const SizedBox(height: 16),

              // Spot
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Spot"),
                items: _spotsFavoritos
                    .map(
                      (s) =>
                          DropdownMenuItem(value: s.id, child: Text(s.nombre)),
                    )
                    .toList(),
                validator: (v) => v == null ? "Selecciona un spot" : null,
                onChanged: (v) => setState(() => _spotId = v),
              ),
              const SizedBox(height: 16),

              // Disciplina
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Disciplina"),
                items:
                    ["surf", "kitesurf", "windsurf", "wingfoil", "vela ligera"]
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                validator: (v) =>
                    v == null ? "Selecciona una disciplina" : null,
                onChanged: (v) => setState(() => _disciplina = v),
              ),
              const SizedBox(height: 16),

              // Nivel
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Nivel técnico"),
                items: nivelesTecnicos
                    .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                    .toList(),
                validator: (v) => v == null ? "Selecciona un nivel" : null,
                onChanged: (v) => setState(() => _nivel = v),
              ),
              const SizedBox(height: 24),

              // ── Configuración de notificación ────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blueAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.notifications_active,
                          size: 18,
                          color: Colors.blueAccent,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Configuración de avisos",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Frecuencia
                    DropdownButtonFormField<int>(
                      value: _frecuenciaHoras,
                      decoration: const InputDecoration(
                        labelText: "Frecuencia máxima de avisos",
                      ),
                      items: frecuencias
                          .map(
                            (h) => DropdownMenuItem(
                              value: h,
                              child: Text(
                                h == 1
                                    ? "Cada hora"
                                    : h == 24
                                    ? "1 vez al día"
                                    : "Cada $h horas",
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _frecuenciaHoras = v ?? 4),
                    ),
                    const SizedBox(height: 16),

                    // Horario
                    const Text(
                      "Horario de avisos",
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _horaInicio,
                            decoration: const InputDecoration(
                              labelText: "Desde",
                            ),
                            items: List.generate(
                              24,
                              (h) => DropdownMenuItem(
                                value: h,
                                child: Text(
                                  "${h.toString().padLeft(2, '0')}:00",
                                ),
                              ),
                            ).toList(),
                            onChanged: (v) =>
                                setState(() => _horaInicio = v ?? 7),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _horaFin,
                            decoration: const InputDecoration(
                              labelText: "Hasta",
                            ),
                            items: List.generate(
                              24,
                              (h) => DropdownMenuItem(
                                value: h,
                                child: Text(
                                  "${h.toString().padLeft(2, '0')}:00",
                                ),
                              ),
                            ).toList(),
                            onChanged: (v) =>
                                setState(() => _horaFin = v ?? 22),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mensaje personalizado
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Mensaje personalizado (opcional)",
                ),
                maxLines: 2,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (v.length > 200) return "Máximo 200 caracteres";
                  return null;
                },
                onSaved: (v) => _mensaje = v?.trim(),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _crear,
                child: const Text("Crear alerta"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
