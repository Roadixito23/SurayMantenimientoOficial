import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;
import 'package:intl/intl.dart';

import '../models/bus.dart';
import '../models/mantenimiento_preventivo.dart';
import '../services/data_service.dart';
import '../services/chilean_utils.dart';
import '../main.dart'; // Import para colores Suray

import '../widgets/bus_form_dialog.dart';
import '../widgets/historial_completo_dialog.dart';
import '../widgets/mantenimiento_preventivo_dialog.dart';
import '../widgets/asignar_repuesto_dialog.dart';
import '../widgets/actualizar_kilometraje_dialog.dart';

class BusesScreen extends StatefulWidget {
  @override
  _BusesScreenState createState() => _BusesScreenState();
}

class _BusesScreenState extends State<BusesScreen> with TickerProviderStateMixin {
  // --- STATE & CONTROLLERS ---
  String _filtroEstado = 'Todos';
  String _filtroTexto = '';
  String _filtroOrden = 'patente';
  String _filtroMantenimiento = 'Todos';
  bool _ordenAscendente = true;

  late TextEditingController _searchController;
  late AnimationController _filterAnimationController;
  late AnimationController _fadeAnimationController;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  int _currentPage = 0;
  int _itemsPerPage = 25;

  // Cache para los buses para evitar rebuilds innecesarios
  List<Bus>? _cachedBuses;
  Future<List<Bus>>? _busesFuture;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filterAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterAnimationController.dispose();
    _fadeAnimationController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  // --- FETCH & FILTER BUSES ---
  Future<List<Bus>> _getBusesFiltrados() async {
    // Solo obtener buses del servidor si el cache está vacío
    if (_cachedBuses == null) {
      _cachedBuses = await DataService.getBuses();
    }

    var filtered = List<Bus>.from(_cachedBuses!);

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

  void _refreshBuses() {
    setState(() {
      _cachedBuses = null;
      _busesFuture = null;
    });
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

  // --- UI & WIDGETS ---

  @override
  Widget build(BuildContext context) {
    // Cachear el Future para evitar recrearlo en cada rebuild
    _busesFuture ??= _getBusesFiltrados();

    return Scaffold(
      backgroundColor: SurayColors.blancoHumo,
      body: Column(
        children: [
          _buildFilterPanel(),
          Expanded(
            child: FutureBuilder<List<Bus>>(
              future: _busesFuture,
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

                return FadeTransition(
                  opacity: _fadeAnimationController,
                  child: Column(
                    children: [
                      Expanded(
                        child: total == 0
                            ? _buildEmptyState()
                            : _buildTableView(pageBuses),
                      ),
                      if (total > 0) _buildPagination(total),
                    ],
                  ),
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
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SurayColors.azulMarinoProfundo,
            SurayColors.azulMarinoClaro,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: SurayColors.azulMarinoProfundo.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildTitleAndStats()),
          SizedBox(width: 16),
          _buildToolbarButtons(),
        ],
      ),
    );
  }

  Widget _buildTitleAndStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SurayColors.naranjaQuemado,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: SurayColors.naranjaQuemado.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.directions_bus,
                color: SurayColors.blancoHumo,
                size: 28,
              ),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de Flota',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: SurayColors.blancoHumo,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                FutureBuilder<Map<String, int>>(
                  future: _getEstadisticasRapidas(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return Text(
                        'Cargando estadísticas...',
                        style: TextStyle(
                          color: SurayColors.blancoHumo.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      );
                    }
                    final s = snap.data!;
                    return Wrap(
                      spacing: 16,
                      children: [
                        _buildStatChip('${s['total']} buses', Icons.directions_bus),
                        _buildStatChip('${s['disponibles']} disponibles', Icons.check_circle),
                        _buildStatChip('${s['alertasMantenimiento']} alertas mant.', Icons.warning),
                        _buildStatChip('${s['alertas']} rev. técnica', Icons.assignment_late),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: SurayColors.blancoHumo.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SurayColors.blancoHumo.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: SurayColors.blancoHumo),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: SurayColors.blancoHumo,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButtons() {
    return Row(
      children: [
        _buildModernButton(
          onPressed: () => _mostrarDialogoBus(context),
          icon: Icons.add_circle,
          label: 'Nuevo Bus',
          color: SurayColors.naranjaQuemado,
        ),
        SizedBox(width: 12),
        _buildIconButton(
          icon: Icons.settings,
          tooltip: 'Configurar intervalos',
          onPressed: _showMaintenanceConfig,
        ),
        SizedBox(width: 8),
        _buildIconButton(
          icon: Icons.fullscreen,
          tooltip: 'Pantalla completa',
          onPressed: _toggleFullScreen,
        ),
      ],
    );
  }

  Widget _buildModernButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: SurayColors.blancoHumo,
        elevation: 4,
        shadowColor: color.withOpacity(0.4),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: SurayColors.blancoHumo.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SurayColors.blancoHumo.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: SurayColors.blancoHumo),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
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
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SurayColors.azulMarinoProfundo,
            SurayColors.azulMarinoClaro,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: SurayColors.azulMarinoProfundo.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con título y botón Nuevo Bus
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SurayColors.naranjaQuemado,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: SurayColors.naranjaQuemado.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: SurayColors.blancoHumo,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestión de Flota',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: SurayColors.blancoHumo,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    FutureBuilder<Map<String, int>>(
                      future: _getEstadisticasRapidas(),
                      builder: (context, snap) {
                        if (!snap.hasData) return SizedBox.shrink();
                        final s = snap.data!;
                        return Wrap(
                          spacing: 16,
                          children: [
                            _buildStatChip('${s['total']} buses', Icons.directions_bus),
                            _buildStatChip('${s['disponibles']} disponibles', Icons.check_circle),
                            _buildStatChip('${s['alertasMantenimiento']} alertas mant.', Icons.warning),
                            _buildStatChip('${s['alertas']} rev. técnica', Icons.assignment_late),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              _buildModernButton(
                onPressed: () => _mostrarDialogoBus(context),
                icon: Icons.add_circle,
                label: 'Nuevo Bus',
                color: SurayColors.naranjaQuemado,
              ),
            ],
          ),
          SizedBox(height: 20),
          // Filtros en una segunda fila
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SurayColors.blancoHumo.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Búsqueda
                Expanded(
                  flex: 2,
                  child: _buildSearchField(),
                ),
                SizedBox(width: 12),
                // Estado
                Expanded(
                  flex: 1,
                  child: _buildDropdownFilter(
                    value: _filtroEstado,
                    label: 'Estado',
                    items: ['Todos', 'Disponible', 'En Reparación', 'Fuera de Servicio'],
                    onChanged: (v) {
                      setState(() {
                        _filtroEstado = v!;
                        _currentPage = 0;
                        _busesFuture = null;
                      });
                    },
                  ),
                ),
                SizedBox(width: 12),
                // Mantenimiento
                Expanded(
                  flex: 1,
                  child: _buildDropdownFilter(
                    value: _filtroMantenimiento,
                    label: 'Mantenimiento',
                    items: [
                      'Todos',
                      'Mantenimiento Vencido',
                      'Mantenimiento Urgente',
                      'Mantenimiento Al Día',
                      'Sin Configurar'
                    ],
                    onChanged: (v) {
                      setState(() {
                        _filtroMantenimiento = v!;
                        _currentPage = 0;
                        _busesFuture = null;
                      });
                    },
                  ),
                ),
                SizedBox(width: 12),
                // Ordenar
                Expanded(
                  flex: 1,
                  child: _buildDropdownFilter(
                    value: _filtroOrden,
                    label: 'Ordenar por',
                    items: [
                      'patente',
                      'marca',
                      'año',
                      'estado',
                      'kilometraje',
                      'kilometraje_ideal',
                      'fecha_ideal',
                      'ubicacion'
                    ],
                    displayMapper: _labelOrden,
                    onChanged: (v) {
                      setState(() {
                        _filtroOrden = v!;
                        _busesFuture = null;
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                _buildFilterIconButton(
                  icon: _ordenAscendente ? Icons.arrow_upward : Icons.arrow_downward,
                  tooltip: _ordenAscendente ? 'Ascendente' : 'Descendente',
                  onPressed: () {
                    setState(() {
                      _ordenAscendente = !_ordenAscendente;
                      _busesFuture = null;
                    });
                  },
                ),
                SizedBox(width: 8),
                _buildClearButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: TextStyle(color: SurayColors.azulMarinoProfundo),
      decoration: InputDecoration(
        labelText: 'Buscar buses',
        labelStyle: TextStyle(color: SurayColors.blancoHumo.withOpacity(0.9)),
        hintText: 'Patente, marca, modelo...',
        hintStyle: TextStyle(color: SurayColors.blancoHumo.withOpacity(0.6)),
        prefixIcon: Icon(Icons.search, color: SurayColors.blancoHumo.withOpacity(0.9)),
        suffixIcon: _filtroTexto.isNotEmpty
            ? IconButton(
          icon: Icon(Icons.clear, color: SurayColors.blancoHumo.withOpacity(0.9)),
          onPressed: () {
            _searchController.clear();
            setState(() {
              _filtroTexto = '';
              _currentPage = 0;
              _busesFuture = null;
            });
          },
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: SurayColors.naranjaQuemado, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
      ),
      onChanged: (v) {
        setState(() {
          _filtroTexto = v;
          _currentPage = 0;
          _busesFuture = null;
        });
      },
    );
  }

  Widget _buildDropdownFilter({
    required String value,
    required String label,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String Function(String)? displayMapper,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: SurayColors.blancoHumo,
      ),
      items: items
          .map((e) => DropdownMenuItem(
        value: e,
        child: Text(displayMapper != null ? displayMapper(e) : e),
      ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildFilterIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: SurayColors.azulMarinoProfundo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SurayColors.azulMarinoProfundo.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: SurayColors.azulMarinoProfundo),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildClearButton() {
    return ElevatedButton.icon(
      onPressed: _limpiarFiltros,
      icon: Icon(Icons.clear_all, size: 18),
      label: Text('Limpiar'),
      style: ElevatedButton.styleFrom(
        backgroundColor: SurayColors.grisAntracita,
        foregroundColor: SurayColors.blancoHumo,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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

  Widget _buildInfoTip() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SurayColors.azulMarinoProfundo.withOpacity(0.1),
            SurayColors.naranjaQuemado.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SurayColors.azulMarinoProfundo.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: SurayColors.azulMarinoProfundo,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Usa scroll horizontal/touchpad para ver todas las columnas • Haz clic en una fila para ver acciones',
              style: TextStyle(
                fontSize: 13,
                color: SurayColors.azulMarinoProfundo,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView(List<Bus> buses) {
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

    final totalWidth = columnWidths.reduce((a, b) => a + b);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: SurayColors.azulMarinoProfundo.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con scroll horizontal
          Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: ScrollbarTheme(
              data: ScrollbarThemeData(
                thumbVisibility: MaterialStateProperty.all(true),
                trackVisibility: MaterialStateProperty.all(true),
                thickness: MaterialStateProperty.all(16),
                thumbColor: MaterialStateProperty.all(SurayColors.naranjaQuemado.withOpacity(0.8)),
                trackColor: MaterialStateProperty.all(SurayColors.grisAntracita.withOpacity(0.15)),
                trackBorderColor: MaterialStateProperty.all(SurayColors.grisAntracita.withOpacity(0.25)),
                radius: Radius.circular(10),
              ),
              child: Scrollbar(
                controller: _horizontalScrollController,
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: totalWidth,
                    child: _buildTableHeader(),
                  ),
                ),
              ),
            ),
          ),
          // Contenido de la tabla
          Expanded(
            child: ScrollbarTheme(
              data: ScrollbarThemeData(
                thumbVisibility: MaterialStateProperty.all(true),
                trackVisibility: MaterialStateProperty.all(true),
                thickness: MaterialStateProperty.all(16),
                thumbColor: MaterialStateProperty.all(SurayColors.naranjaQuemado.withOpacity(0.8)),
                trackColor: MaterialStateProperty.all(SurayColors.grisAntracita.withOpacity(0.15)),
                trackBorderColor: MaterialStateProperty.all(SurayColors.grisAntracita.withOpacity(0.25)),
                radius: Radius.circular(10),
                interactive: true,
              ),
              child: Scrollbar(
                controller: _horizontalScrollController,
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: totalWidth,
                    child: Scrollbar(
                      controller: _verticalScrollController,
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
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
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
      _HeaderCell('Revisión Técnica', 160, null),
      _HeaderCell('Ubicación', 200, 'ubicacion'),
    ];

    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SurayColors.azulMarinoProfundo,
            SurayColors.azulMarinoClaro,
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
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
    return _BusTableRow(
      bus: bus,
      isEven: isEven,
      onTap: () => _showBusActionsDialog(bus),
    );
  }

  void _showBusActionsDialog(Bus bus) {
    showDialog(
      context: context,
      barrierColor: SurayColors.azulMarinoProfundo.withOpacity(0.5),
      builder: (ctx) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        SurayColors.azulMarinoProfundo,
                        SurayColors.azulMarinoClaro,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.directions_bus, color: SurayColors.blancoHumo),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Acciones para ${bus.patente}',
                          style: TextStyle(
                            color: SurayColors.blancoHumo,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Acciones principales
                    _buildActionOption(
                      icon: Icons.speed,
                      label: 'Actualizar Kilometraje',
                      color: SurayColors.azulMarinoProfundo,
                      onTap: () {
                        Navigator.pop(ctx);
                        _actualizarKilometraje(context, bus);
                      },
                    ),
                    SizedBox(height: 8),
                    _buildActionOption(
                      icon: Icons.assignment,
                      label: 'Registrar Mantenimiento',
                      color: SurayColors.naranjaQuemado,
                      onTap: () {
                        Navigator.pop(ctx);
                        _registrarMantenimiento(context, bus);
                      },
                    ),
                    SizedBox(height: 8),
                    _buildActionOption(
                      icon: Icons.build_circle,
                      label: 'Asignar Repuesto',
                      color: SurayColors.azulMarinoClaro,
                      onTap: () {
                        Navigator.pop(ctx);
                        _asignarRepuesto(context, bus);
                      },
                    ),
                    SizedBox(height: 8),
                    _buildActionOption(
                      icon: Icons.history,
                      label: 'Historial Completo',
                      color: Color(0xFF607D8B),
                      onTap: () {
                        Navigator.pop(ctx);
                        _mostrarHistorialCompleto(context, bus);
                      },
                    ),

                    // Divisor para acciones secundarias
                    SizedBox(height: 12),
                    Divider(color: SurayColors.grisAntracitaClaro.withOpacity(0.3)),
                    SizedBox(height: 4),

                    // Acciones secundarias (menos frecuentes)
                    _buildActionOption(
                      icon: Icons.edit,
                      label: 'Editar Bus',
                      color: SurayColors.grisAntracita,
                      iconSize: 16,
                      isSecondary: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        _mostrarDialogoBus(context, bus: bus);
                      },
                    ),
                    SizedBox(height: 6),
                    _buildActionOption(
                      icon: Icons.delete_forever,
                      label: 'Eliminar Bus',
                      color: Colors.red,
                      iconSize: 16,
                      isSecondary: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        _eliminarBus(bus.id);
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cerrar'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    double iconSize = 20,
    bool isSecondary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isSecondary ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSecondary ? 6 : 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: iconSize),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isSecondary ? 13 : 15,
                  fontWeight: isSecondary ? FontWeight.w400 : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color.withOpacity(0.5),
              size: isSecondary ? 18 : 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dataCell(String text, double width, {bool bold = false}) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: SurayColors.grisAntracita.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: bold ? SurayColors.azulMarinoProfundo : SurayColors.grisAntracita,
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
        c = SurayColors.naranjaQuemado;
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
        border: Border(
          right: BorderSide(
            color: SurayColors.grisAntracita.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ic, size: 14, color: c),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                lbl,
                style: TextStyle(
                  fontSize: 12,
                  color: c,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _revisionTecnicaCell(Bus bus, double width) {
    if (bus.fechaRevisionTecnica == null) {
      return _dataCell('No registrada', width);
    }

    Color textColor = Colors.green;
    if (bus.revisionTecnicaVencida) {
      textColor = Colors.red;
    } else if (bus.revisionTecnicaProximaAVencer) {
      textColor = SurayColors.naranjaQuemado;
    }

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: SurayColors.grisAntracita.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Text(
        ChileanUtils.formatDate(bus.fechaRevisionTecnica!),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _kilometrajeCell(double? kilometraje, double width) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: SurayColors.grisAntracita.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Text(
        kilometraje != null
            ? _formatKilometraje(kilometraje)
            : 'No registrado',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: kilometraje != null
              ? SurayColors.azulMarinoProfundo
              : SurayColors.grisAntracitaClaro,
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
      textColor = SurayColors.naranjaQuemado;
    }

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: SurayColors.grisAntracita.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Text(
        kmIdeal > 0 ? _formatKilometraje(kmIdeal) : 'No configurado',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
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
      textColor = SurayColors.naranjaQuemado;
    } else if (diasHastaFecha < 0) {
      textColor = Colors.red;
    }

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: SurayColors.grisAntracita.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Text(
        ChileanUtils.formatDate(fechaIdeal),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatKilometraje(double km) {
    final formatador = NumberFormat("#,##0", "es_CL");
    return formatador.format(km);
  }

  void _showMaintenanceConfig() {
    showDialog(
      context: context,
      barrierColor: SurayColors.azulMarinoProfundo.withOpacity(0.5),
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: _MaintenanceConfigDialog(
                onConfigChanged: () => setState(() {}),
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostrarDialogoBus(BuildContext context, {Bus? bus}) {
    showDialog<Bus>(
      context: context,
      barrierColor: SurayColors.azulMarinoProfundo.withOpacity(0.5),
      builder: (_) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: BusFormDialog(bus: bus),
            ),
          );
        },
      ),
    ).then((result) async {
      if (result == null) return;
      try {
        if (bus == null) {
          await DataService.addBus(result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bus creado exitosamente'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          await DataService.updateBus(result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bus actualizado exitosamente'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }

  void _registrarMantenimiento(BuildContext context, Bus bus) {
    showDialog(
      context: context,
      barrierColor: SurayColors.azulMarinoProfundo.withOpacity(0.5),
      builder: (_) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: MantenimientoPreventivoDialog(
                bus: bus,
                onMantenimientoRegistrado: () => setState(() {}),
              ),
            ),
          );
        },
      ),
    );
  }

  void _actualizarKilometraje(BuildContext context, Bus bus) {
    showDialog(
      context: context,
      barrierColor: SurayColors.azulMarinoProfundo.withOpacity(0.5),
      builder: (_) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: ActualizarKilometrajeDialog(
                bus: bus,
                onKilometrajeActualizado: () => setState(() {}),
              ),
            ),
          );
        },
      ),
    );
  }

  void _asignarRepuesto(BuildContext context, Bus bus) {
    showDialog(
      context: context,
      barrierColor: SurayColors.azulMarinoProfundo.withOpacity(0.5),
      builder: (_) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: AsignarRepuestoDialog(
                bus: bus,
                onRepuestoAsignado: () => setState(() {}),
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostrarHistorialCompleto(BuildContext context, Bus bus) {
    showDialog(
      context: context,
      barrierColor: SurayColors.azulMarinoProfundo.withOpacity(0.5),
      builder: (_) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: HistorialCompletoDialog(bus: bus),
            ),
          );
        },
      ),
    );
  }

  Future<void> _eliminarBus(String id) async {
    final bus = await DataService.getBusById(id);
    if (bus == null) return;

    final conf = await showDialog<bool>(
      context: context,
      barrierColor: SurayColors.azulMarinoProfundo.withOpacity(0.5),
      builder: (_) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Confirmar eliminación'),
                  ],
                ),
                content: Text(
                  '¿Estás seguro de eliminar el bus ${bus.patente}?\n\nEsta acción no se puede deshacer.',
                  style: TextStyle(fontSize: 15),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(_, false),
                    child: Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(_, true),
                    child: Text('Eliminar'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (conf == true) {
      try {
        await DataService.deleteBus(id);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bus eliminado exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
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
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: SurayColors.grisAntracita.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Página ${_currentPage + 1} de $totalPages',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: SurayColors.azulMarinoProfundo,
            ),
          ),
          Spacer(),
          _buildPaginationButton(
            icon: Icons.first_page,
            enabled: _currentPage > 0,
            onPressed: () => setState(() => _currentPage = 0),
          ),
          SizedBox(width: 8),
          _buildPaginationButton(
            icon: Icons.chevron_left,
            enabled: _currentPage > 0,
            onPressed: () => setState(() => _currentPage--),
          ),
          SizedBox(width: 16),
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
                    backgroundColor: _currentPage == pageIndex
                        ? SurayColors.azulMarinoProfundo
                        : SurayColors.blancoHumo,
                    foregroundColor: _currentPage == pageIndex
                        ? SurayColors.blancoHumo
                        : SurayColors.azulMarinoProfundo,
                    minimumSize: Size(40, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => setState(() => _currentPage = pageIndex),
                  child: Text('${pageIndex + 1}'),
                ),
              );
            },
          ),
          SizedBox(width: 16),
          _buildPaginationButton(
            icon: Icons.chevron_right,
            enabled: _currentPage < totalPages - 1,
            onPressed: () => setState(() => _currentPage++),
          ),
          SizedBox(width: 8),
          _buildPaginationButton(
            icon: Icons.last_page,
            enabled: _currentPage < totalPages - 1,
            onPressed: () => setState(() => _currentPage = totalPages - 1),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon),
      color: enabled ? SurayColors.azulMarinoProfundo : SurayColors.grisAntracitaClaro,
      onPressed: enabled ? onPressed : null,
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
      _busesFuture = null;
    });
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: SurayColors.azulMarinoProfundo,
            strokeWidth: 4,
          ),
          SizedBox(height: 24),
          Text(
            'Cargando buses...',
            style: TextStyle(
              color: SurayColors.grisAntracita,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(32),
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error al cargar buses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: SurayColors.azulMarinoProfundo,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: SurayColors.grisAntracita),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: Icon(Icons.refresh),
              label: Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SurayColors.azulMarinoProfundo,
                foregroundColor: SurayColors.blancoHumo,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(32),
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: SurayColors.grisAntracita.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_bus,
              size: 80,
              color: SurayColors.grisAntracitaClaro,
            ),
            SizedBox(height: 24),
            Text(
              (_filtroTexto.isNotEmpty ||
                  _filtroEstado != 'Todos' ||
                  _filtroMantenimiento != 'Todos')
                  ? 'No hay buses con esos filtros'
                  : 'No hay buses registrados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: SurayColors.azulMarinoProfundo,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Comienza agregando tu primer bus',
              style: TextStyle(
                color: SurayColors.grisAntracita,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _mostrarDialogoBus(context),
              icon: Icon(Icons.add_circle),
              label: Text('Agregar Bus'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SurayColors.naranjaQuemado,
                foregroundColor: SurayColors.blancoHumo,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Clase auxiliar para construir encabezados ordenables
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
        border: Border(
          right: BorderSide(
            color: SurayColors.blancoHumo.withOpacity(0.2),
            width: 1,
          ),
        ),
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
                  color: SurayColors.blancoHumo,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (sortKey != null)
              Icon(
                active ? (asc ? Icons.arrow_upward : Icons.arrow_downward) : Icons.sort,
                size: 16,
                color: active ? SurayColors.naranjaQuemado : SurayColors.blancoHumo.withOpacity(0.6),
              ),
          ],
        ),
      ),
    );
  }
}

// Dialog para configurar los intervalos de mantenimiento
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              SurayColors.azulMarinoProfundo,
              SurayColors.azulMarinoClaro,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.settings, color: SurayColors.blancoHumo),
            SizedBox(width: 12),
            Text(
              'Configuración de Mantenimiento',
              style: TextStyle(color: SurayColors.blancoHumo),
            ),
          ],
        ),
      ),
      content: Container(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SurayColors.azulMarinoProfundo.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: SurayColors.azulMarinoProfundo.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Intervalos de Mantenimiento',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: SurayColors.azulMarinoProfundo,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Configura los intervalos para calcular el kilometraje ideal y la fecha ideal de mantenimiento.',
                    style: TextStyle(
                      fontSize: 14,
                      color: SurayColors.grisAntracita,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            TextField(
              controller: _kmController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Kilometraje ideal para mantenimiento',
                suffixText: 'km',
                prefixIcon: Icon(Icons.speed, color: SurayColors.azulMarinoProfundo),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'Intervalo en kilómetros entre mantenimientos',
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _diasController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Días ideales para mantenimiento',
                suffixText: 'días',
                prefixIcon: Icon(Icons.calendar_today, color: SurayColors.azulMarinoProfundo),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'Intervalo en días entre mantenimientos',
              ),
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SurayColors.naranjaQuemado.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: SurayColors.naranjaQuemado.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: SurayColors.naranjaQuemado),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Los cambios se aplicarán inmediatamente a todos los buses en la tabla.',
                      style: TextStyle(
                        fontSize: 12,
                        color: SurayColors.naranjaQuemado,
                      ),
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
            backgroundColor: SurayColors.azulMarinoProfundo,
            foregroundColor: SurayColors.blancoHumo,
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (dias == null || dias <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Los días deben ser un número positivo'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// Widget separado para las filas de la tabla que maneja su propio hover state
class _BusTableRow extends StatefulWidget {
  final Bus bus;
  final bool isEven;
  final VoidCallback onTap;

  const _BusTableRow({
    required this.bus,
    required this.isEven,
    required this.onTap,
  });

  @override
  _BusTableRowState createState() => _BusTableRowState();
}

class _BusTableRowState extends State<_BusTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = _isHovered
        ? SurayColors.naranjaQuemado.withOpacity(0.08)
        : (widget.isEven ? SurayColors.blancoHumo : Colors.white);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: SurayColors.naranjaQuemado.withOpacity(0.05),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 150),
          height: 60,
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              bottom: BorderSide(
                color: SurayColors.grisAntracita.withOpacity(0.1),
                width: 1,
              ),
              left: _isHovered
                  ? BorderSide(color: SurayColors.naranjaQuemado, width: 4)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              _dataCell(widget.bus.identificador ?? '-', 100),
              _dataCell(widget.bus.patente, 140, bold: true),
              _dataCell(widget.bus.marca, 120),
              _dataCell(widget.bus.modelo, 140),
              _dataCell('${widget.bus.anio}', 80),
              _estadoCell(widget.bus, 140),
              _kilometrajeCell(widget.bus.kilometraje, 150),
              _kilometrajeIdealCell(widget.bus, 150),
              _fechaIdealCell(widget.bus, 150),
              _revisionTecnicaCell(widget.bus, 160),
              _dataCell(widget.bus.ubicacionActual ?? '-', 200),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dataCell(String text, double width, {bool bold = false}) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: SurayColors.grisAntracita.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: bold ? SurayColors.azulMarinoProfundo : SurayColors.grisAntracita,
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
        c = SurayColors.naranjaQuemado;
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
        border: Border(
          right: BorderSide(
            color: SurayColors.grisAntracita.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ic, size: 14, color: c),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                lbl,
                style: TextStyle(
                  fontSize: 12,
                  color: c,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _revisionTecnicaCell(Bus bus, double width) {
    if (bus.fechaRevisionTecnica == null) {
      return _dataCell('No registrada', width);
    }

    Color textColor = Colors.green;
    if (bus.revisionTecnicaVencida) {
      textColor = Colors.red;
    } else if (bus.revisionTecnicaProximaAVencer) {
      textColor = SurayColors.naranjaQuemado;
    }

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: SurayColors.grisAntracita.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Text(
        ChileanUtils.formatDate(bus.fechaRevisionTecnica!),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _kilometrajeCell(double? kilometraje, double width) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: SurayColors.grisAntracita.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Text(
        kilometraje != null
            ? _formatKilometraje(kilometraje)
            : 'No registrado',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: kilometraje != null
              ? SurayColors.azulMarinoProfundo
              : SurayColors.grisAntracitaClaro,
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
      textColor = SurayColors.naranjaQuemado;
    }

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: SurayColors.grisAntracita.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Text(
        kmIdeal > 0 ? _formatKilometraje(kmIdeal) : 'No configurado',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
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
      textColor = SurayColors.naranjaQuemado;
    } else if (diasHastaFecha < 0) {
      textColor = Colors.red;
    }

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: SurayColors.grisAntracita.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Text(
        ChileanUtils.formatDate(fechaIdeal),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatKilometraje(double km) {
    final formatador = NumberFormat("#,##0", "es_CL");
    return formatador.format(km);
  }
}
