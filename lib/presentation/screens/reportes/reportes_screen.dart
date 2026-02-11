import 'package:flutter/material.dart';
import '../../widgets/responsive/responsive_builder.dart';
import '../../../models/bus.dart';
import '../../../models/reporte_diario.dart';
import '../../../models/mantenimiento_preventivo.dart';
import '../../../screens/reporte_editor_screen.dart';
import '../../../services/data_service.dart';
import '../../../widgets/editar_mantenimiento_dialog.dart';
import 'layouts/reportes_desktop_layout.dart';
import 'layouts/reportes_mobile_layout.dart';

// =====================================================================
// === REPORTES SCREEN - Punto de entrada responsive ===================
// =====================================================================
// Maneja estado, carga de datos, filtros y acciones CRUD.
// Delega renderizado al layout correspondiente (mobile/desktop).

class HistorialGlobalScreen extends StatefulWidget {
  @override
  _HistorialGlobalScreenState createState() => _HistorialGlobalScreenState();
}

class _HistorialGlobalScreenState extends State<HistorialGlobalScreen> {
  // --- FILTROS ---
  String? _filtroBusId;
  DateTimeRange? _filtroFecha;

  // --- DATOS CACHEADOS ---
  List<Map<String, dynamic>> _todasActividades = [];
  List<Map<String, dynamic>> _actividadesFiltradas = [];
  List<Map<String, String>> _busesDisponibles = []; // [{id, display}]
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // --- CARGA DE DATOS ---
  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final todosLosBuses = await DataService.getBuses();
      final todosLosReportes = await DataService.getReportes();

      // Cachear lista de buses para filtros
      _busesDisponibles = todosLosBuses
          .map((b) => {'id': b.id, 'display': b.identificadorDisplay})
          .toList()
        ..sort((a, b) => a['display']!.compareTo(b['display']!));

      // Construir lista completa de actividades
      List<Map<String, dynamic>> registros = [];

      for (final bus in todosLosBuses) {
        if (bus.mantenimientoPreventivo != null) {
          for (final mantenimiento
              in bus.mantenimientoPreventivo!.historialMantenimientos) {
            registros.add({
              'tipo': 'mantenimiento',
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
      }

      for (final reporte in todosLosReportes) {
        registros.add({
          'tipo': 'reporte',
          'fecha': reporte.fecha,
          'descripcion':
              'Reporte ${reporte.numeroReporte} - ${reporte.tipoTrabajoDisplay}',
          'data': reporte,
          'autor': reporte.autor,
          'observaciones': reporte.observaciones,
          'busesReporte': reporte.busesAtendidos,
        });
      }

      // Ordenar por fecha descendente
      registros
          .sort((a, b) => (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime));

      setState(() {
        _todasActividades = registros;
        _isLoading = false;
      });

      _aplicarFiltros(todosLosBuses);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // --- APLICAR FILTROS SINCRONAMENTE ---
  void _aplicarFiltros([List<Bus>? busesOverride]) {
    var resultado = List<Map<String, dynamic>>.from(_todasActividades);

    // Filtro por bus
    if (_filtroBusId != null) {
      resultado = resultado.where((registro) {
        if (registro['tipo'] == 'reporte') {
          // Para reportes, buscar si el bus está en busesAtendidos por patente
          final busSeleccionado = _busesDisponibles.firstWhere(
            (b) => b['id'] == _filtroBusId,
            orElse: () => {'id': '', 'display': ''},
          );
          // Necesitamos la patente — buscar en buses cacheados o desde display
          // En reportes, busesAtendidos contiene patentes
          final buses = registro['busesReporte'] as List? ?? [];
          // El display puede contener la patente, pero intentemos
          // con la referencia a los buses originales
          return buses.any((p) =>
              busSeleccionado['display']?.contains(p.toString()) == true ||
              p.toString().contains(busSeleccionado['display'] ?? ''));
        } else {
          return registro['busId'] == _filtroBusId;
        }
      }).toList();
    }

    // Filtro por fecha
    if (_filtroFecha != null) {
      final start = _filtroFecha!.start;
      final end = DateTime(
          _filtroFecha!.end.year, _filtroFecha!.end.month, _filtroFecha!.end.day, 23, 59);
      resultado = resultado.where((registro) {
        final fecha = registro['fecha'] as DateTime;
        return !fecha.isBefore(start) && !fecha.isAfter(end);
      }).toList();
    }

    setState(() {
      _actividadesFiltradas = resultado;
    });
  }

  // --- ACCIONES ---
  Future<void> _seleccionarFecha() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _filtroFecha,
    );
    if (picked != null) {
      setState(() => _filtroFecha = picked);
      _aplicarFiltros();
    }
  }

  void _editarActividad(Map<String, dynamic> registro) async {
    final tipo = registro['tipo'];

    if (tipo == 'reporte') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ReporteEditorScreen(reporteBase: registro['data'] as ReporteDiario),
        ),
      ).then((_) => _cargarDatos());
    } else if (tipo == 'mantenimiento') {
      final bus = await DataService.getBusById(registro['busId']);
      if (bus != null && mounted) {
        showDialog(
          context: context,
          builder: (context) => EditarMantenimientoDialog(
            bus: bus,
            registroParaEditar: registro['data'] as RegistroMantenimiento,
            onMantenimientoGuardado: _cargarDatos,
          ),
        );
      }
    }
  }

  void _eliminarActividad(Map<String, dynamic> registro) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
            '¿Estás seguro de que quieres eliminar este registro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      if (registro['tipo'] == 'reporte') {
        final reporte = registro['data'] as ReporteDiario;
        await DataService.deleteReporte(reporte.id);
      } else if (registro['tipo'] == 'mantenimiento') {
        final mant = registro['data'] as RegistroMantenimiento;
        await DataService.deleteMantenimientoFromBus(
            registro['busId'], mant.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Registro eliminado exitosamente'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red),
        );
      }
    }

    _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text('Error al cargar: $_error',
                style: TextStyle(color: Colors.red[700])),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _cargarDatos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return ResponsiveBuilder(
      mobile: (context) => ReportesMobileLayout(
        actividades: _actividadesFiltradas,
        filtroBusId: _filtroBusId,
        filtroFecha: _filtroFecha,
        buses: _busesDisponibles,
        onBusChanged: (value) {
          setState(() => _filtroBusId = value);
          _aplicarFiltros();
        },
        onFechaPressed: _seleccionarFecha,
        onClearBus: () {
          setState(() => _filtroBusId = null);
          _aplicarFiltros();
        },
        onClearFecha: () {
          setState(() => _filtroFecha = null);
          _aplicarFiltros();
        },
        onEditar: _editarActividad,
        onEliminar: _eliminarActividad,
        onRefresh: _cargarDatos,
        isLoading: _isLoading,
      ),
      desktop: (context) => ReportesDesktopLayout(
        actividades: _actividadesFiltradas,
        filtroBusId: _filtroBusId,
        filtroFecha: _filtroFecha,
        buses: _busesDisponibles,
        onBusChanged: (value) {
          setState(() => _filtroBusId = value);
          _aplicarFiltros();
        },
        onFechaPressed: _seleccionarFecha,
        onClearBus: () {
          setState(() => _filtroBusId = null);
          _aplicarFiltros();
        },
        onClearFecha: () {
          setState(() => _filtroFecha = null);
          _aplicarFiltros();
        },
        onEditar: _editarActividad,
        onEliminar: _eliminarActividad,
        isLoading: _isLoading,
      ),
    );
  }
}
