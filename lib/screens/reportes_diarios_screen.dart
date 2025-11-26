import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reporte_diario.dart';
import '../services/data_service.dart';
import '../services/chilean_utils.dart';
import 'reporte_editor_screen.dart';

class ReportesDiariosScreen extends StatefulWidget {
  @override
  _ReportesDiariosScreenState createState() => _ReportesDiariosScreenState();
}

class _ReportesDiariosScreenState extends State<ReportesDiariosScreen> {
  String _filtroTipoTrabajo = 'Todos';
  DateTimeRange? _filtroFecha;
  String _filtroTexto = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<ReporteDiario>> _getReportesFiltrados() async {
    var reportes = await DataService.getReportes();

    // Filtrar por tipo de trabajo
    if (_filtroTipoTrabajo != 'Todos') {
      reportes = reportes.where((r) => r.tipoTrabajoDisplay == _filtroTipoTrabajo).toList();
    }

    // Filtrar por rango de fechas
    if (_filtroFecha != null) {
      reportes = reportes.where((r) {
        final start = _filtroFecha!.start;
        final end = DateTime(
          _filtroFecha!.end.year,
          _filtroFecha!.end.month,
          _filtroFecha!.end.day,
          23,
          59,
        );
        return r.fecha.isAfter(start.subtract(Duration(days: 1))) &&
               r.fecha.isBefore(end.add(Duration(days: 1)));
      }).toList();
    }

    // Filtrar por texto de búsqueda
    if (_filtroTexto.isNotEmpty) {
      reportes = reportes.where((r) =>
        r.numeroReporte.toLowerCase().contains(_filtroTexto.toLowerCase()) ||
        r.observaciones.toLowerCase().contains(_filtroTexto.toLowerCase()) ||
        r.autor.toLowerCase().contains(_filtroTexto.toLowerCase()) ||
        r.busesAtendidos.any((b) => b.toLowerCase().contains(_filtroTexto.toLowerCase()))
      ).toList();
    }

    // Ordenar por fecha descendente
    reportes.sort((a, b) => b.fecha.compareTo(a.fecha));

    return reportes;
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reportes Diarios',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gestión de informes de trabajo diario',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _crearNuevoReporte(),
                icon: Icon(Icons.add),
                label: Text('Nuevo Reporte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Estadísticas rápidas
          _buildEstadisticasCard(),

          SizedBox(height: 24),

          // Panel de filtros
          _buildFiltrosPanel(),

          SizedBox(height: 16),

          // Lista de reportes
          Expanded(
            child: FutureBuilder<List<ReporteDiario>>(
              future: _getReportesFiltrados(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final reportes = snapshot.data ?? [];

                if (reportes.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  itemCount: reportes.length,
                  itemBuilder: (context, index) => _buildReporteCard(reportes[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticasCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: DataService.getEstadisticasReportes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
        }

        final stats = snapshot.data!;
        return Card(
          elevation: 2,
          color: Colors.blue[50],
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total',
                  '${stats['total']}',
                  Icons.description,
                  Colors.blue[700]!,
                ),
                _buildStatItem(
                  'Hoy',
                  '${stats['hoy']}',
                  Icons.today,
                  Colors.green[700]!,
                ),
                _buildStatItem(
                  'Esta Semana',
                  '${stats['semana']}',
                  Icons.date_range,
                  Colors.orange[700]!,
                ),
                _buildStatItem(
                  'Este Mes',
                  '${stats['mes']}',
                  Icons.calendar_month,
                  Colors.purple[700]!,
                ),
                _buildStatItem(
                  'Buses Atendidos (Mes)',
                  '${stats['busesAtendidosMes']}',
                  Icons.directions_bus,
                  Colors.teal[700]!,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFiltrosPanel() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: Colors.blue[700]),
                SizedBox(width: 8),
                Text(
                  'Filtros',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                // Búsqueda
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar por número, autor, observaciones o bus',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      suffixIcon: _filtroTexto.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _filtroTexto = '';
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() => _filtroTexto = value),
                  ),
                ),
                SizedBox(width: 16),
                // Filtro tipo de trabajo
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _filtroTipoTrabajo,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Trabajo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                    ),
                    items: [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                      DropdownMenuItem(
                        value: 'Mantenimiento Rutinario',
                        child: Text('🔵 Mantenimiento Rutinario'),
                      ),
                      DropdownMenuItem(
                        value: 'Reparación Correctiva',
                        child: Text('🔴 Reparación Correctiva'),
                      ),
                      DropdownMenuItem(
                        value: 'Inspección Técnica',
                        child: Text('🟣 Inspección Técnica'),
                      ),
                      DropdownMenuItem(
                        value: 'Mantenimiento Preventivo',
                        child: Text('🟢 Mantenimiento Preventivo'),
                      ),
                      DropdownMenuItem(
                        value: 'Diagnóstico',
                        child: Text('🟠 Diagnóstico'),
                      ),
                      DropdownMenuItem(
                        value: 'Limpieza y Mantenimiento',
                        child: Text('🟡 Limpieza y Mantenimiento'),
                      ),
                      DropdownMenuItem(
                        value: 'Otros',
                        child: Text('⚪ Otros'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _filtroTipoTrabajo = value!),
                  ),
                ),
                SizedBox(width: 16),
                // Filtro de fecha
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(Duration(days: 1)),
                        initialDateRange: _filtroFecha,
                      );
                      if (picked != null) {
                        setState(() => _filtroFecha = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Rango de Fechas',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                        suffixIcon: _filtroFecha != null
                            ? IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () => setState(() => _filtroFecha = null),
                              )
                            : null,
                      ),
                      child: Text(
                        _filtroFecha != null
                            ? '${DateFormat('dd/MM/yy').format(_filtroFecha!.start)} - ${DateFormat('dd/MM/yy').format(_filtroFecha!.end)}'
                            : 'Todas las fechas',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FutureBuilder<List<List<ReporteDiario>>>(
                  future: Future.wait([
                    _getReportesFiltrados(),
                    DataService.getReportes(),
                  ]),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final filtrados = snapshot.data![0].length;
                      final total = snapshot.data![1].length;
                      return Text(
                        'Mostrando $filtrados de $total reportes',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      );
                    }
                    return SizedBox();
                  },
                ),
                ElevatedButton.icon(
                  onPressed: _limpiarFiltros,
                  icon: Icon(Icons.clear_all),
                  label: Text('Limpiar Filtros'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReporteCard(ReporteDiario reporte) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: reporte.colorTipoTrabajo,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            reporte.iconoTipoTrabajo,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Text(
              'Reporte ${reporte.numeroReporte}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(width: 12),
            Chip(
              label: Text(
                reporte.tipoTrabajoDisplay,
                style: TextStyle(fontSize: 11, color: Colors.white),
              ),
              backgroundColor: reporte.colorTipoTrabajo,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    ChileanUtils.formatDate(reporte.fecha),
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    reporte.autor,
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.directions_bus, size: 14, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Buses: ${reporte.busesAtendidos.join(", ")}',
                      style: TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(height: 1),
                SizedBox(height: 16),
                Text(
                  'Descripción del Trabajo:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    reporte.observaciones,
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _editarReporte(reporte),
                      icon: Icon(Icons.edit, size: 18),
                      label: Text('Editar'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue[700]),
                    ),
                    SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _eliminarReporte(reporte),
                      icon: Icon(Icons.delete, size: 18),
                      label: Text('Eliminar'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hayFiltros = _filtroTexto.isNotEmpty ||
        _filtroTipoTrabajo != 'Todos' ||
        _filtroFecha != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hayFiltros ? Icons.search_off : Icons.description,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            hayFiltros
                ? 'No se encontraron reportes con los filtros aplicados'
                : 'No hay reportes diarios registrados',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            hayFiltros
                ? 'Prueba ajustando los filtros para ver más resultados'
                : 'Crea el primer reporte diario para comenzar',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: hayFiltros ? _limpiarFiltros : _crearNuevoReporte,
            icon: Icon(hayFiltros ? Icons.clear : Icons.add),
            label: Text(hayFiltros ? 'Limpiar Filtros' : 'Crear Primer Reporte'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1565C0),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Error al cargar reportes',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: Icon(Icons.refresh),
            label: Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroTipoTrabajo = 'Todos';
      _filtroFecha = null;
      _filtroTexto = '';
      _searchController.clear();
    });
  }

  void _crearNuevoReporte() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReporteEditorScreen()),
    ).then((_) => setState(() {}));
  }

  void _editarReporte(ReporteDiario reporte) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReporteEditorScreen(reporteBase: reporte),
      ),
    ).then((_) => setState(() {}));
  }

  void _eliminarReporte(ReporteDiario reporte) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el reporte ${reporte.numeroReporte}?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Eliminar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await DataService.deleteReporte(reporte.id);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reporte ${reporte.numeroReporte} eliminado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar el reporte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
