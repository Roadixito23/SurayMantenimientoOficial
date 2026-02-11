import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/bus.dart';
import '../../../../services/data_service.dart';
import '../../../../services/chilean_utils.dart';
import '../../../../main.dart';
import '../../../widgets/buses/buses_widgets.dart';
import '../../../dialogs/ver_estado_mantenimiento/ver_estado_mantenimiento_dialog.dart';

// =====================================================================
// === BUSES DESKTOP LAYOUT ===========================================
// =====================================================================
// Layout desktop: tabla con scroll horizontal/vertical, paginación completa

class BusesDesktopLayout extends StatefulWidget {
  final List<Bus> pageBuses;
  final int totalItems;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final void Function(Bus) onBusTap;

  const BusesDesktopLayout({
    Key? key,
    required this.pageBuses,
    required this.totalItems,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.onBusTap,
  }) : super(key: key);

  @override
  State<BusesDesktopLayout> createState() => _BusesDesktopLayoutState();
}

class _BusesDesktopLayoutState extends State<BusesDesktopLayout> {
  final ScrollController _headerHScrollController = ScrollController();
  final ScrollController _bodyHScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Sincronizar scroll horizontal entre header y body
    _headerHScrollController.addListener(() {
      if (_bodyHScrollController.hasClients &&
          _bodyHScrollController.offset != _headerHScrollController.offset) {
        _bodyHScrollController.jumpTo(_headerHScrollController.offset);
      }
    });
    _bodyHScrollController.addListener(() {
      if (_headerHScrollController.hasClients &&
          _headerHScrollController.offset != _bodyHScrollController.offset) {
        _headerHScrollController.jumpTo(_bodyHScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _headerHScrollController.dispose();
    _bodyHScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: widget.totalItems == 0
              ? _buildEmptyState(context)
              : _buildTableView(context),
        ),
        if (widget.totalItems > 0)
          BusesPagination(
            currentPage: widget.currentPage,
            totalPages: widget.totalPages,
            totalItems: widget.totalItems,
            compact: false,
            onPageChanged: widget.onPageChanged,
          ),
      ],
    );
  }

  Widget _buildTableView(BuildContext context) {
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
      200.0, // Ubicación
      120.0, // Acciones
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
                thumbVisibility: WidgetStateProperty.all(true),
                trackVisibility: WidgetStateProperty.all(true),
                thickness: WidgetStateProperty.all(8),
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return SurayColors.naranjaQuemado.withOpacity(0.7);
                  }
                  if (states.contains(WidgetState.dragged)) {
                    return SurayColors.naranjaQuemado.withOpacity(0.9);
                  }
                  return SurayColors.naranjaQuemado.withOpacity(0.5);
                }),
                trackColor: WidgetStateProperty.all(
                    SurayColors.azulMarinoProfundo.withOpacity(0.08)),
                trackBorderColor: WidgetStateProperty.all(
                    SurayColors.azulMarinoProfundo.withOpacity(0.15)),
                radius: Radius.circular(8),
                crossAxisMargin: 2,
                mainAxisMargin: 4,
              ),
              child: Scrollbar(
                controller: _headerHScrollController,
                child: SingleChildScrollView(
                  controller: _headerHScrollController,
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
                thumbVisibility: WidgetStateProperty.all(true),
                trackVisibility: WidgetStateProperty.all(true),
                thickness: WidgetStateProperty.all(8),
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return SurayColors.naranjaQuemado.withOpacity(0.7);
                  }
                  if (states.contains(WidgetState.dragged)) {
                    return SurayColors.naranjaQuemado.withOpacity(0.9);
                  }
                  return SurayColors.naranjaQuemado.withOpacity(0.5);
                }),
                trackColor: WidgetStateProperty.all(
                    SurayColors.azulMarinoProfundo.withOpacity(0.08)),
                trackBorderColor: WidgetStateProperty.all(
                    SurayColors.azulMarinoProfundo.withOpacity(0.15)),
                radius: Radius.circular(8),
                crossAxisMargin: 2,
                mainAxisMargin: 4,
                interactive: true,
              ),
              child: Scrollbar(
                controller: _bodyHScrollController,
                child: SingleChildScrollView(
                  controller: _bodyHScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: totalWidth,
                    child: Scrollbar(
                      controller: _verticalScrollController,
                      child: ListView.builder(
                        controller: _verticalScrollController,
                        itemCount: widget.pageBuses.length,
                        itemBuilder: (_, i) =>
                            _BusTableRow(
                              bus: widget.pageBuses[i],
                              isEven: i.isEven,
                              onTap: () => widget.onBusTap(widget.pageBuses[i]),
                            ),
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
      _HeaderCell('ID', 100),
      _HeaderCell('Patente', 140),
      _HeaderCell('Marca', 120),
      _HeaderCell('Modelo', 140),
      _HeaderCell('Año', 80),
      _HeaderCell('Estado', 140),
      _HeaderCell('Km Actual', 150),
      _HeaderCell('Km Ideal', 150),
      _HeaderCell('Fecha Ideal', 150),
      _HeaderCell('Revisión Técnica', 160),
      _HeaderCell('Ubicación', 200),
      _HeaderCell('Acciones', 120),
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
        children: headers.map((h) => h.build()).toList(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
              'No hay buses registrados',
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
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// === HEADER CELL =====================================================
// =====================================================================

class _HeaderCell {
  final String title;
  final double width;
  _HeaderCell(this.title, this.width);

  Widget build() {
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
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: SurayColors.blancoHumo,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// =====================================================================
// === BUS TABLE ROW ===================================================
// =====================================================================
// Widget separado para filas con hover state propio

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
              _accionesCell(context, widget.bus, 120),
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
          color: bold
              ? SurayColors.azulMarinoProfundo
              : SurayColors.grisAntracita,
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

  Widget _accionesCell(BuildContext context, Bus bus, double width) {
    final tieneAlertas = bus.tieneMantenimientosVencidos || bus.tieneMantenimientosUrgentes;
    
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: SurayColors.grisAntracita.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: tieneAlertas
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    VerEstadoMantenimientoDialog.show(context, bus: bus);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Ver estado',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : SizedBox.shrink(),
    );
  }
}
