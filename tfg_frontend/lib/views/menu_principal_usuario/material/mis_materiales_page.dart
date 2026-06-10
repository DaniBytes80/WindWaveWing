import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/models/material_usuario.dart';
import 'package:tfg_clima_malaga/services/material_service.dart';
import 'package:tfg_clima_malaga/views/menu_principal_usuario/material/crear_material_page.dart';
import 'package:tfg_clima_malaga/views/menu_principal_usuario/material/editar_material_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  // ── Icono representativo ──────────────────────────────────
  Widget _icono(MaterialUsuario m) {
    final tipo = m.tipo.toLowerCase();
    final disc = m.disciplina.toLowerCase();

    String? asset;

    if (tipo == 'foil') asset = 'assets/icons/picto_foil_small.svg';
    if (tipo == 'cometa') asset = 'assets/icons/ico_kitesuf_kite.svg';
    if (tipo == 'ala') asset = 'assets/icons/ico_ala_wing.svg';
    if (tipo == 'vela') asset = 'assets/icons/ico_windsuf_vela.svg';

    if (tipo == 'tabla') {
      if (disc.contains('surf')) asset = 'assets/icons/tabla_surf.svg';
      if (disc.contains('wing')) asset = 'assets/icons/tabla_wing.svg';
      if (disc.contains('kite')) asset = 'assets/icons/tabla_kite.svg';
      if (disc.contains('wind')) asset = 'assets/icons/tabla_windsurf.svg';
    }

    if (asset != null) {
      return SizedBox(
        width: 36,
        height: 36,
        child: SvgPicture.asset(
          asset,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => _iconoFallback(tipo),
        ),
      );
    }

    return _iconoFallback(tipo);
  }

  Widget _iconoFallback(String tipo) {
    final map = <String, (IconData, Color)>{
      'tabla': (Icons.surfing, Colors.blueAccent),
      'cometa': (Icons.paragliding, Colors.cyan),
      'ala': (Icons.paragliding, Colors.teal),
      'foil': (Icons.navigation, Colors.teal),
      'vela': (Icons.sailing, Colors.indigo),
      'botavara': (Icons.horizontal_rule, Colors.grey),
      'mástil': (Icons.vertical_align_top, Colors.grey),
      'tipo de barco': (Icons.directions_boat, Colors.blue),
    };
    final (icon, color) = map[tipo] ?? (Icons.inventory_2, Colors.blueAccent);
    return Icon(icon, size: 32, color: color);
  }

  // ── Badge medida con unidad ───────────────────────────────
  String _medidaConUnidad(MaterialUsuario m) {
    final v = m.medida;
    if (v == null || v.isEmpty) return '';
    final tipo = m.tipo.toLowerCase();
    final disc = m.disciplina.toLowerCase();

    if (tipo == 'foil') return '$v cm²';
    if (tipo == 'cometa' || tipo == 'ala') return '$v m²';
    if (tipo == 'vela') return '$v m²';
    if (tipo == 'botavara' || tipo == 'mástil') return '$v cm';
    if (tipo == 'tipo de barco') return v;
    if (tipo == 'tabla') {
      if (disc.contains('kite')) return '$v cm';
      return '$v L'; // surf, wingfoil, windsurf
    }
    return v;
  }

  @override
  Widget build(BuildContext context) {
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
              children: agrupado.entries
                  .map(
                    (entry) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Text(
                            entry.key.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                        ...entry.value.map((m) {
                          final medida = _medidaConUnidad(m);
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: ListTile(
                              dense: true,
                              minLeadingWidth: 40,
                              leading: _icono(m),

                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      m.nombre ?? m.tipo,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  // ✅ Badge medida
                                  if (medida.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.blueAccent.withValues(
                                            alpha: 0.35,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        medida,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              subtitle: Text(
                                [
                                  if (m.marca != null && m.marca!.isNotEmpty)
                                    m.marca!,
                                  if (m.modelo != null && m.modelo!.isNotEmpty)
                                    m.modelo!,
                                  if (m.ano != null) m.ano.toString(),
                                ].join(' · '),
                                style: const TextStyle(fontSize: 13),
                              ),

                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) async {
                                  if (value == 'editar') {
                                    final ok = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            EditarMaterialPage(material: m),
                                      ),
                                    );
                                    if (ok == true) _cargarMaterial();
                                  }
                                  if (value == 'eliminar') {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text("Eliminar material"),
                                        content: Text(
                                          "¿Seguro que quieres eliminar "
                                          "'${m.nombre ?? m.tipo}'?",
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
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true) {
                                      final deleted = await _service
                                          .eliminarMaterial(m.id);
                                      if (deleted) _cargarMaterial();
                                    }
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'editar',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 10),
                                        Text("Modificar"),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'eliminar',
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
                    ),
                  )
                  .toList(),
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearMaterialPage()),
          );
          if (ok == true) _cargarMaterial();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
