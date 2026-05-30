import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/models/material_usuario.dart';
import 'package:tfg_clima_malaga/services/material_service.dart';
import 'package:tfg_clima_malaga/views/material/crear_material_page.dart';
import 'package:tfg_clima_malaga/views/material/editar_material_page.dart';

class MisMaterialesPage extends StatefulWidget {
  const MisMaterialesPage({super.key});

  @override
  State<MisMaterialesPage> createState() => _MisMaterialesPageState();
}

class _MisMaterialesPageState extends State<MisMaterialesPage> {
  final MaterialService _service = MaterialService();
  List<MaterialUsuario> _materiales = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarMaterial();
  }

  Future<void> _cargarMaterial() async {
    final userId = _service.supabase.auth.currentUser?.id;

    if (userId == null) {
      setState(() => _cargando = false);
      return;
    }

    final lista = await _service.obtenerMaterialUsuario(userId);

    setState(() {
      _materiales = lista;
      _cargando = false;
    });
  }

  IconData _iconoPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'tabla':
        return Icons.surfing;
      case 'cometa':
        return Icons.air;
      case 'ala':
        return Icons.toys;
      case 'foil':
        return Icons.navigation;
      case 'vela':
        return Icons.sailing;
      case 'botavara':
        return Icons.horizontal_rule;
      case 'mástil':
        return Icons.vertical_align_top;
      case 'tipo de barco':
        return Icons.directions_boat;
      default:
        return Icons.inventory_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    // AGRUPAR POR DISCIPLINA
    final Map<String, List<MaterialUsuario>> agrupado = {};

    for (var m in _materiales) {
      agrupado.putIfAbsent(m.disciplina, () => []);
      agrupado[m.disciplina]!.add(m);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Mi Material Deportivo")),

      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _materiales.isEmpty
          ? const Center(
              child: Text(
                "No tienes material registrado",
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView(
              children: agrupado.entries.map((entry) {
                final disciplina = entry.key;
                final lista = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER DE DISCIPLINA
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text(
                        disciplina.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),

                    // LISTA COMPACTA DE MATERIALES
                    ...lista.map((m) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          dense: true,
                          minLeadingWidth: 30,
                          leading: Icon(
                            _iconoPorTipo(m.tipo),
                            size: 28,
                            color: Colors.blueAccent,
                          ),
                          title: Text(
                            m.nombre ?? "${m.tipo} ${m.medida ?? ''}",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            "${m.marca ?? ''} ${m.modelo ?? ''}",
                            style: const TextStyle(fontSize: 13),
                          ),

                          // ⭐ MENÚ DE 3 PUNTOS
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) async {
                              if (value == "editar") {
                                final actualizado = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditarMaterialPage(material: m),
                                  ),
                                );

                                if (actualizado == true) {
                                  _cargarMaterial();
                                }
                              }

                              if (value == "eliminar") {
                                final confirmar = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Eliminar material"),
                                    content: Text(
                                      "¿Seguro que quieres eliminar '${m.nombre ?? m.tipo}'?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Cancelar"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          "Eliminar",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmar == true) {
                                  final ok = await _service.eliminarMaterial(
                                    m.id,
                                  );

                                  if (ok) {
                                    _cargarMaterial();
                                  }
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: "editar",
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 10),
                                    Text("Modificar"),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: "eliminar",
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 10),
                                    Text("Eliminar"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final creado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearMaterialPage()),
          );

          if (creado == true) {
            _cargarMaterial();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
