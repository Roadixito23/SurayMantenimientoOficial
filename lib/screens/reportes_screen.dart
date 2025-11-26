import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bus.dart';
import '../models/mantencion.dart';
import '../models/reporte_diario.dart';
import '../models/mantenimiento_preventivo.dart';
import '../models/tipo_mantenimiento_personalizado.dart';
import '../screens/reporte_editor_screen.dart'; // Importar la pantalla de edición
import '../services/data_service.dart';
import '../services/chilean_utils.dart';
import '../widgets/editar_mantenimiento_dialog.dart';


class HistorialGlobalScreen extends StatefulWidget {
  @override
  _HistorialGlobalScreenState createState() => _HistorialGlobalScreenState();
}

class _HistorialGlobalScreenState extends State<HistorialGlobalScreen> {
  String? _filtroBusId;
  DateTimeRange? _filtroFecha;

  late Future<List<Map<String, dynamic>>> _actividadesFuture;

  @override
  void initState() {
    super.initState();
    _actividadesFuture = _getRegistrosCompletos();
  }

  void _refrescarActividades() {
    setState(() {
      _actividadesFuture = _getRegistrosCompletos();
    });
  }

  Future<List<Map<String, dynamic>>> _getRegistrosCompletos() async {
    List<Map<String, dynamic>> todosLosRegistros = [];
    final todosLosBuses = await DataService.getBuses();
    final todosLosReportes = await DataService.getReportes();

    for (final bus in todosLosBuses) {
      if (bus.mantenimientoPreventivo != null) {
        for (final mantenimiento in bus.mantenimientoPreventivo!.historialMantenimientos) {
          todosLosRegistros.add({
            'tipo': 'mantenimiento_nuevo',
            'busId': bus.id,
            'busDisplay': bus.identificadorDisplay,
            'fecha': mantenimiento.fechaUltimoCambio,
            'descripcion': mantenimiento.descripcionTipo,
            'data': mantenimiento,
            'tecnico': mantenimiento.tecnicoResponsable,
            'observaciones': mantenimiento.observaciones,
            'tipoMantenimiento': mantenimiento.tipoMantenimientoEfectivo,
          });
        }
      }
      for (final mantencion in bus.historialMantenciones) {
        todosLosRegistros.add({
          'tipo': 'mantenimiento_antiguo',
          'busId': bus.id,
          'busDisplay': bus.identificadorDisplay,
          'fecha': mantencion.fecha,
          'descripcion': mantencion.descripcion,
          'data': mantencion,
          'tecnico': 'No registrado',
          'observaciones': 'Costo: ${ChileanUtils.formatCurrency(mantencion.costoTotal ?? 0)}',
          'tipoMantenimiento': TipoMantenimiento.correctivo,
        });
      }
    }

    for (final reporte in todosLosReportes) {
      todosLosRegistros.add({
        'tipo': 'reporte',
        'fecha': reporte.fecha,
        'descripcion': 'Reporte ${reporte.numeroReporte} - ${reporte.tipoTrabajoDisplay}',
        'data': reporte,
        'autor': reporte.autor,
        'observaciones': reporte.observaciones,
        'busesReporte': reporte.busesAtendidos,
      });
    }

    var registrosFiltrados = todosLosRegistros.where((registro) {
      if (_filtroBusId != null) {
        if (registro['tipo'] == 'reporte') {
          final busFiltrado = todosLosBuses.firstWhere((b) => b.id == _filtroBusId, orElse: () => Bus(id: '', patente: '', marca: '', modelo: '', anio: 0, estado: EstadoBus.disponible, historialMantenciones: [], fechaRegistro: DateTime.now()));
          if (!(registro['busesReporte'] as List).contains(busFiltrado.patente)) {
            return false;
          }
        } else if (registro['busId'] != _filtroBusId) {
          return false;
        }
      }

      if (_filtroFecha != null) {
        final fechaRegistro = registro['fecha'] as DateTime;
        final start = _filtroFecha!.start;
        final end = DateTime(_filtroFecha!.end.year, _filtroFecha!.end.month, _filtroFecha!.end.day, 23, 59);
        if (fechaRegistro.isBefore(start) || fechaRegistro.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList();

    registrosFiltrados.sort((a, b) => (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime));
    return registrosFiltrados;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historial Global de Actividades',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          _buildFiltrosPanel(),
          SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _actividadesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar el historial: ${snapshot.error}'));
                }
                final actividades = snapshot.data ?? [];
                if (actividades.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  itemCount: actividades.length,
                  itemBuilder: (context, index) => _buildRegistroCard(actividades[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: FutureBuilder<List<Bus>>(
                future: DataService.getBuses(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Text('Cargando buses...');
                  final buses = snapshot.data!..sort((a, b) => a.identificadorDisplay.compareTo(b.identificadorDisplay));
                  return DropdownButtonFormField<String>(
                    value: _filtroBusId,
                    hint: Text('Toda la flota'),
                    decoration: InputDecoration(
                        labelText: 'Filtrar por Bus',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.directions_bus),
                        suffixIcon: _filtroBusId != null ? IconButton(icon: Icon(Icons.clear), onPressed: () => setState((){_filtroBusId=null; _refrescarActividades();})) : null
                    ),
                    items: buses.map((bus) => DropdownMenuItem(value: bus.id, child: Text(bus.identificadorDisplay))).toList(),
                    onChanged: (value) => setState(() {
                      _filtroBusId = value;
                      _refrescarActividades();
                    }),
                  );
                },
              ),
            ),
            SizedBox(width: 16),
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
                  if (picked != null) setState(() {
                    _filtroFecha = picked;
                    _refrescarActividades();
                  });
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                      labelText: 'Filtrar por Fecha',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                      suffixIcon: _filtroFecha != null ? IconButton(icon: Icon(Icons.clear), onPressed: () => setState((){_filtroFecha=null; _refrescarActividades();})) : null
                  ),
                  child: Text(
                    _filtroFecha != null
                        ? '${DateFormat('dd/MM/yy').format(_filtroFecha!.start)} - ${DateFormat('dd/MM/yy').format(_filtroFecha!.end)}'
                        : 'Cualquier fecha',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistroCard(Map<String, dynamic> registro) {
    final String tipo = registro['tipo'];
    final DateTime fecha = registro['fecha'];
    final String descripcion = registro['descripcion'];
    final String? busDisplay = registro['busDisplay'];

    Color tipoColor;
    IconData tipoIcon;

    if (tipo.startsWith('mantenimiento')) {
      final TipoMantenimiento tipoMant = registro['tipoMantenimiento'];
      tipoColor = _getColorTipoMantenimiento(tipoMant);
      tipoIcon = _getIconTipoMantenimiento(tipoMant);
    } else { // 'reporte'
      final ReporteDiario reporteData = registro['data'] as ReporteDiario;
      tipoColor = reporteData.colorTipoTrabajo;
      tipoIcon = reporteData.iconoTipoTrabajo;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: tipoColor, borderRadius: BorderRadius.circular(8)),
          child: Icon(tipoIcon, color: Colors.white, size: 24),
        ),
        title: Text(descripcion, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(ChileanUtils.formatDate(fecha), style: TextStyle(fontSize: 12)),
              if (busDisplay != null) ...[
                SizedBox(width: 12),
                Icon(Icons.directions_bus, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(busDisplay, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ]
            ],
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: _buildRegistroDetails(registro),
          ),
        ],
      ),
    );
  }

  // ✅ WIDGET DE DETALLES MEJORADO CON TÉCNICO Y ACCIONES
  Widget _buildRegistroDetails(Map<String, dynamic> registro) {
    final tecnico = registro['tecnico'] ?? registro['autor'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1),
        SizedBox(height: 12),

        // Fila de información adicional
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (tecnico != null)
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[700]),
                  SizedBox(width: 8),
                  Text('Técnico/Autor: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(tecnico),
                ],
              ),
            // Puedes añadir más detalles aquí (ej. costo, km)
          ],
        ),
        SizedBox(height: 12),

        // Observaciones
        if (registro['observaciones'] != null && registro['observaciones'].isNotEmpty) ...[
          Text('Observaciones:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${registro['observaciones']}', style: TextStyle(fontSize: 13, height: 1.4)),
          ),
        ],
        SizedBox(height: 16),

        // Botones de acción
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () => _editarActividad(registro),
              icon: Icon(Icons.edit, size: 16),
              label: Text('Editar'),
              style: TextButton.styleFrom(foregroundColor: Colors.blue[700]),
            ),
            SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => _eliminarActividad(registro),
              icon: Icon(Icons.delete_outline, size: 16),
              label: Text('Eliminar'),
              style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
            ),
          ],
        ),
      ],
    );
  }

  // ✅ NUEVOS MÉTODOS PARA MANEJAR LAS ACCIONES
  void _editarActividad(Map<String, dynamic> registro) async {
    final tipo = registro['tipo'];

    if (tipo == 'reporte') {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => ReporteEditorScreen(reporteBase: registro['data'] as ReporteDiario),
      )).then((_) => _refrescarActividades());

    } else if (tipo == 'mantenimiento_nuevo') {
      // ✅ Llama al nuevo diálogo de edición
      final bus = await DataService.getBusById(registro['busId']);
      if (bus != null) {
        showDialog(
          context: context,
          builder: (context) => EditarMantenimientoDialog(
            bus: bus,
            registroParaEditar: registro['data'] as RegistroMantenimiento,
            onMantenimientoGuardado: _refrescarActividades,
          ),
        );
      }
    } else {
      // Para mantenimientos del sistema antiguo o tipos no soportados
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La edición para este tipo de registro aún no está implementada.'), backgroundColor: Colors.orange),
      );
    }
  }

  void _eliminarActividad(Map<String, dynamic> registro) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar este registro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar')),
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
      if (registro['tipo'] == 'reporte') {
        final reporte = registro['data'] as ReporteDiario;
        await DataService.deleteReporte(reporte.id);
      } else if (registro['tipo'] == 'mantenimiento_nuevo') {
        final mant = registro['data'] as RegistroMantenimiento;
        await DataService.deleteMantenimientoFromBus(registro['busId'], mant.id, 'nuevo');
      } else if (registro['tipo'] == 'mantenimiento_antiguo') {
        final mant = registro['data'] as Mantencion;
        await DataService.deleteMantenimientoFromBus(registro['busId'], mant.id, 'antiguo');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registro eliminado exitosamente'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
      );
    }

    _refrescarActividades();
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No hay actividades que coincidan con los filtros',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Prueba a cambiar los filtros de bus o de fecha para ver resultados.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getColorTipoMantenimiento(TipoMantenimiento tipo) {
    switch (tipo) {
      case TipoMantenimiento.correctivo: return Color(0xFFE53E3E);
      case TipoMantenimiento.rutinario: return Color(0xFF3182CE);
      case TipoMantenimiento.preventivo: return Color(0xFF38A169);
    }
  }

  IconData _getIconTipoMantenimiento(TipoMantenimiento tipo) {
    switch (tipo) {
      case TipoMantenimiento.correctivo: return Icons.handyman;
      case TipoMantenimiento.rutinario: return Icons.schedule;
      case TipoMantenimiento.preventivo: return Icons.build_circle;
    }
  }
}