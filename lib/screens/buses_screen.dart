import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;
import 'package:intl/intl.dart'; // ✅ PASO 1: AÑADIR IMPORTACIÓN

import '../models/bus.dart';
import '../models/mantenimiento_preventivo.dart';
import '../services/data_service.dart';
import '../services/chilean_utils.dart';

import '../widgets/bus_form_dialog.dart';
import '../widgets/historial_completo_dialog.dart';
import '../widgets/mantenimiento_preventivo_dialog.dart';
import '../widgets/asignar_repuesto_dialog.dart';


class BusesScreen extends StatefulWidget {
  @override
  _BusesScreenState createState() => _BusesScreenState();
}

class _BusesScreenState extends State<BusesScreen> with TickerProviderStateMixin {
  // --- STATE & CONTROLLERS (Sin cambios) ---
  String _filtroEstado = 'Todos';
  String _filtroTexto = '';
  String _filtroOrden = 'patente';
  String _filtroMantenimiento = 'Todos';
  bool _ordenAscendente = true;

  late TextEditingController _searchController;
  late AnimationController _filterAnimationController;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  int _currentPage = 0;
  int _itemsPerPage = 25;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filterAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterAnimationController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  // --- FETCH & FILTER BUSES (Sin cambios) ---
  Future<List<Bus>> _getBusesFiltrados() async {
    final buses = await DataService.getBuses();
    var filtered = List<Bus>.from(buses);

    // (Lógica de filtros sin cambios)
    if (_filtroEstado != 'Todos') {
      EstadoBus estado;
      switch (_filtroEstado) {
        case 'Disponible':
          estado = EstadoBus.disponible;
          break;
        case 'En Reparación':
          estado = EstadoBus.enReparacion;
          break;
        case 'Fuera de Servicio':
          estado = EstadoBus.fueraDeServicio;
          break;
        default:
          estado = EstadoBus.disponible;
      }
      filtered = filtered.where((b) => b.estado == estado).toList();
    }

    if (_filtroMantenimiento != 'Todos') {
      switch (_filtroMantenimiento) {
        case 'Mantenimiento Vencido':
          filtered = filtered.where((b) => b.tieneMantenimientosVencidos).toList();
          break;
        case 'Mantenimiento Urgente':
          filtered = filtered.where((b) => b.tieneMantenimientosUrgentes).toList();
          break;
        case 'Mantenimiento Al Día':
          filtered = filtered.where((b) =>
          !b.tieneMantenimientosVencidos && !b.tieneMantenimientosUrgentes
          ).toList();
          break;
        case 'Sin Configurar':
          filtered = filtered.where((b) => b.mantenimientoPreventivo == null).toList();
          break;
      }
    }

    if (_filtroTexto.isNotEmpty) {
      final txt = _filtroTexto.toLowerCase();
      filtered = filtered.where((b) =>
      b.patente.toLowerCase().contains(txt) ||
          b.marca.toLowerCase().contains(txt) ||
          b.modelo.toLowerCase().contains(txt) ||
          (b.identificador?.toLowerCase().contains(txt) ?? false) ||
          (b.ubicacionActual?.toLowerCase().contains(txt) ?? false)
      ).toList();
    }

    _sortBuses(filtered);
    return filtered;
  }

  void _sortBuses(List<Bus> buses) {
    buses.sort((a, b) {
      int cmp;
      switch (_filtroOrden) {
        case 'marca':
          cmp = a.marca.compareTo(b.marca);
          break;
        case 'año':
          cmp = a.anio.compareTo(b.anio);
          break;
        case 'estado':
          cmp = a.estado.toString().compareTo(b.estado.toString());
          break;
        case 'kilometraje':
          cmp = (a.kilometraje ?? 0).compareTo(b.kilometraje ?? 0);
          break;
        case 'kilometraje_ideal':
          cmp = (a.kilometrajeIdeal ?? 0).compareTo(b.kilometrajeIdeal ?? 0);
          break;
        case 'fecha_ideal':
          cmp = MantenimientoConfig.calcularFechaIdeal(a).compareTo(
              MantenimientoConfig.calcularFechaIdeal(b));
          break;
        case 'ubicacion':
          cmp = (a.ubicacionActual ?? '').compareTo(b.ubicacionActual ?? '');
          break;
        case 'patente':
        default:
          cmp = a.patente.compareTo(b.patente);
      }
      return _ordenAscendente ? cmp : -cmp;
    });
  }

  // --- UI & WIDGETS (Con cambios) ---

  // ... (build, _buildTopToolbar, _buildFilterPanel, etc. sin cambios)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTopToolbar(),
          _buildFilterPanel(),
          Expanded(
            child: FutureBuilder<List<Bus>>(
              future: _getBusesFiltrados(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final allBuses = snapshot.data ?? [];
                final total = allBuses.length;
                final totalPages = (total / _itemsPerPage).ceil();
                if (_currentPage >= totalPages && totalPages > 0) {
                  _currentPage = totalPages - 1;
                }

                final start = (_currentPage * _itemsPerPage).clamp(0, total);
                final end = ((start + _itemsPerPage)).clamp(0, total);
                final pageBuses = allBuses.sublist(start, end);

                return Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      color: Colors.blue[50],
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
                          SizedBox(width: 8),
                          Text(
                            'Tip: Usa scroll horizontal para ver todas las columnas • Configura intervalos de mantenimiento desde el engranaje superior',
                            style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: total == 0
                          ? _buildEmptyState()
                          : _buildTableView(pageBuses),
                    ),
                    _buildPagination(total),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopToolbar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTitleAndStats()),
          _buildToolbarButtons(),
        ],
      ),
    );
  }

  Widget _buildTitleAndStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestión de Flota',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800]),
        ),
        SizedBox(height: 4),
        FutureBuilder<Map<String, int>>(
          future: _getEstadisticasRapidas(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return Text('Cargando estadísticas...', style: TextStyle(color: Colors.grey[600]));
            }
            final s = snap.data!;
            return Text(
              '${s['total']} buses • ${s['disponibles']} disponibles • '
                  '${s['alertasMantenimiento']} alertas mant. • ${s['alertas']} rev. técnica',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            );
          },
        ),
      ],
    );
  }

  Widget _buildToolbarButtons() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _exportarCSV,
          icon: Icon(Icons.download, size: 16),
          label: Text('Exportar'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
        SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _importarCSV,
          icon: Icon(Icons.upload_file, size: 16),
          label: Text('Importar'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        ),
        SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _mostrarDialogoBus(context),
          icon: Icon(Icons.add, size: 16),
          label: Text('Nuevo Bus'),
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1565C0)),
        ),
        SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.settings, size: 20, color: Color(0xFF1565C0)),
          tooltip: 'Configurar intervalos de mantenimiento',
          onPressed: _showMaintenanceConfig,
        ),
        SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.fullscreen, size: 20, color: Color(0xFF1565C0)),
          tooltip: 'Pantalla completa',
          onPressed: _toggleFullScreen,
        ),
      ],
    );
  }

  void _toggleFullScreen() {
    if (html.document.fullscreenElement == null) {
      html.document.documentElement?.requestFullscreen();
    } else {
      html.document.exitFullscreen();
    }
  }

  Widget _buildFilterPanel() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: 75,
      color: Colors.grey[50],
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Búsqueda
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar buses…',
                    hintText: 'Patente, marca, modelo, identificador',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _filtroTexto.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _filtroTexto = '';
                          _currentPage = 0;
                        });
                      },
                    )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (v) => setState(() {
                    _filtroTexto = v;
                    _currentPage = 0;
                  }),
                ),
              ),
              SizedBox(width: 12),
              // Estado
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _filtroEstado,
                  decoration: InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: ['Todos', 'Disponible', 'En Reparación', 'Fuera de Servicio']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _filtroEstado = v!;
                    _currentPage = 0;
                  }),
                ),
              ),
              SizedBox(width: 12),
              // Mantenimiento
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _filtroMantenimiento,
                  decoration: InputDecoration(
                    labelText: 'Mantenimiento',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    'Todos',
                    'Mantenimiento Vencido',
                    'Mantenimiento Urgente',
                    'Mantenimiento Al Día',
                    'Sin Configurar'
                  ]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _filtroMantenimiento = v!;
                    _currentPage = 0;
                  }),
                ),
              ),
              SizedBox(width: 12),
              // Ordenar
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _filtroOrden,
                  decoration: InputDecoration(
                    labelText: 'Ordenar por',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    'patente',
                    'marca',
                    'año',
                    'estado',
                    'kilometraje',
                    'kilometraje_ideal',
                    'fecha_ideal',
                    'ubicacion'
                  ]
                      .map((k) => DropdownMenuItem(value: k, child: Text(_labelOrden(k))))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _filtroOrden = v!;
                  }),
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(
                    _ordenAscendente ? Icons.arrow_upward : Icons.arrow_downward),
                tooltip: _ordenAscendente ? 'Ascendente' : 'Descendente',
                onPressed: () =>
                    setState(() => _ordenAscendente = !_ordenAscendente),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _limpiarFiltros,
                icon: Icon(Icons.clear_all),
                label: Text('Limpiar'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _labelOrden(String key) {
    switch (key) {
      case 'patente':
        return 'Patente';
      case 'marca':
        return 'Marca';
      case 'año':
        return 'Año';
      case 'estado':
        return 'Estado';
      case 'kilometraje':
        return 'Km Actual';
      case 'kilometraje_ideal':
        return 'Km Ideal';
      case 'fecha_ideal':
        return 'Fecha Ideal';
      case 'ubicacion':
        return 'Ubicación';
      default:
        return key;
    }
  }

  Widget _buildTableView(List<Bus> buses) {
    // Definimos los anchos de columna en un solo lugar para mantener consistencia
    final columnWidths = [
      100.0, // ID
      140.0, // Patente
      120.0, // Marca
      140.0, // Modelo
      80.0,  // Año
      140.0, // Estado
      150.0, // Km Actual
      150.0, // Km Ideal
      150.0, // Fecha Ideal
      160.0, // Revisión Técnica
      200.0  // Ubicación
    ];

    // Calculamos el ancho total de la tabla dinámicamente
    final totalWidth = columnWidths.reduce((a, b) => a + b);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header con scroll horizontal
          Container(
            height: 55,
            child: Scrollbar(
              controller: _horizontalScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: totalWidth, // Usamos el ancho dinámico
                  child: _buildTableHeader(),
                ),
              ),
            ),
          ),
          // Contenido de la tabla con ambos scrolls
          Expanded(
            child: Scrollbar(
              controller: _horizontalScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: totalWidth, // Usamos el ancho dinámico
                  child: Scrollbar(
                    controller: _verticalScrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: ListView.builder(
                      controller: _verticalScrollController,
                      itemCount: buses.length,
                      itemBuilder: (_, i) => _buildTableRow(buses[i], i.isEven),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    // Los encabezados ahora incluyen "Revisión Técnica"
    final headers = <_HeaderCell>[
      _HeaderCell('ID', 100, null),
      _HeaderCell('Patente', 140, 'patente'),
      _HeaderCell('Marca', 120, 'marca'),
      _HeaderCell('Modelo', 140, null),
      _HeaderCell('Año', 80, 'año'),
      _HeaderCell('Estado', 140, 'estado'),
      _HeaderCell('Km Actual', 150, 'kilometraje'),
      _HeaderCell('Km Ideal', 150, 'kilometraje_ideal'),
      _HeaderCell('Fecha Ideal', 150, 'fecha_ideal'),
      _HeaderCell('Revisión Técnica', 160, null), // Columna añadida
      _HeaderCell('Ubicación', 200, 'ubicacion'),
    ];

    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Color(0xFF1565C0),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: headers
            .map((h) => h.build(
            context, _filtroOrden, _ordenAscendente, () => setState(() {
          if (h.sortKey != null) {
            if (_filtroOrden == h.sortKey) {
              _ordenAscendente = !_ordenAscendente;
            } else {
              _filtroOrden = h.sortKey!;
              _ordenAscendente = true;
            }
          }
        })))
            .toList(),
      ),
    );
  }

  Widget _buildTableRow(Bus bus, bool isEven) {
    final bg = isEven ? Colors.grey[50] : Colors.white;
    return InkWell(
      onTap: () => _showBusActionsDialog(bus),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            _dataCell(bus.identificador ?? '-', 100),
            _dataCell(bus.patente, 140, bold: true),
            _dataCell(bus.marca, 120),
            _dataCell(bus.modelo, 140),
            _dataCell('${bus.anio}', 80),
            _estadoCell(bus, 140),
            _kilometrajeCell(bus.kilometraje, 150),
            _kilometrajeIdealCell(bus, 150),
            _fechaIdealCell(bus, 150),
            _revisionTecnicaCell(bus, 160), // Celda añadida
            _dataCell(bus.ubicacionActual ?? '-', 200),
          ],
        ),
      ),
    );
  }

  void _showBusActionsDialog(Bus bus) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Acciones para ${bus.patente}'),
        children: [
          SimpleDialogOption(
            child: Text('Asignar Repuesto'),
            onPressed: () {
              Navigator.pop(ctx);
              _asignarRepuesto(context, bus);
            },
          ),
          SimpleDialogOption(
            child: Text('Historial Completo'),
            onPressed: () {
              Navigator.pop(ctx);
              _mostrarHistorialCompleto(context, bus);
            },
          ),
          SimpleDialogOption(
            child: Text('Registrar Mantenimiento'),
            onPressed: () {
              Navigator.pop(ctx);
              _registrarMantenimiento(context, bus);
            },
          ),
          SimpleDialogOption(
            child: Text('Editar Bus'),
            onPressed: () {
              Navigator.pop(ctx);
              _mostrarDialogoBus(context, bus: bus);
            },
          ),
          SimpleDialogOption(
            child: Text('Eliminar Bus', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(ctx);
              _eliminarBus(bus.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _dataCell(String text, double width, {bool bold = false}) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _estadoCell(Bus bus, double width) {
    Color c;
    IconData ic;
    String lbl;
    switch (bus.estado) {
      case EstadoBus.disponible:
        c = Colors.green;
        ic = Icons.check_circle;
        lbl = 'Disponible';
        break;
      case EstadoBus.enReparacion:
        c = Colors.orange;
        ic = Icons.build;
        lbl = 'En Reparación';
        break;
      default:
        c = Colors.red;
        ic = Icons.cancel;
        lbl = 'Fuera de Servicio';
    }
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(ic, size: 16, color: c),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              lbl,
              style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _revisionTecnicaCell(Bus bus, double width) {
    // Si no hay fecha, muestra un texto indicativo
    if (bus.fechaRevisionTecnica == null) {
      return _dataCell('No registrada', width);
    }

    // Determina el color basado en el estado de la revisión técnica
    Color textColor = Colors.green;
    if (bus.revisionTecnicaVencida) {
      textColor = Colors.red;
    } else if (bus.revisionTecnicaProximaAVencer) {
      textColor = Colors.orange;
    }

    // Retorna el widget con el estilo y color apropiados
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: Text(
        ChileanUtils.formatDate(bus.fechaRevisionTecnica!), // Usa la utilidad para formatear la fecha
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  // ✅ PASO 2: MODIFICAR CELDAS DE KILOMETRAJE
  Widget _kilometrajeCell(double? kilometraje, double width) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: Text(
        kilometraje != null
            ? _formatKilometraje(kilometraje) // Se quita el sufijo " km"
            : 'No registrado',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: kilometraje != null ? Colors.black : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _kilometrajeIdealCell(Bus bus, double width) {
    final kmIdeal = bus.kilometrajeIdeal ?? 0;
    final kmActual = bus.kilometraje ?? 0;
    final diferencia = kmIdeal - kmActual;

    Color textColor = Colors.green;
    if (kmActual > kmIdeal) {
      textColor = Colors.red;
    } else if (diferencia < (MantenimientoConfig.kilometrajeIdeal * 0.2)) {
      textColor = Colors.orange;
    }

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: Text(
        kmIdeal > 0 ? _formatKilometraje(kmIdeal) : 'No configurado', // Se quita el sufijo " km"
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _fechaIdealCell(Bus bus, double width) {
    final fechaIdeal = MantenimientoConfig.calcularFechaIdeal(bus);
    final diasHastaFecha = fechaIdeal.difference(DateTime.now()).inDays;

    Color textColor = Colors.green;
    if (diasHastaFecha < 7) {
      textColor = Colors.orange;
    } else if (diasHastaFecha < 0) {
      textColor = Colors.red;
    }

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: Text(
        ChileanUtils.formatDate(fechaIdeal),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  // ✅ PASO 3: ACTUALIZAR EL MÉTODO DE FORMATO
  String _formatKilometraje(double km) {
    // Se usa NumberFormat para obtener el formato "000.000"
    final formatador = NumberFormat("#,##0", "es_CL");
    return formatador.format(km);
  }

  // --- El resto de los métodos (sin cambios) ---

  void _showMaintenanceConfig() {
    showDialog(
      context: context,
      builder: (context) => _MaintenanceConfigDialog(
        onConfigChanged: () => setState(() {}),
      ),
    );
  }

  void _mostrarDialogoBus(BuildContext context, {Bus? bus}) {
    showDialog<Bus>(
      context: context,
      builder: (_) => BusFormDialog(bus: bus),
    ).then((result) async {
      if (result == null) return;
      try {
        if (bus == null) {
          await DataService.addBus(result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bus creado'), backgroundColor: Colors.green),
          );
        } else {
          await DataService.updateBus(result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bus actualizado'), backgroundColor: Colors.green),
          );
        }
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    });
  }

  void _registrarMantenimiento(BuildContext context, Bus bus) {
    showDialog(
      context: context,
      builder: (_) => MantenimientoPreventivoDialog(
        bus: bus,
        onMantenimientoRegistrado: () => setState(() {}),
      ),
    );
  }

  void _asignarRepuesto(BuildContext context, Bus bus) {
    showDialog(
      context: context,
      builder: (_) => AsignarRepuestoDialog(
        bus: bus,
        onRepuestoAsignado: () => setState(() {}),
      ),
    );
  }

  void _mostrarHistorialCompleto(BuildContext context, Bus bus) {
    showDialog(
      context: context,
      builder: (_) => HistorialCompletoDialog(bus: bus),
    );
  }

  Future<void> _eliminarBus(String id) async {
    final bus = await DataService.getBusById(id);
    if (bus == null) return;
    final conf = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text('Eliminar bus ${bus.patente}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, false), child: Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(_, true),
            child: Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (conf == true) {
      try {
        await DataService.deleteBus(id);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bus eliminado'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportarCSV() async {
    try {
      final csv = await DataService.exportBusesToCSV();
      final blob = html.Blob([csv]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'buses_${DateTime.now().toIso8601String().substring(0,10)}.csv';
      html.document.body!.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV exportado'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exportando: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _importarCSV() {
    final upload = html.FileUploadInputElement()..accept = '.csv';
    upload.click();
    upload.onChange.listen((_) {
      final file = upload.files?.first;
      if (file == null) return;
      final reader = html.FileReader();
      reader.readAsText(file);
      reader.onLoad.listen((_) async {
        try {
          await DataService.importBusesFromCSV(reader.result as String);
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('CSV importado'), backgroundColor: Colors.green),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error importando: $e'), backgroundColor: Colors.red),
          );
        }
      });
    });
  }

  Future<Map<String, int>> _getEstadisticasRapidas() async {
    final buses = await DataService.getBuses();
    return {
      'total': buses.length,
      'disponibles': buses.where((b) => b.estado == EstadoBus.disponible).length,
      'enReparacion': buses.where((b) => b.estado == EstadoBus.enReparacion).length,
      'alertasMantenimiento': buses.where((b) =>
      b.tieneMantenimientosVencidos || b.tieneMantenimientosUrgentes).length,
      'alertas': buses.where((b) =>
      b.revisionTecnicaVencida || b.revisionTecnicaProximaAVencer).length,
    };
  }

  Widget _buildPagination(int totalItems) {
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (totalPages <= 1) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Text('Página ${_currentPage+1} de $totalPages'),
          Spacer(),
          IconButton(
            icon: Icon(Icons.first_page),
            onPressed: _currentPage > 0 ? () => setState(() => _currentPage = 0) : null,
          ),
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
          ),
          ...List.generate(
            totalPages > 10 ? 10 : totalPages,
                (i) {
              final pageIndex = totalPages > 10
                  ? (_currentPage > 5 ? _currentPage - 5 + i : i)
                  : i;
              if (pageIndex >= totalPages) return SizedBox.shrink();

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentPage == pageIndex ? Color(0xFF1565C0) : Colors.grey[200],
                    minimumSize: Size(36,36),
                  ),
                  onPressed: () => setState(() => _currentPage = pageIndex),
                  child: Text('${pageIndex+1}',
                      style: TextStyle(
                          color: _currentPage == pageIndex ? Colors.white : Colors.black)),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages-1
                ? () => setState(() => _currentPage++)
                : null,
          ),
          IconButton(
            icon: Icon(Icons.last_page),
            onPressed: _currentPage < totalPages-1
                ? () => setState(() => _currentPage = totalPages-1)
                : null,
          ),
        ],
      ),
    );
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroEstado = 'Todos';
      _filtroMantenimiento = 'Todos';
      _filtroTexto = '';
      _filtroOrden = 'patente';
      _ordenAscendente = true;
      _currentPage = 0;
      _searchController.clear();
    });
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF1565C0)),
          SizedBox(height: 16),
          Text('Cargando buses...', style: TextStyle(color: Colors.grey[600])),
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
          Text('Error al cargar buses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: Icon(Icons.refresh),
            label: Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            (_filtroTexto.isNotEmpty ||
                _filtroEstado != 'Todos' ||
                _filtroMantenimiento != 'Todos')
                ? 'No hay buses con esos filtros'
                : 'No hay buses registrados',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogoBus(context),
            icon: Icon(Icons.add),
            label: Text('Agregar Bus'),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1565C0)),
          ),
        ],
      ),
    );
  }
}

// Clase auxiliar para construir encabezados ordenables (sin cambios)
class _HeaderCell {
  final String title;
  final double width;
  final String? sortKey;
  _HeaderCell(this.title, this.width, this.sortKey);

  Widget build(BuildContext context, String currentSort, bool asc, VoidCallback onTap) {
    final active = sortKey != null && currentSort == sortKey;
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.white24, width: 0.5)),
      ),
      child: InkWell(
        onTap: sortKey == null ? null : onTap,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (sortKey != null)
              Icon(
                active ? (asc ? Icons.arrow_upward : Icons.arrow_downward) : Icons.sort,
                size: 16,
                color: active ? Colors.white : Colors.white70,
              ),
          ],
        ),
      ),
    );
  }
}

// Dialog para configurar los intervalos de mantenimiento (sin cambios)
class _MaintenanceConfigDialog extends StatefulWidget {
  final VoidCallback onConfigChanged;

  _MaintenanceConfigDialog({required this.onConfigChanged});

  @override
  _MaintenanceConfigDialogState createState() => _MaintenanceConfigDialogState();
}

class _MaintenanceConfigDialogState extends State<_MaintenanceConfigDialog> {
  late TextEditingController _kmController;
  late TextEditingController _diasController;

  @override
  void initState() {
    super.initState();
    _kmController = TextEditingController(text: MantenimientoConfig.kilometrajeIdeal.toString());
    _diasController = TextEditingController(text: MantenimientoConfig.diasFechaIdeal.toString());
  }

  @override
  void dispose() {
    _kmController.dispose();
    _diasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.settings, color: Color(0xFF1565C0)),
          SizedBox(width: 8),
          Text('Configuración de Mantenimiento'),
        ],
      ),
      content: Container(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Intervalos de Mantenimiento',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Configura los intervalos para calcular el kilometraje ideal y la fecha ideal de mantenimiento.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _kmController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Kilometraje ideal para mantenimiento',
                suffixText: 'km',
                prefixIcon: Icon(Icons.speed),
                border: OutlineInputBorder(),
                helperText: 'Intervalo en kilómetros entre mantenimientos',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _diasController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Días ideales para mantenimiento',
                suffixText: 'días',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
                helperText: 'Intervalo en días entre mantenimientos',
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Los cambios se aplicarán inmediatamente a todos los buses en la tabla.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveConfig,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1565C0),
            foregroundColor: Colors.white,
          ),
          child: Text('Guardar'),
        ),
      ],
    );
  }

  void _saveConfig() {
    final km = int.tryParse(_kmController.text);
    final dias = int.tryParse(_diasController.text);

    if (km == null || km <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El kilometraje debe ser un número positivo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (dias == null || dias <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Los días deben ser un número positivo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    MantenimientoConfig.kilometrajeIdeal = km;
    MantenimientoConfig.diasFechaIdeal = dias;

    widget.onConfigChanged();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Configuración guardada exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  }
}