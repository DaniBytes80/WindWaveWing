import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tfg_clima_malaga/models/material_usuario.dart';
import 'package:tfg_clima_malaga/services/material_service.dart';
import 'package:tfg_clima_malaga/views/menu_principal_usuario/material/crear_material_page.dart';
import 'package:tfg_clima_malaga/views/menu_principal_usuario/material/editar_material_page.dart';
import 'package:tfg_clima_malaga/utils/tema.dart';

class MisMaterialesPage extends StatefulWidget {
  const MisMaterialesPage({super.key});
  @override
  State<MisMaterialesPage> createState() => _MisMaterialesPageState();
}

class _MisMaterialesPageState extends State<MisMaterialesPage> {
  final _service = MaterialService();
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

  Widget _icono(MaterialUsuario m) {
    final tipo = m.tipo.toLowerCase();
    switch (tipo) {
      case 'foil':
        return _svg('assets/icons/ico_foil.svg');
      case 'ala':
        return _svg('assets/icons/ico_ala_wing.svg');
      case 'cometa':
        return _svg('assets/icons/ico_kitesurf_kite.svg');
      case 'vela':
      case 'botavara':
      case 'mástil':
        return _svg('assets/icons/ico_windsurf_vela.svg');
      case 'tabla':
        return const Icon(
          Icons.surfing,
          size: 32,
          color: EstilosWWW.colorAccent,
        );
      case 'tipo de barco':
        return const Icon(
          Icons.sailing,
          size: 32,
          color: EstilosWWW.colorAccent,
        );
      default:
        return const Icon(
          Icons.inventory_2,
          size: 32,
          color: EstilosWWW.colorAccent,
        );
    }
  }

  Widget _svg(String path) => SvgPicture.asset(path, width: 34, height: 34);

  String _medidaConUnidad(MaterialUsuario m) {
    final v = m.medida;
    if (v == null || v.isEmpty) return '';
    final tipo = m.tipo.toLowerCase();
    final disc = m.disciplina.toLowerCase();
    switch (tipo) {
      case 'foil':
        return '$v cm²';
      case 'cometa':
      case 'ala':
        return '$v m²';
      case 'vela':
        return '$v m²';
      case 'botavara':
      case 'mástil':
        return '$v cm';
      case 'tipo de barco':
        return v;
      case 'tabla':
        if (disc.contains('kite')) return '$v cm';
        return '$v L';
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
      backgroundColor: EstilosWWW.colorFondoPantalla,
      appBar: AppBar(
        title: const Text("Mi Material Deportivo"),
        backgroundColor: EstilosWWW.colorFondoPantalla,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _materiales.isEmpty
          ? Center(
              child: Text(
                "No tienes material registrado",
                style: EstilosWWW.textoSecundario,
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: agrupado.entries
                  .map(
                    (entry) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Text(
                            entry.key.toUpperCase(),
                            style: EstilosWWW.tituloSeccion.copyWith(
                              color: EstilosWWW.colorAccent,
                            ),
                          ),
                        ),
                        ...entry.value.map((m) {
                          final medida = _medidaConUnidad(m);
                          return Material(
                            color: Colors.transparent,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: EstilosWWW.decoracionCard,
                              child: ListTile(
                                dense: true,
                                minLeadingWidth: 40,
                                leading: _icono(m),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        m.nombre ?? m.tipo,
                                        style: EstilosWWW.textoNegritaTabla,
                                      ),
                                    ),
                                    if (medida.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: EstilosWWW.colorAccent
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: EstilosWWW.colorAccent
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Text(
                                          medida,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: EstilosWWW.colorAccent,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  [
                                    if (m.marca != null && m.marca!.isNotEmpty)
                                      m.marca!,
                                    if (m.modelo != null &&
                                        m.modelo!.isNotEmpty)
                                      m.modelo!,
                                    if (m.ano != null) m.ano.toString(),
                                  ].join(' · '),
                                  style: EstilosWWW.textoSecundario,
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    size: 20,
                                    color: Colors.white54,
                                  ),
                                  color: EstilosWWW.colorAzulMedio,
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
                                      final confirmar = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          backgroundColor:
                                              EstilosWWW.fondoDialog,
                                          title: const Text(
                                            "Eliminar material",
                                            style: TextStyle(
                                              color: EstilosWWW.colorLetra,
                                            ),
                                          ),
                                          content: Text(
                                            "¿Seguro que quieres eliminar "
                                            "'${m.nombre ?? m.tipo}'?",
                                            style: EstilosWWW.textoSecundario,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text(
                                                "Cancelar",
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text(
                                                "Eliminar",
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmar == true) {
                                        final ok = await _service
                                            .eliminarMaterial(m.id);
                                        if (ok) _cargarMaterial();
                                      }
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'editar',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            size: 20,
                                            color: Colors.blueAccent,
                                          ),
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
                                            color: Colors.redAccent,
                                          ),
                                          SizedBox(width: 10),
                                          Text("Eliminar"),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
        backgroundColor: EstilosWWW.colorBordeTabla,
        foregroundColor: EstilosWWW.colorLetra,
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
