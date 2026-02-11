import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/reporte_diario.dart';
import '../../../models/tipo_mantenimiento_personalizado.dart';
import '../../../main.dart';
import '../../../services/chilean_utils.dart';

// =====================================================================
// === REPORTES WIDGETS - Componentes compartidos =====================
// =====================================================================

// --- Helpers de color/icono para tipo de mantenimiento ---

Color getColorTipoMantenimiento(TipoMantenimiento tipo) {
  switch (tipo) {
    case TipoMantenimiento.correctivo:
      return const Color(0xFFE53E3E);
    case TipoMantenimiento.rutinario:
      return const Color(0xFF3182CE);
    case TipoMantenimiento.preventivo:
      return const Color(0xFF38A169);
  }
}

IconData getIconTipoMantenimiento(TipoMantenimiento tipo) {
  switch (tipo) {
    case TipoMantenimiento.correctivo:
      return Icons.handyman;
    case TipoMantenimiento.rutinario:
      return Icons.schedule;
    case TipoMantenimiento.preventivo:
      return Icons.build_circle;
  }
}

String getTipoMantenimientoLabel(TipoMantenimiento tipo) {
  switch (tipo) {
    case TipoMantenimiento.correctivo:
      return 'Correctivo';
    case TipoMantenimiento.rutinario:
      return 'Rutinario';
    case TipoMantenimiento.preventivo:
      return 'Preventivo';
  }
}

// --- Obtener color e icono de un registro genérico ---

Color getRegistroColor(Map<String, dynamic> registro) {
  if (registro['tipo'] == 'reporte') {
    final reporteData = registro['data'] as ReporteDiario;
    return reporteData.colorTipoTrabajo;
  } else {
    final TipoMantenimiento tipoMant = registro['tipoMantenimiento'];
    return getColorTipoMantenimiento(tipoMant);
  }
}

IconData getRegistroIcon(Map<String, dynamic> registro) {
  if (registro['tipo'] == 'reporte') {
    final reporteData = registro['data'] as ReporteDiario;
    return reporteData.iconoTipoTrabajo;
  } else {
    final TipoMantenimiento tipoMant = registro['tipoMantenimiento'];
    return getIconTipoMantenimiento(tipoMant);
  }
}

// =====================================================================
// === TipoBadge - Badge visual para tipo de actividad ================
// =====================================================================

class TipoBadge extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double size;

  const TipoBadge({
    Key? key,
    required this.color,
    required this.icon,
    this.size = 36,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.55),
    );
  }
}

// =====================================================================
// === RegistroCardDesktop - Card completa para desktop ================
// =====================================================================

class RegistroCardDesktop extends StatefulWidget {
  final Map<String, dynamic> registro;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const RegistroCardDesktop({
    Key? key,
    required this.registro,
    required this.onEditar,
    required this.onEliminar,
  }) : super(key: key);

  @override
  State<RegistroCardDesktop> createState() => _RegistroCardDesktopState();
}

class _RegistroCardDesktopState extends State<RegistroCardDesktop> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final registro = widget.registro;
    final DateTime fecha = registro['fecha'];
    final String descripcion = registro['descripcion'];
    final String? busDisplay = registro['busDisplay'];
    final tipoColor = getRegistroColor(registro);
    final tipoIcon = getRegistroIcon(registro);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: _isExpanded ? tipoColor.withOpacity(0.3) : Colors.grey.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          // Cabecera
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  TipoBadge(color: tipoColor, icon: tipoIcon),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          descripcion,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 13, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              ChileanUtils.formatDate(fecha),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                            if (busDisplay != null) ...[
                              const SizedBox(width: 14),
                              Icon(Icons.directions_bus,
                                  size: 13, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                busDisplay,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Tipo badge label
                  _buildTipoLabel(registro),
                  const SizedBox(width: 12),
                  // Acciones inline
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        size: 18, color: SurayColors.azulMarinoProfundo),
                    tooltip: 'Editar',
                    onPressed: widget.onEditar,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: Colors.red[400]),
                    tooltip: 'Eliminar',
                    onPressed: widget.onEliminar,
                    visualDensity: VisualDensity.compact,
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            ),
          ),
          // Detalles expandibles
          if (_isExpanded)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: _buildDetallesExpandidos(registro),
            ),
        ],
      ),
    );
  }

  Widget _buildTipoLabel(Map<String, dynamic> registro) {
    String label;
    Color color;

    if (registro['tipo'] == 'reporte') {
      final reporte = registro['data'] as ReporteDiario;
      label = reporte.tipoTrabajoDisplay;
      color = reporte.colorTipoTrabajo;
    } else {
      final TipoMantenimiento tipo = registro['tipoMantenimiento'];
      label = getTipoMantenimientoLabel(tipo);
      color = getColorTipoMantenimiento(tipo);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetallesExpandidos(Map<String, dynamic> registro) {
    final tecnico = registro['tecnico'] ?? registro['autor'];
    final observaciones = registro['observaciones'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 12),
        if (tecnico != null)
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 8),
              const Text('Técnico/Autor: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(tecnico, style: const TextStyle(fontSize: 13)),
            ],
          ),
        if (tecnico != null) const SizedBox(height: 10),
        if (observaciones != null && observaciones.toString().isNotEmpty) ...[
          const Text('Observaciones:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Text(
              '$observaciones',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
        if (registro['tipo'] == 'reporte') ...[
          const SizedBox(height: 10),
          _buildBusesAtendidos(registro),
        ],
      ],
    );
  }

  Widget _buildBusesAtendidos(Map<String, dynamic> registro) {
    final buses = registro['busesReporte'] as List? ?? [];
    if (buses.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Buses atendidos:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: buses
              .map((bus) => Chip(
                    avatar: const Icon(Icons.directions_bus, size: 14),
                    label: Text(bus.toString(),
                        style: const TextStyle(fontSize: 11)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// =====================================================================
// === RegistroCardCompact - Card compacta para mobile ================
// =====================================================================

class RegistroCardCompact extends StatelessWidget {
  final Map<String, dynamic> registro;
  final VoidCallback onTap;

  const RegistroCardCompact({
    Key? key,
    required this.registro,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateTime fecha = registro['fecha'];
    final String descripcion = registro['descripcion'];
    final String? busDisplay = registro['busDisplay'];
    final tipoColor = getRegistroColor(registro);
    final tipoIcon = getRegistroIcon(registro);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              TipoBadge(color: tipoColor, icon: tipoIcon, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          ChileanUtils.formatDate(fecha),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600]),
                        ),
                        if (busDisplay != null) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.directions_bus,
                              size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              busDisplay,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// === ReportesFiltros - Panel de filtros adaptable ====================
// =====================================================================

class ReportesFiltrosDesktop extends StatelessWidget {
  final String? filtroBusId;
  final DateTimeRange? filtroFecha;
  final List<Map<String, String>> buses; // [{id, display}]
  final ValueChanged<String?> onBusChanged;
  final VoidCallback onFechaPressed;
  final VoidCallback onClearBus;
  final VoidCallback onClearFecha;

  const ReportesFiltrosDesktop({
    Key? key,
    required this.filtroBusId,
    required this.filtroFecha,
    required this.buses,
    required this.onBusChanged,
    required this.onFechaPressed,
    required this.onClearBus,
    required this.onClearFecha,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Filtro por bus
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: filtroBusId,
                hint: const Text('Toda la flota'),
                decoration: InputDecoration(
                  labelText: 'Filtrar por Bus',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.directions_bus),
                  suffixIcon: filtroBusId != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: onClearBus,
                        )
                      : null,
                ),
                items: buses
                    .map((b) => DropdownMenuItem(
                          value: b['id'],
                          child: Text(b['display']!),
                        ))
                    .toList(),
                onChanged: onBusChanged,
              ),
            ),
            const SizedBox(width: 16),
            // Filtro por fecha
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: onFechaPressed,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Filtrar por Fecha',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_today),
                    suffixIcon: filtroFecha != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: onClearFecha,
                          )
                        : null,
                  ),
                  child: Text(
                    filtroFecha != null
                        ? '${DateFormat('dd/MM/yy').format(filtroFecha!.start)} - ${DateFormat('dd/MM/yy').format(filtroFecha!.end)}'
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
}

class ReportesFiltrosMobile extends StatelessWidget {
  final String? filtroBusId;
  final DateTimeRange? filtroFecha;
  final List<Map<String, String>> buses;
  final ValueChanged<String?> onBusChanged;
  final VoidCallback onFechaPressed;
  final VoidCallback onClearBus;
  final VoidCallback onClearFecha;
  final int totalResultados;

  const ReportesFiltrosMobile({
    Key? key,
    required this.filtroBusId,
    required this.filtroFecha,
    required this.buses,
    required this.onBusChanged,
    required this.onFechaPressed,
    required this.onClearBus,
    required this.onClearFecha,
    required this.totalResultados,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasFilters = filtroBusId != null || filtroFecha != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Header con conteo y filtro rápido
          Row(
            children: [
              Expanded(
                child: Text(
                  '$totalResultados actividades',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              if (hasFilters)
                TextButton.icon(
                  onPressed: () {
                    onClearBus();
                    onClearFecha();
                  },
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Limpiar', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[400],
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Chips de filtro rápido
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Chip de bus
                _FiltroChip(
                  icon: Icons.directions_bus,
                  label: filtroBusId != null
                      ? buses
                          .firstWhere(
                            (b) => b['id'] == filtroBusId,
                            orElse: () => {'display': 'Bus'},
                          )['display']!
                      : 'Bus',
                  isActive: filtroBusId != null,
                  onTap: () => _showBusFilterSheet(context),
                ),
                const SizedBox(width: 8),
                // Chip de fecha
                _FiltroChip(
                  icon: Icons.calendar_today,
                  label: filtroFecha != null
                      ? '${DateFormat('dd/MM').format(filtroFecha!.start)} - ${DateFormat('dd/MM').format(filtroFecha!.end)}'
                      : 'Fecha',
                  isActive: filtroFecha != null,
                  onTap: onFechaPressed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBusFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Filtrar por Bus',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.select_all,
                  color: filtroBusId == null
                      ? SurayColors.naranjaQuemado
                      : Colors.grey),
              title: const Text('Toda la flota'),
              selected: filtroBusId == null,
              onTap: () {
                onClearBus();
                Navigator.pop(ctx);
              },
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: buses.length,
                itemBuilder: (_, i) {
                  final bus = buses[i];
                  final isSelected = bus['id'] == filtroBusId;
                  return ListTile(
                    leading: Icon(
                      Icons.directions_bus,
                      color: isSelected
                          ? SurayColors.naranjaQuemado
                          : Colors.grey[600],
                    ),
                    title: Text(bus['display']!),
                    selected: isSelected,
                    onTap: () {
                      onBusChanged(bus['id']);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// --- Chip de filtro reutilizable ---

class _FiltroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? SurayColors.naranjaQuemado.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? SurayColors.naranjaQuemado.withOpacity(0.4)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? SurayColors.naranjaQuemado : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? SurayColors.naranjaQuemado : Colors.grey[700],
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle,
                  size: 12, color: SurayColors.naranjaQuemado),
            ],
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// === EmptyStateReportes - Estado vacío ===============================
// =====================================================================

class EmptyStateReportes extends StatelessWidget {
  final bool hasFilters;

  const EmptyStateReportes({Key? key, this.hasFilters = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.filter_list_off : Icons.history_toggle_off,
              size: 56,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'No hay actividades que coincidan con los filtros'
                  : 'Sin actividades registradas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Prueba a cambiar los filtros de bus o de fecha'
                  : 'Las actividades de mantenimiento y reportes aparecerán aquí',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// === showRegistroActionsSheet - Bottom sheet mobile ==================
// =====================================================================

void showRegistroActionsSheet({
  required BuildContext context,
  required Map<String, dynamic> registro,
  required VoidCallback onEditar,
  required VoidCallback onEliminar,
}) {
  final DateTime fecha = registro['fecha'];
  final String descripcion = registro['descripcion'];
  final String? busDisplay = registro['busDisplay'];
  final tipoColor = getRegistroColor(registro);
  final tipoIcon = getRegistroIcon(registro);
  final tecnico = registro['tecnico'] ?? registro['autor'];
  final observaciones = registro['observaciones'];

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Row(
              children: [
                TipoBadge(color: tipoColor, icon: tipoIcon, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        descripcion,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            ChileanUtils.formatDate(fecha),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          if (busDisplay != null) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.directions_bus,
                                size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                busDisplay,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            // Detalles
            if (tecnico != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text('Técnico/Autor: ',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Flexible(
                    child: Text(tecnico,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
            if (observaciones != null &&
                observaciones.toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$observaciones',
                  style: const TextStyle(fontSize: 12, height: 1.4),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            // Buses atendidos (solo para reportes)
            if (registro['tipo'] == 'reporte') ...[
              const SizedBox(height: 10),
              _buildBusesChips(registro),
            ],
            const SizedBox(height: 16),
            // Acciones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onEditar();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SurayColors.azulMarinoProfundo,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onEliminar();
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Eliminar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      side: BorderSide(color: Colors.red[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildBusesChips(Map<String, dynamic> registro) {
  final buses = registro['busesReporte'] as List? ?? [];
  if (buses.isEmpty) return const SizedBox();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Buses atendidos:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
      const SizedBox(height: 4),
      Wrap(
        spacing: 4,
        runSpacing: 2,
        children: buses
            .map((bus) => Chip(
                  avatar: const Icon(Icons.directions_bus, size: 12),
                  label:
                      Text(bus.toString(), style: const TextStyle(fontSize: 10)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ))
            .toList(),
      ),
    ],
  );
}

// =====================================================================
// === Agrupación por fecha helpers ====================================
// =====================================================================

/// Agrupa las actividades por fecha (Hoy, Ayer, Esta Semana, Este Mes, Anteriores)
Map<String, List<Map<String, dynamic>>> agruparPorFecha(
    List<Map<String, dynamic>> actividades) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  final monthStart = DateTime(now.year, now.month, 1);

  final Map<String, List<Map<String, dynamic>>> grupos = {};

  for (final actividad in actividades) {
    final fecha = actividad['fecha'] as DateTime;
    final fechaDia = DateTime(fecha.year, fecha.month, fecha.day);

    String grupo;
    if (fechaDia == today) {
      grupo = 'Hoy';
    } else if (fechaDia == yesterday) {
      grupo = 'Ayer';
    } else if (fechaDia.isAfter(weekStart) || fechaDia == weekStart) {
      grupo = 'Esta semana';
    } else if (fechaDia.isAfter(monthStart) || fechaDia == monthStart) {
      grupo = 'Este mes';
    } else {
      grupo = DateFormat('MMMM yyyy', 'es').format(fecha);
    }

    grupos.putIfAbsent(grupo, () => []);
    grupos[grupo]!.add(actividad);
  }

  return grupos;
}
