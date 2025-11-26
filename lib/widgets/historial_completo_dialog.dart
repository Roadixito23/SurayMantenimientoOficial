import 'package:flutter/material.dart';
import '../models/bus.dart';
import '../models/reporte_diario.dart';
import '../models/mantenimiento_preventivo.dart';
import '../models/tipo_mantenimiento_personalizado.dart';
import '../services/data_service.dart';
import '../services/chilean_utils.dart';

class HistorialCompletoDialog extends StatefulWidget {
  final Bus bus;

  HistorialCompletoDialog({required this.bus});

  @override
  _HistorialCompletoDialogState createState() => _HistorialCompletoDialogState();
}

class _HistorialCompletoDialogState extends State<HistorialCompletoDialog> {
  String _filtroTipo = 'Todos';
  String _filtroEstado = 'Todos';
  String _filtroTipoMantenimiento = 'Todos'; // ✅ ACTUALIZADO: Filtro por tipo de mantenimiento
  String _filtroTipoTrabajo = 'Todos'; // Filtro por tipo de trabajo (reportes)

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.history, color: Color(0xFF1565C0)),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Historial Completo'),
                Text(
                  '${widget.bus.identificadorDisplay} - ${widget.bus.marca} ${widget.bus.modelo} (${widget.bus.anio})',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        constraints: BoxConstraints(maxWidth: 900),
        child: Column(
          children: [
            // Estadísticas resumidas
            _buildEstadisticasCard(),
            SizedBox(height: 16),

            // Filtros actualizados
            _buildFiltrosActualizados(),
            SizedBox(height: 16),

            // Lista combinada de mantenimientos y reportes
            Expanded(
              child: _buildListaCompleta(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cerrar'),
        ),
        ElevatedButton.icon(
          onPressed: () => _exportarHistorial(),
          icon: Icon(Icons.download),
          label: Text('Exportar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1565C0),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildEstadisticasCard() {
    return FutureBuilder<Map<String, int>>(
      future: _getEstadisticasCompletas(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(height: 80, child: Center(child: CircularProgressIndicator()));
        }

        final stats = snapshot.data!;
        return Card(
          color: Colors.blue[50],
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Registros',
                  '${stats['total']}',
                  Icons.list_alt,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Correctivos',
                  stats['correctivos'].toString(),
                  Icons.handyman,
                  Color(0xFFE53E3E),
                ),
                _buildStatItem(
                  'Rutinarios',
                  stats['rutinarios'].toString(),
                  Icons.schedule,
                  Color(0xFF3182CE),
                ),
                _buildStatItem(
                  'Preventivos',
                  stats['preventivos'].toString(),
                  Icons.build_circle,
                  Color(0xFF38A169),
                ),
                _buildStatItem(
                  'Reportes',
                  stats['reportes'].toString(),
                  Icons.description,
                  Colors.purple,
                ),
                _buildStatItem(
                  'Completados',
                  stats['completados'].toString(),
                  Icons.check_circle,
                  Colors.teal,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFiltrosActualizados() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Primera fila de filtros
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filtroTipo,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Actividad',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                      DropdownMenuItem(value: 'Mantenimiento', child: Text('🔧 Mantenimientos')),
                      DropdownMenuItem(value: 'Reporte', child: Text('📋 Reportes de Trabajo')),
                    ],
                    onChanged: (value) => setState(() => _filtroTipo = value!),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filtroEstado,
                    decoration: InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                      DropdownMenuItem(value: 'Completados', child: Text('Completados')),
                      DropdownMenuItem(value: 'En Progreso', child: Text('En Progreso')),
                    ],
                    onChanged: (value) => setState(() => _filtroEstado = value!),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Segunda fila: Filtros específicos por tipo
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filtroTipoMantenimiento,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Mantenimiento',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos los tipos')),
                      DropdownMenuItem(value: 'Correctivo', child: Row(
                        children: [
                          Icon(Icons.handyman, size: 16, color: Color(0xFFE53E3E)),
                          SizedBox(width: 8),
                          Text('Correctivo'),
                        ],
                      )),
                      DropdownMenuItem(value: 'Rutinario', child: Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: Color(0xFF3182CE)),
                          SizedBox(width: 8),
                          Text('Rutinario'),
                        ],
                      )),
                      DropdownMenuItem(value: 'Preventivo', child: Row(
                        children: [
                          Icon(Icons.build_circle, size: 16, color: Color(0xFF38A169)),
                          SizedBox(width: 8),
                          Text('Preventivo'),
                        ],
                      )),
                    ],
                    onChanged: (value) => setState(() => _filtroTipoMantenimiento = value!),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filtroTipoTrabajo,
                    decoration: InputDecoration(
                      labelText: 'Categoría de Trabajo (Reportes)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: 'Todos', child: Text('Todas las categorías')),
                      DropdownMenuItem(value: 'Mantenimiento Rutinario', child: Text('🔵 Mantenimiento Rutinario')),
                      DropdownMenuItem(value: 'Reparación Correctiva', child: Text('🔴 Reparación Correctiva')),
                      DropdownMenuItem(value: 'Inspección Técnica', child: Text('🟣 Inspección Técnica')),
                      DropdownMenuItem(value: 'Mantenimiento Preventivo', child: Text('🟢 Mantenimiento Preventivo')),
                      DropdownMenuItem(value: 'Diagnóstico', child: Text('🟠 Diagnóstico')),
                      DropdownMenuItem(value: 'Limpieza y Mantenimiento', child: Text('🟡 Limpieza y Mantenimiento')),
                      DropdownMenuItem(value: 'Otros', child: Text('⚪ Otros')),
                    ],
                    onChanged: (value) => setState(() => _filtroTipoTrabajo = value!),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Botón limpiar filtros
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _limpiarFiltros,
                  icon: Icon(Icons.clear),
                  label: Text('Limpiar Filtros'),
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
    );
  }

  Widget _buildListaCompleta() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getRegistrosCompletos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final registros = snapshot.data ?? [];

        if (registros.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          itemCount: registros.length,
          itemBuilder: (context, index) {
            final registro = registros[index];
            return _buildRegistroCard(registro);
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getRegistrosCompletos() async {
    List<Map<String, dynamic>> todosLosRegistros = [];

    // ✅ ACTUALIZADO: Obtener mantenimientos personalizados y tradicionales
    if (widget.bus.mantenimientoPreventivo != null) {
      for (final mantenimiento in widget.bus.mantenimientoPreventivo!.historialMantenimientos) {
        if (_debeIncluirMantenimiento(mantenimiento)) {
          todosLosRegistros.add({
            'tipo': 'mantenimiento',
            'fecha': mantenimiento.fechaUltimoCambio,
            'descripcion': mantenimiento.descripcionTipo,
            'completada': true,
            'repuestos': mantenimiento.marcaRepuesto != null ? [mantenimiento.marcaRepuesto!] : [],
            'data': mantenimiento,
            'tecnico': mantenimiento.tecnicoResponsable,
            'observaciones': mantenimiento.observaciones,
            'kilometraje': mantenimiento.kilometrajeUltimoCambio,
            'tipoMantenimiento': mantenimiento.tipoMantenimientoEfectivo,
            'tipoTrabajo': 'Mantenimiento ${_getLabelTipoMantenimiento(mantenimiento.tipoMantenimientoEfectivo)}',
          });
        }
      }
    }


    // Obtener reportes específicos del bus
    final reportesDelBus = await DataService.getReportesPorBus(widget.bus.patente);
    for (final reporte in reportesDelBus) {
      if (_debeIncluirReporte(reporte)) {
        todosLosRegistros.add({
          'tipo': 'reporte',
          'fecha': reporte.fecha,
          'descripcion': 'Reporte ${reporte.numeroReporte} - ${reporte.tipoTrabajoDisplay}',
          'completada': true,
          'repuestos': <String>[],
          'data': reporte,
          'autor': reporte.autor,
          'numeroReporte': reporte.numeroReporte,
          'tipoTrabajo': reporte.tipoTrabajoDisplay,
          'observaciones': reporte.observaciones,
        });
      }
    }

    // Ordenar por fecha descendente
    todosLosRegistros.sort((a, b) => (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime));

    return todosLosRegistros;
  }

  bool _debeIncluirMantenimiento(RegistroMantenimiento mantenimiento) {
    // Filtrar por tipo de actividad
    if (_filtroTipo != 'Todos' && _filtroTipo != 'Mantenimiento') return false;

    // Los mantenimientos siempre están completados
    if (_filtroEstado == 'En Progreso') return false;

    // ✅ NUEVO: Filtrar por tipo de mantenimiento
    if (_filtroTipoMantenimiento != 'Todos') {
      final tipoRequerido = _getTipoMantenimientoFromString(_filtroTipoMantenimiento);
      if (tipoRequerido != null && mantenimiento.tipoMantenimientoEfectivo != tipoRequerido) {
        return false;
      }
    }

    return true;
  }


  bool _debeIncluirReporte(ReporteDiario reporte) {
    // Filtrar por tipo de actividad
    if (_filtroTipo != 'Todos' && _filtroTipo != 'Reporte') return false;

    // Los reportes siempre están completados
    if (_filtroEstado == 'En Progreso') return false;

    // Filtrar por tipo de trabajo específico
    if (_filtroTipoTrabajo != 'Todos' && _filtroTipoTrabajo != reporte.tipoTrabajoDisplay) return false;

    return true;
  }

  Widget _buildRegistroCard(Map<String, dynamic> registro) {
    final String tipo = registro['tipo'];
    final DateTime fecha = registro['fecha'];
    final String descripcion = registro['descripcion'];
    final bool completada = registro['completada'];
    final List<String> repuestos = List<String>.from(registro['repuestos'] ?? []);
    final String tipoTrabajo = registro['tipoTrabajo'] ?? 'Sin Categorizar';

    Color tipoColor;
    IconData tipoIcon;
    String tipoLabel;

    if (tipo == 'mantenimiento') {
      final TipoMantenimiento tipoMant = registro['tipoMantenimiento'] ?? TipoMantenimiento.preventivo;
      tipoColor = _getColorTipoMantenimiento(tipoMant);
      tipoIcon = _getIconTipoMantenimiento(tipoMant);
      tipoLabel = _getLabelTipoMantenimiento(tipoMant).toUpperCase();
    } else if (tipo == 'reporte') {
      final ReporteDiario reporteData = registro['data'] as ReporteDiario;
      tipoColor = reporteData.colorTipoTrabajo;
      tipoIcon = reporteData.iconoTipoTrabajo;
      tipoLabel = 'REPORTE';
    } else {
      tipoColor = Colors.grey;
      tipoIcon = Icons.help;
      tipoLabel = 'DESCONOCIDO';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tipoColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(tipoIcon, color: Colors.white, size: 20),
        ),
        title: Text(
          descripcion,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tipoColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tipoLabel,
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                // Chip para el tipo específico
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tipoColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: tipoColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    tipoTrabajo,
                    style: TextStyle(
                      color: tipoColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(ChileanUtils.formatDate(fecha), style: TextStyle(fontSize: 12)),
                if (registro['kilometraje'] != null) ...[
                  SizedBox(width: 12),
                  Icon(Icons.speed, size: 14, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text('${registro['kilometraje'].round()} km', style: TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ],
        ),
        trailing: Icon(
          completada ? Icons.check_circle : Icons.schedule,
          color: completada ? Colors.green : Colors.orange,
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildRegistroDetails(registro, tipo, tipoColor),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRegistroDetails(Map<String, dynamic> registro, String tipo, Color tipoColor) {
    List<Widget> details = [];

    // Información específica según el tipo
    if (tipo == 'mantenimiento') {
      final RegistroMantenimiento mantenimiento = registro['data'] as RegistroMantenimiento;
      details.add(
        Row(
          children: [
            Icon(Icons.speed, size: 16, color: Colors.grey[600]),
            SizedBox(width: 8),
            Text('Kilometraje: ${mantenimiento.kilometrajeUltimoCambio.round()} km'),
          ],
        ),
      );

      if (registro['tecnico'] != null) {
        details.add(SizedBox(height: 4));
        details.add(
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text('Técnico: ${registro['tecnico']}'),
            ],
          ),
        );
      }

      // ✅ NUEVO: Mostrar tipo de mantenimiento
      details.add(SizedBox(height: 4));
      details.add(
        Row(
          children: [
            Icon(_getIconTipoMantenimiento(mantenimiento.tipoMantenimientoEfectivo),
                size: 16, color: _getColorTipoMantenimiento(mantenimiento.tipoMantenimientoEfectivo)),
            SizedBox(width: 8),
            Text('Tipo: ${_getLabelTipoMantenimiento(mantenimiento.tipoMantenimientoEfectivo)}'),
          ],
        ),
      );

    } else if (tipo == 'reporte') {
      final ReporteDiario reporte = registro['data'] as ReporteDiario;
      details.add(
        Row(
          children: [
            Icon(Icons.assignment, size: 16, color: Colors.grey[600]),
            SizedBox(width: 8),
            Text('Reporte N° ${reporte.numeroReporte}'),
          ],
        ),
      );
      details.add(SizedBox(height: 4));
      details.add(
        Row(
          children: [
            Icon(Icons.person, size: 16, color: Colors.grey[600]),
            SizedBox(width: 8),
            Text('Autor: ${reporte.autor}'),
          ],
        ),
      );
    }

    // Observaciones
    if (registro['observaciones'] != null) {
      details.add(SizedBox(height: 8));
      details.add(
        Text(
          tipo == 'reporte' ? 'Detalle del trabajo realizado:' : 'Observaciones:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
      details.add(SizedBox(height: 4));
      details.add(
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            '${registro['observaciones']}',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            maxLines: tipo == 'reporte' ? null : 3,
            overflow: tipo == 'reporte' ? null : TextOverflow.ellipsis,
          ),
        ),
      );
    }

    // Repuestos utilizados
    final List<String> repuestos = List<String>.from(registro['repuestos'] ?? []);
    if (repuestos.isNotEmpty) {
      details.add(SizedBox(height: 12));
      details.add(
        Text(
          'Repuestos/Materiales utilizados:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
      details.add(SizedBox(height: 8));
      details.add(
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: repuestos.map((repuesto) => Chip(
            label: Text(repuesto, style: TextStyle(fontSize: 11)),
            backgroundColor: tipoColor.withOpacity(0.1),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          )).toList(),
        ),
      );
    }

    return details;
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No hay registros de actividades',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Los mantenimientos y reportes aparecerán aquí cuando se registren',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<Map<String, int>> _getEstadisticasCompletas() async {
    final reportesDelBus = await DataService.getReportesPorBus(widget.bus.patente);

    final estadisticasMantenimiento = widget.bus.estadisticasMantenimientosPorTipo;

    final totalCorrectivos = estadisticasMantenimiento[TipoMantenimiento.correctivo] ?? 0;
    final totalRutinarios = estadisticasMantenimiento[TipoMantenimiento.rutinario] ?? 0;
    final totalPreventivos = estadisticasMantenimiento[TipoMantenimiento.preventivo] ?? 0;
    final totalReportes = reportesDelBus.length;
    final totalCompleto = totalCorrectivos + totalRutinarios + totalPreventivos + totalReportes;

    final completados = totalCorrectivos + totalRutinarios + totalPreventivos + totalReportes;

    return {
      'total': totalCompleto,
      'preventivos': totalPreventivos,
      'correctivos': totalCorrectivos,
      'rutinarios': totalRutinarios,
      'reportes': totalReportes,
      'completados': completados,
    };
  }

  // ✅ NUEVOS MÉTODOS para tipos de mantenimiento
  TipoMantenimiento? _getTipoMantenimientoFromString(String tipo) {
    switch (tipo) {
      case 'Correctivo':
        return TipoMantenimiento.correctivo;
      case 'Rutinario':
        return TipoMantenimiento.rutinario;
      case 'Preventivo':
        return TipoMantenimiento.preventivo;
      default:
        return null;
    }
  }

  String _getLabelTipoMantenimiento(TipoMantenimiento tipo) {
    switch (tipo) {
      case TipoMantenimiento.correctivo:
        return 'Correctivo';
      case TipoMantenimiento.rutinario:
        return 'Rutinario';
      case TipoMantenimiento.preventivo:
        return 'Preventivo';
    }
  }

  Color _getColorTipoMantenimiento(TipoMantenimiento tipo) {
    switch (tipo) {
      case TipoMantenimiento.correctivo:
        return Color(0xFFE53E3E);
      case TipoMantenimiento.rutinario:
        return Color(0xFF3182CE);
      case TipoMantenimiento.preventivo:
        return Color(0xFF38A169);
    }
  }

  IconData _getIconTipoMantenimiento(TipoMantenimiento tipo) {
    switch (tipo) {
      case TipoMantenimiento.correctivo:
        return Icons.handyman;
      case TipoMantenimiento.rutinario:
        return Icons.schedule;
      case TipoMantenimiento.preventivo:
        return Icons.build_circle;
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroTipo = 'Todos';
      _filtroEstado = 'Todos';
      _filtroTipoMantenimiento = 'Todos';
      _filtroTipoTrabajo = 'Todos';
    });
  }

  void _exportarHistorial() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Funcionalidad de exportar en desarrollo'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}