import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/bus.dart';
import '../../../../models/reporte_diario.dart';
import '../../../../models/mantenimiento_preventivo.dart';
import '../../../../models/tipo_mantenimiento_personalizado.dart';
import '../../../../services/data_service.dart';
import '../../../../services/chilean_utils.dart';
import '../../../../main.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class HistorialCompletoMobileLayout extends StatefulWidget {
  final Bus bus;

  const HistorialCompletoMobileLayout({
    Key? key,
    required this.bus,
  }) : super(key: key);

  @override
  State<HistorialCompletoMobileLayout> createState() =>
      _HistorialCompletoMobileLayoutState();
}

class _HistorialCompletoMobileLayoutState
    extends State<HistorialCompletoMobileLayout> {
  String _filtroTipo = 'Todos';
  String _filtroEstado = 'Todos';
  String _filtroTipoMantenimiento = 'Todos';
  String _filtroTipoTrabajo = 'Todos';

  bool _mostrarFiltros = false; // Control para mostrar/ocultar filtros

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial Completo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.bus.identificadorDisplay,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SurayColors.azulMarinoProfundo,
                SurayColors.azulMarinoProfundo.withOpacity(0.8)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            tooltip: 'Exportar',
            onPressed: _exportarHistorial,
          ),
          IconButton(
            icon: Icon(
                _mostrarFiltros ? Icons.filter_list_off : Icons.filter_list),
            tooltip: _mostrarFiltros ? 'Ocultar Filtros' : 'Mostrar Filtros',
            onPressed: () {
              setState(() {
                _mostrarFiltros = !_mostrarFiltros;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Estadísticas compactas
          _buildEstadisticasCompactas(),

          // Filtros colapsables
          if (_mostrarFiltros) _buildFiltrosCompactos(),

          // Lista de registros
          Expanded(
            child: _buildListaCompleta(),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticasCompactas() {
    return FutureBuilder<Map<String, int>>(
      future: _getEstadisticasCompletas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final stats = snapshot.data ?? {};

        return Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Estadísticas',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              // Grid 2x3 para las estadísticas
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 1.3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  _buildStatCard('Total', '${stats['total']}', Icons.list,
                      Color(0xFF2196F3)),
                  _buildStatCard('Correctivos', '${stats['correctivos']}',
                      Icons.handyman, Color(0xFFE53E3E)),
                  _buildStatCard('Rutinarios', '${stats['rutinarios']}',
                      Icons.schedule, Color(0xFF3182CE)),
                  _buildStatCard('Preventivos', '${stats['preventivos']}',
                      Icons.build_circle, Color(0xFF38A169)),
                  _buildStatCard('Reportes', '${stats['reportes']}',
                      Icons.assignment, Color(0xFF9C27B0)),
                  _buildStatCard('Completados', '${stats['completados']}',
                      Icons.check_circle, Color(0xFF009688)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: Colors.grey[600]),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosCompactos() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              TextButton.icon(
                onPressed: _limpiarFiltros,
                icon: Icon(Icons.clear, size: 16),
                label: Text('Limpiar', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size(0, 0),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          // Tipo de Actividad
          _buildDropdownField(
            label: 'Tipo de Actividad',
            value: _filtroTipo,
            items: ['Todos', 'Mantenimiento', 'Reporte'],
            onChanged: (value) => setState(() => _filtroTipo = value!),
          ),

          SizedBox(height: 8),

          // Estado
          _buildDropdownField(
            label: 'Estado',
            value: _filtroEstado,
            items: ['Todos', 'Completado'],
            onChanged: (value) => setState(() => _filtroEstado = value!),
          ),

          SizedBox(height: 8),

          // Tipo de Mantenimiento
          _buildDropdownField(
            label: 'Tipo de Mantenimiento',
            value: _filtroTipoMantenimiento,
            items: ['Todos', 'Correctivo', 'Rutinario', 'Preventivo'],
            onChanged: (value) =>
                setState(() => _filtroTipoMantenimiento = value!),
          ),

          SizedBox(height: 8),

          // Categoría de Trabajo
          _buildDropdownField(
            label: 'Categoría de Trabajo',
            value: _filtroTipoTrabajo,
            items: [
              'Todos',
              'Mecánica de Motor',
              'Sistema Eléctrico',
              'Frenos',
              'Suspensión y Dirección',
              'Transmisión',
              'Neumáticos',
              'Aire Acondicionado',
              'Carrocería',
              'Pintura',
              'Otros',
            ],
            onChanged: (value) => setState(() => _filtroTipoTrabajo = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: InputBorder.none,
              isDense: true,
            ),
            style: TextStyle(fontSize: 13, color: Colors.black87),
            items: items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
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
          padding: EdgeInsets.all(12),
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

    // Obtener mantenimientos personalizados y tradicionales
    if (widget.bus.mantenimientoPreventivo != null) {
      for (final mantenimiento
          in widget.bus.mantenimientoPreventivo!.historialMantenimientos) {
        if (_debeIncluirMantenimiento(mantenimiento)) {
          todosLosRegistros.add({
            'tipo': 'mantenimiento',
            'fecha': mantenimiento.fechaUltimoCambio,
            'descripcion': mantenimiento.descripcionTipo,
            'completada': true,
            'repuestos': mantenimiento.marcaRepuesto != null
                ? [mantenimiento.marcaRepuesto!]
                : [],
            'data': mantenimiento,
            'tecnico': mantenimiento.tecnicoResponsable,
            'observaciones': mantenimiento.observaciones,
            'kilometraje': mantenimiento.kilometrajeUltimoCambio,
            'tipoMantenimiento': mantenimiento.tipoMantenimientoEfectivo,
            'tipoTrabajo':
                'Mantenimiento ${_getLabelTipoMantenimiento(mantenimiento.tipoMantenimientoEfectivo)}',
          });
        }
      }
    }

    // Obtener reportes específicos del bus
    final reportesDelBus =
        await DataService.getReportesPorBus(widget.bus.patente);
    for (final reporte in reportesDelBus) {
      if (_debeIncluirReporte(reporte)) {
        todosLosRegistros.add({
          'tipo': 'reporte',
          'fecha': reporte.fecha,
          'descripcion':
              'Reporte ${reporte.numeroReporte} - ${reporte.tipoTrabajoDisplay}',
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
    todosLosRegistros.sort(
        (a, b) => (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime));

    return todosLosRegistros;
  }

  bool _debeIncluirMantenimiento(RegistroMantenimiento mantenimiento) {
    // Filtrar por tipo de actividad
    if (_filtroTipo != 'Todos' && _filtroTipo != 'Mantenimiento') return false;

    // Los mantenimientos siempre están completados
    if (_filtroEstado == 'En Progreso') return false;

    // Filtrar por tipo de mantenimiento
    if (_filtroTipoMantenimiento != 'Todos') {
      final tipoRequerido =
          _getTipoMantenimientoFromString(_filtroTipoMantenimiento);
      if (tipoRequerido != null &&
          mantenimiento.tipoMantenimientoEfectivo != tipoRequerido) {
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
    if (_filtroTipoTrabajo != 'Todos' &&
        _filtroTipoTrabajo != reporte.tipoTrabajoDisplay) return false;

    return true;
  }

  Widget _buildRegistroCard(Map<String, dynamic> registro) {
    final String tipo = registro['tipo'];
    final DateTime fecha = registro['fecha'];
    final String descripcion = registro['descripcion'];
    final bool completada = registro['completada'];
    final List<String> repuestos =
        List<String>.from(registro['repuestos'] ?? []);
    final String tipoTrabajo = registro['tipoTrabajo'] ?? 'Sin Categorizar';

    Color tipoColor;
    IconData tipoIcon;
    String tipoLabel;

    if (tipo == 'mantenimiento') {
      final TipoMantenimiento tipoMant =
          registro['tipoMantenimiento'] ?? TipoMantenimiento.preventivo;
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
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tipoColor.withOpacity(0.3), width: 1),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: EdgeInsets.all(12),
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
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                // Badge tipo
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tipoColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tipoLabel,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                // Badge categoría
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
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(ChileanUtils.formatDate(fecha),
                    style: TextStyle(fontSize: 11)),
                if (registro['kilometraje'] != null) ...[
                  SizedBox(width: 8),
                  Icon(Icons.speed, size: 12, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text('${registro['kilometraje'].round()} km',
                      style: TextStyle(fontSize: 11)),
                ],
              ],
            ),
          ],
        ),
        trailing: Icon(
          completada ? Icons.check_circle : Icons.schedule,
          color: completada ? Colors.green : Colors.orange,
          size: 20,
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildRegistroDetails(registro, tipo, tipoColor),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRegistroDetails(
      Map<String, dynamic> registro, String tipo, Color tipoColor) {
    List<Widget> details = [];

    // Información específica según el tipo
    if (tipo == 'mantenimiento') {
      final RegistroMantenimiento mantenimiento =
          registro['data'] as RegistroMantenimiento;

      details.add(
        _buildDetailRow(
          Icons.speed,
          'Kilometraje',
          '${mantenimiento.kilometrajeUltimoCambio.round()} km',
        ),
      );

      if (registro['tecnico'] != null) {
        details.add(SizedBox(height: 6));
        details.add(
          _buildDetailRow(
            Icons.person,
            'Técnico',
            '${registro['tecnico']}',
          ),
        );
      }

      details.add(SizedBox(height: 6));
      details.add(
        _buildDetailRow(
          _getIconTipoMantenimiento(mantenimiento.tipoMantenimientoEfectivo),
          'Tipo',
          _getLabelTipoMantenimiento(mantenimiento.tipoMantenimientoEfectivo),
          color: _getColorTipoMantenimiento(
              mantenimiento.tipoMantenimientoEfectivo),
        ),
      );
    } else if (tipo == 'reporte') {
      final ReporteDiario reporte = registro['data'] as ReporteDiario;

      details.add(
        _buildDetailRow(
          Icons.assignment,
          'Reporte N°',
          '${reporte.numeroReporte}',
        ),
      );

      details.add(SizedBox(height: 6));
      details.add(
        _buildDetailRow(
          Icons.person,
          'Autor',
          reporte.autor,
        ),
      );
    }

    // Observaciones
    if (registro['observaciones'] != null &&
        registro['observaciones'].toString().isNotEmpty) {
      details.add(SizedBox(height: 12));
      details.add(
        Text(
          tipo == 'reporte'
              ? 'Detalle del trabajo realizado:'
              : 'Observaciones:',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Colors.grey[700]),
        ),
      );
      details.add(SizedBox(height: 6));
      details.add(
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            '${registro['observaciones']}',
            style: TextStyle(fontSize: 11, color: Colors.grey[800]),
          ),
        ),
      );
    }

    // Repuestos utilizados
    final List<String> repuestos =
        List<String>.from(registro['repuestos'] ?? []);
    if (repuestos.isNotEmpty) {
      details.add(SizedBox(height: 12));
      details.add(
        Text(
          'Repuestos/Materiales utilizados:',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Colors.grey[700]),
        ),
      );
      details.add(SizedBox(height: 6));
      details.add(
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: repuestos
              .map((repuesto) => Chip(
                    label: Text(repuesto, style: TextStyle(fontSize: 10)),
                    backgroundColor: tipoColor.withOpacity(0.1),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ))
              .toList(),
        ),
      );
    }

    return details;
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey[600]),
        SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700]),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 11, color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No hay registros de actividades',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Los mantenimientos y reportes aparecerán aquí cuando se registren',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, int>> _getEstadisticasCompletas() async {
    final reportesDelBus =
        await DataService.getReportesPorBus(widget.bus.patente);
    final estadisticasMantenimiento =
        widget.bus.estadisticasMantenimientosPorTipo;

    final totalCorrectivos =
        estadisticasMantenimiento[TipoMantenimiento.correctivo] ?? 0;
    final totalRutinarios =
        estadisticasMantenimiento[TipoMantenimiento.rutinario] ?? 0;
    final totalPreventivos =
        estadisticasMantenimiento[TipoMantenimiento.preventivo] ?? 0;
    final totalReportes = reportesDelBus.length;
    final totalCompleto =
        totalCorrectivos + totalRutinarios + totalPreventivos + totalReportes;
    final completados =
        totalCorrectivos + totalRutinarios + totalPreventivos + totalReportes;

    return {
      'total': totalCompleto,
      'preventivos': totalPreventivos,
      'correctivos': totalCorrectivos,
      'rutinarios': totalRutinarios,
      'reportes': totalReportes,
      'completados': completados,
    };
  }

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

  Future<void> _exportarHistorial() async {
    final registros = await _getRegistrosCompletos();
    final estadisticas = await _getEstadisticasCompletas();
    final htmlContent = _generarHTMLHistorial(registros, estadisticas);
    _abrirVentanaImpresion(htmlContent);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.print, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('Enviando a cola de impresión'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _abrirVentanaImpresion(String htmlContent) {
    if (kIsWeb) {
      final blob = html.Blob([htmlContent], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final printWindowBase =
          html.window.open(url, 'PRINT', 'height=600,width=800');

      if (printWindowBase != null) {
        final printWindow = printWindowBase as html.Window;
        Future.delayed(Duration(milliseconds: 1000), () {
          printWindow.print();
          html.Url.revokeObjectUrl(url);
        });
      }
    }
  }

  String _generarHTMLHistorial(
      List<Map<String, dynamic>> registros, Map<String, int> estadisticas) {
    final fechaActual = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final bus = widget.bus;

    String filasHTML = '';
    for (final registro in registros) {
      final tipo = registro['tipo'];
      final fecha =
          DateFormat('dd/MM/yyyy').format(registro['fecha'] as DateTime);
      final descripcion = registro['descripcion'] ?? '';
      final tipoTrabajo = registro['tipoTrabajo'] ?? 'Sin Categorizar';
      final observaciones = registro['observaciones'] ?? 'Sin observaciones';

      String tipoLabel;
      String tipoColor;

      if (tipo == 'mantenimiento') {
        final TipoMantenimiento tipoMant =
            registro['tipoMantenimiento'] ?? TipoMantenimiento.preventivo;
        tipoLabel = _getLabelTipoMantenimiento(tipoMant);
        tipoColor = _getColorHTMLTipoMantenimiento(tipoMant);
      } else {
        tipoLabel = 'Reporte';
        final ReporteDiario reporteData = registro['data'] as ReporteDiario;
        tipoColor = _getColorHTMLFromColor(reporteData.colorTipoTrabajo);
      }

      String detallesAdicionales = '';
      if (registro['kilometraje'] != null) {
        detallesAdicionales += '${registro['kilometraje'].round()} km';
      }
      if (registro['tecnico'] != null) {
        if (detallesAdicionales.isNotEmpty) detallesAdicionales += ' | ';
        detallesAdicionales += 'Técnico: ${registro['tecnico']}';
      }
      if (registro['autor'] != null) {
        if (detallesAdicionales.isNotEmpty) detallesAdicionales += ' | ';
        detallesAdicionales += 'Autor: ${registro['autor']}';
      }

      filasHTML += '''
        <tr>
          <td>$fecha</td>
          <td><span class="badge" style="background-color: $tipoColor;">$tipoLabel</span></td>
          <td>$descripcion</td>
          <td>$tipoTrabajo</td>
          <td style="font-size: 11px;">$detallesAdicionales</td>
          <td style="font-size: 11px; max-width: 200px;">$observaciones</td>
        </tr>
      ''';
    }

    return '''
    <!DOCTYPE html>
    <html lang="es">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Historial Completo - ${bus.identificadorDisplay}</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #2C3E50; padding: 20px; background: white; }
        .container { max-width: 1200px; margin: 0 auto; background: white; }
        .header { text-align: center; padding: 20px 0; border-bottom: 3px solid #1565C0; margin-bottom: 30px; }
        .header h1 { color: #1565C0; font-size: 28px; margin-bottom: 10px; }
        .header .subtitle { color: #555; font-size: 14px; margin: 5px 0; }
        .bus-info { background: #E3F2FD; padding: 15px; border-radius: 8px; margin-bottom: 25px; border-left: 4px solid #1565C0; }
        .bus-info h2 { color: #1565C0; font-size: 18px; margin-bottom: 10px; }
        .bus-info-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; }
        .bus-info-item { padding: 8px; background: white; border-radius: 5px; }
        .info-label { font-size: 11px; color: #666; margin-bottom: 3px; font-weight: 600; text-transform: uppercase; }
        .info-value { font-size: 14px; color: #2C3E50; font-weight: bold; }
        .estadisticas { margin-bottom: 25px; padding: 15px; background: #f8f9fa; border-radius: 8px; }
        .estadisticas h2 { color: #1565C0; font-size: 18px; margin-bottom: 15px; border-bottom: 2px solid #1565C0; padding-bottom: 8px; }
        .stats-grid { display: grid; grid-template-columns: repeat(6, 1fr); gap: 10px; text-align: center; }
        .stat-item { padding: 12px; background: white; border-radius: 5px; border: 2px solid #e0e0e0; }
        .stat-value { font-size: 24px; font-weight: bold; margin-bottom: 5px; }
        .stat-label { font-size: 11px; color: #666; text-transform: uppercase; }
        .registros-section { margin-bottom: 25px; }
        .registros-section h2 { color: #1565C0; font-size: 18px; margin-bottom: 15px; border-bottom: 2px solid #1565C0; padding-bottom: 8px; }
        table { width: 100%; border-collapse: collapse; margin: 15px 0; background: white; font-size: 12px; }
        th, td { padding: 10px 8px; text-align: left; border: 1px solid #ddd; }
        th { background: #1565C0; color: white; font-weight: 600; font-size: 11px; text-transform: uppercase; }
        tr:nth-child(even) { background: #f8f9fa; }
        .badge { display: inline-block; padding: 3px 8px; border-radius: 4px; color: white; font-size: 10px; font-weight: bold; text-transform: uppercase; }
        .footer { margin-top: 40px; padding-top: 20px; border-top: 2px solid #1565C0; text-align: center; font-size: 11px; color: #666; }
        @media print {
          body { padding: 10px; }
          .container { max-width: 100%; }
          table { font-size: 10px; }
          th, td { padding: 6px 4px; }
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>📋 HISTORIAL COMPLETO</h1>
          <div class="subtitle">Buses Suray - Sistema de Gestión de Flota</div>
          <div class="subtitle">Generado: $fechaActual</div>
        </div>
        <div class="bus-info">
          <h2>🚌 Información del Bus</h2>
          <div class="bus-info-grid">
            <div class="bus-info-item"><div class="info-label">Patente</div><div class="info-value">${bus.patente}</div></div>
            <div class="bus-info-item"><div class="info-label">Identificador</div><div class="info-value">${bus.identificadorDisplay}</div></div>
            <div class="bus-info-item"><div class="info-label">Marca/Modelo</div><div class="info-value">${bus.marca} ${bus.modelo}</div></div>
            <div class="bus-info-item"><div class="info-label">Año</div><div class="info-value">${bus.anio}</div></div>
          </div>
        </div>
        <div class="estadisticas">
          <h2>📊 Estadísticas del Historial</h2>
          <div class="stats-grid">
            <div class="stat-item"><div class="stat-value" style="color: #2196F3;">${estadisticas['total']}</div><div class="stat-label">Total Registros</div></div>
            <div class="stat-item"><div class="stat-value" style="color: #E53E3E;">${estadisticas['correctivos']}</div><div class="stat-label">Correctivos</div></div>
            <div class="stat-item"><div class="stat-value" style="color: #3182CE;">${estadisticas['rutinarios']}</div><div class="stat-label">Rutinarios</div></div>
            <div class="stat-item"><div class="stat-value" style="color: #38A169;">${estadisticas['preventivos']}</div><div class="stat-label">Preventivos</div></div>
            <div class="stat-item"><div class="stat-value" style="color: #9C27B0;">${estadisticas['reportes']}</div><div class="stat-label">Reportes</div></div>
            <div class="stat-item"><div class="stat-value" style="color: #009688;">${estadisticas['completados']}</div><div class="stat-label">Completados</div></div>
          </div>
        </div>
        <div class="registros-section">
          <h2>📑 Detalle de Registros</h2>
          <table>
            <thead>
              <tr><th>Fecha</th><th>Tipo</th><th>Descripción</th><th>Categoría</th><th>Detalles</th><th>Observaciones</th></tr>
            </thead>
            <tbody>$filasHTML</tbody>
          </table>
        </div>
        <div class="footer">
          <p><strong>Sistema de Gestión de Buses Suray</strong></p>
          <p>Reporte generado automáticamente - ${bus.identificadorDisplay}</p>
          <p>Fecha de generación: $fechaActual</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  String _getColorHTMLTipoMantenimiento(TipoMantenimiento tipo) {
    switch (tipo) {
      case TipoMantenimiento.correctivo:
        return '#E53E3E';
      case TipoMantenimiento.rutinario:
        return '#3182CE';
      case TipoMantenimiento.preventivo:
        return '#38A169';
    }
  }

  String _getColorHTMLFromColor(Color color) {
    return '#${color.value.toRadixString(16).substring(2, 8)}';
  }
}
