import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/chilean_utils.dart';
import '../models/repuesto.dart';
import '../widgets/repuesto_form_dialog.dart';

class RepuestosScreen extends StatefulWidget {
  @override
  _RepuestosScreenState createState() => _RepuestosScreenState();
}

class _RepuestosScreenState extends State<RepuestosScreen> {
  String _filtroSistema = 'Todos';
  String _filtroTipo = 'Todos';
  String _filtroTexto = '';
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<RepuestoCatalogo>> _getRepuestosFiltrados() async {
    var repuestos = await DataService.getCatalogoRepuestos();

    // Filtrar por sistema
    if (_filtroSistema != 'Todos') {
      repuestos = repuestos.where((r) => r.sistemaLabel == _filtroSistema).toList();
    }

    // Filtrar por tipo
    if (_filtroTipo != 'Todos') {
      repuestos = repuestos.where((r) => r.tipoLabel == _filtroTipo).toList();
    }

    // Filtrar por texto
    if (_filtroTexto.isNotEmpty) {
      repuestos = repuestos.where((r) =>
      r.nombre.toLowerCase().contains(_filtroTexto.toLowerCase()) ||
          r.codigo.toLowerCase().contains(_filtroTexto.toLowerCase()) ||
          r.descripcion.toLowerCase().contains(_filtroTexto.toLowerCase()) ||
          (r.fabricante?.toLowerCase().contains(_filtroTexto.toLowerCase()) ?? false)
      ).toList();
    }

    // Ordenar por sistema y luego por nombre
    repuestos.sort((a, b) {
      final sistemaComparison = a.sistemaLabel.compareTo(b.sistemaLabel);
      if (sistemaComparison != 0) return sistemaComparison;
      return a.nombre.compareTo(b.nombre);
    });

    return repuestos;
  }

  Future<List<String>> _getSistemasDisponibles() async {
    final sistemas = <String>{'Todos'};
    final repuestos = await DataService.getCatalogoRepuestos();
    for (final repuesto in repuestos) {
      sistemas.add(repuesto.sistemaLabel);
    }
    return sistemas.toList()..sort();
  }

  Future<List<String>> _getTiposDisponibles() async {
    final tipos = <String>{'Todos'};
    final repuestos = await DataService.getCatalogoRepuestos();
    for (final repuesto in repuestos) {
      tipos.add(repuesto.tipoLabel);
    }
    return tipos.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Catálogo de Repuestos',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _mostrarDialogoRepuesto(context),
                icon: Icon(Icons.add),
                label: Text('Nuevo Repuesto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Filtros
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Búsqueda
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Buscar repuesto, código o descripción',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _filtroTexto = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      // Filtro sistema
                      Expanded(
                        flex: 2,
                        child: FutureBuilder<List<String>>(
                          future: _getSistemasDisponibles(),
                          builder: (context, snapshot) {
                            final sistemas = snapshot.data ?? ['Todos'];
                            if (!sistemas.contains(_filtroSistema)) {
                              _filtroSistema = 'Todos';
                            }
                            return DropdownButtonFormField<String>(
                              value: _filtroSistema,
                              decoration: InputDecoration(
                                labelText: 'Sistema',
                                border: OutlineInputBorder(),
                              ),
                              items: sistemas
                                  .map((sistema) => DropdownMenuItem(
                                value: sistema,
                                child: Text(sistema),
                              ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _filtroSistema = value!;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      // Filtro tipo
                      Expanded(
                        flex: 2,
                        child: FutureBuilder<List<String>>(
                          future: _getTiposDisponibles(),
                          builder: (context, snapshot) {
                            final tipos = snapshot.data ?? ['Todos'];
                            if (!tipos.contains(_filtroTipo)) {
                              _filtroTipo = 'Todos';
                            }
                            return DropdownButtonFormField<String>(
                              value: _filtroTipo,
                              decoration: InputDecoration(
                                labelText: 'Tipo',
                                border: OutlineInputBorder(),
                              ),
                              items: tipos
                                  .map((tipo) => DropdownMenuItem(
                                value: tipo,
                                child: Text(tipo),
                              ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _filtroTipo = value!;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FutureBuilder<List<List<RepuestoCatalogo>>>(
                        future: Future.wait([_getRepuestosFiltrados(), DataService.getCatalogoRepuestos()]),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final filtrados = snapshot.data![0].length;
                            final total = snapshot.data![1].length;
                            return Text(
                              'Mostrando $filtrados de $total repuestos',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            );
                          }
                          return Text(
                            'Cargando...',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          );
                        },
                      ),
                      ElevatedButton.icon(
                        onPressed: _limpiarFiltros,
                        icon: Icon(Icons.clear),
                        label: Text('Limpiar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Lista de repuestos
          Expanded(
            child: FutureBuilder<List<RepuestoCatalogo>>(
              future: _getRepuestosFiltrados(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error al cargar repuestos'),
                        SizedBox(height: 8),
                        Text(snapshot.error.toString()),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                final repuestos = snapshot.data ?? [];
                return repuestos.isEmpty
                    ? _buildEmptyState()
                    : _buildRepuestosList(repuestos);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepuestosList(List<RepuestoCatalogo> repuestos) {
    // Agrupar repuestos por sistema
    final repuestosPorSistema = <String, List<RepuestoCatalogo>>{};
    for (final repuesto in repuestos) {
      final sistema = repuesto.sistemaLabel;
      if (!repuestosPorSistema.containsKey(sistema)) {
        repuestosPorSistema[sistema] = [];
      }
      repuestosPorSistema[sistema]!.add(repuesto);
    }

    return ListView.builder(
      itemCount: repuestosPorSistema.keys.length,
      itemBuilder: (context, index) {
        final sistema = repuestosPorSistema.keys.elementAt(index);
        final repuestosSistema = repuestosPorSistema[sistema]!;

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Row(
              children: [
                _getSistemaIcon(repuestosSistema.first.sistema),
                SizedBox(width: 12),
                Text(
                  sistema,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(width: 8),
                Chip(
                  label: Text('${repuestosSistema.length}'),
                  backgroundColor: Colors.blue[100],
                ),
              ],
            ),
            children: repuestosSistema.map((repuesto) =>
                _buildRepuestoCard(repuesto)
            ).toList(),
          ),
        );
      },
    );
  }

  Widget _getSistemaIcon(SistemaVehiculo sistema) {
    IconData iconData;
    Color color;

    switch (sistema) {
      case SistemaVehiculo.motor:
        iconData = Icons.settings;
        color = Colors.red;
        break;
      case SistemaVehiculo.frenos:
        iconData = Icons.disc_full;
        color = Colors.orange;
        break;
      case SistemaVehiculo.transmision:
        iconData = Icons.settings_applications;
        color = Colors.purple;
        break;
      case SistemaVehiculo.electrico:
        iconData = Icons.electrical_services;
        color = Colors.yellow[700]!;
        break;
      case SistemaVehiculo.suspension:
        iconData = Icons.compare_arrows;
        color = Colors.green;
        break;
      case SistemaVehiculo.neumaticos:
        iconData = Icons.tire_repair;
        color = Colors.black;
        break;
      case SistemaVehiculo.carroceria:
        iconData = Icons.directions_bus;
        color = Colors.blue;
        break;
      case SistemaVehiculo.climatizacion:
        iconData = Icons.ac_unit;
        color = Colors.cyan;
        break;
      case SistemaVehiculo.combustible:
        iconData = Icons.local_gas_station;
        color = Colors.brown;
        break;
      case SistemaVehiculo.refrigeracion:
        iconData = Icons.thermostat;
        color = Colors.lightBlue;
        break;
    }

    return Icon(iconData, color: color, size: 24);
  }

  Widget _buildRepuestoCard(RepuestoCatalogo repuesto) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      repuesto.nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(repuesto.tipoLabel),
                    backgroundColor: _getTipoColor(repuesto.tipo),
                  ),
                ],
              ),
              SizedBox(height: 8),

              Text(
                'Código: ${repuesto.codigo}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),

              Text(repuesto.descripcion),
              SizedBox(height: 12),

              // Información básica
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (repuesto.fabricante != null)
                    _buildInfoChip('Fabricante', repuesto.fabricante!, Icons.factory),
                  if (repuesto.numeroOEM != null)
                    _buildInfoChip('OEM', repuesto.numeroOEM!, Icons.tag),
                  if (repuesto.precioReferencial != null)
                    _buildInfoChip('Precio', ChileanUtils.formatCurrency(repuesto.precioReferencial!), Icons.attach_money),
                ],
              ),

              if (repuesto.observaciones != null) ...[
                SizedBox(height: 8),
                Text(
                  'Observaciones: ${repuesto.observaciones}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],

              // Acciones
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _verDetalles(repuesto),
                    icon: Icon(Icons.info),
                    label: Text('Detalles'),
                  ),
                  SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _mostrarDialogoRepuesto(context, repuesto: repuesto),
                    icon: Icon(Icons.edit),
                    label: Text('Editar'),
                  ),
                  SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _eliminarRepuesto(repuesto.id),
                    icon: Icon(Icons.delete, color: Colors.red),
                    label: Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text('$label: $value', style: TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey[100],
    );
  }

  Color _getTipoColor(TipoRepuesto tipo) {
    switch (tipo) {
      case TipoRepuesto.original:
        return Colors.green[100]!;
      case TipoRepuesto.alternativo:
        return Colors.blue[100]!;
      case TipoRepuesto.generico:
        return Colors.grey[200]!;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            _filtroTexto.isNotEmpty || _filtroSistema != 'Todos' || _filtroTipo != 'Todos'
                ? 'No se encontraron repuestos con los filtros aplicados'
                : 'No hay repuestos en el catálogo',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          if (_filtroTexto.isNotEmpty || _filtroSistema != 'Todos' || _filtroTipo != 'Todos')
            ElevatedButton(
              onPressed: _limpiarFiltros,
              child: Text('Limpiar filtros'),
            )
          else
            Text('Agrega el primer repuesto para comenzar'),
        ],
      ),
    );
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroSistema = 'Todos';
      _filtroTipo = 'Todos';
      _filtroTexto = '';
      _searchController.clear();
    });
  }

  void _mostrarDialogoRepuesto(BuildContext context, {RepuestoCatalogo? repuesto}) {
    showDialog(
      context: context,
      builder: (context) => RepuestoFormDialog(repuesto: repuesto),
    ).then((_) {
      setState(() {});
    });
  }

  void _verDetalles(RepuestoCatalogo repuesto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(repuesto.nombre),
        content: Container(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Código: ${repuesto.codigo}', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Sistema: ${repuesto.sistemaLabel}'),
                Text('Tipo: ${repuesto.tipoLabel}'),
                SizedBox(height: 8),
                Text(repuesto.descripcion),
                SizedBox(height: 16),

                if (repuesto.fabricante != null) ...[
                  Text('Fabricante: ${repuesto.fabricante!}'),
                  SizedBox(height: 4),
                ],

                if (repuesto.numeroOEM != null) ...[
                  Text('Número OEM: ${repuesto.numeroOEM!}'),
                  SizedBox(height: 4),
                ],

                if (repuesto.precioReferencial != null) ...[
                  Text('Precio referencial: ${ChileanUtils.formatCurrency(repuesto.precioReferencial!)}'),
                  SizedBox(height: 16),
                ],

                if (repuesto.observaciones != null) ...[
                  Text('Observaciones:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(repuesto.observaciones!),
                  SizedBox(height: 16),
                ],

                Text('Actualizado: ${ChileanUtils.formatDate(repuesto.fechaActualizacion)}'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _eliminarRepuesto(String id) async {
    final repuesto = await DataService.getRepuestoCatalogoById(id);
    if (repuesto == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar ${repuesto.nombre} del catálogo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await DataService.deleteRepuestoCatalogo(id);
                Navigator.pop(context);
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${repuesto.nombre} eliminado del catálogo'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar el repuesto: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}