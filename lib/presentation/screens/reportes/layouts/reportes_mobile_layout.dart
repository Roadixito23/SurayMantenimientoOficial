import 'package:flutter/material.dart';
import '../../../../main.dart';
import '../../../widgets/reportes/reportes_widgets.dart';

// =====================================================================
// === REPORTES MOBILE LAYOUT =========================================
// =====================================================================
// Vista móvil: header con gradiente, filtros chip horizontales,
// lista de cards compactas con bottom sheet para acciones.
// RefreshIndicator para pull-to-refresh.

class ReportesMobileLayout extends StatelessWidget {
  final List<Map<String, dynamic>> actividades;
  final String? filtroBusId;
  final DateTimeRange? filtroFecha;
  final List<Map<String, String>> buses;
  final ValueChanged<String?> onBusChanged;
  final VoidCallback onFechaPressed;
  final VoidCallback onClearBus;
  final VoidCallback onClearFecha;
  final void Function(Map<String, dynamic>) onEditar;
  final void Function(Map<String, dynamic>) onEliminar;
  final Future<void> Function() onRefresh;
  final bool isLoading;

  const ReportesMobileLayout({
    Key? key,
    required this.actividades,
    required this.filtroBusId,
    required this.filtroFecha,
    required this.buses,
    required this.onBusChanged,
    required this.onFechaPressed,
    required this.onClearBus,
    required this.onClearFecha,
    required this.onEditar,
    required this.onEliminar,
    required this.onRefresh,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- Header gradiente ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SurayColors.azulMarinoProfundo,
                SurayColors.azulMarinoProfundo.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historial Global',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Actividades de mantenimiento y reportes',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // --- Filtros móviles ---
        ReportesFiltrosMobile(
          filtroBusId: filtroBusId,
          filtroFecha: filtroFecha,
          buses: buses,
          onBusChanged: onBusChanged,
          onFechaPressed: onFechaPressed,
          onClearBus: onClearBus,
          onClearFecha: onClearFecha,
          totalResultados: actividades.length,
        ),
        const SizedBox(height: 8),
        // --- Lista ---
        Expanded(
          child: _buildContent(context),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (actividades.isEmpty) {
      return EmptyStateReportes(
        hasFilters: filtroBusId != null || filtroFecha != null,
      );
    }

    // Agrupar por fecha
    final grupos = agruparPorFecha(actividades);
    final allItems = <_ListItem>[];

    for (final entry in grupos.entries) {
      allItems.add(_ListItem(isHeader: true, headerTitle: entry.key, headerCount: entry.value.length));
      for (final registro in entry.value) {
        allItems.add(_ListItem(isHeader: false, registro: registro));
      }
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: SurayColors.naranjaQuemado,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: allItems.length,
        itemBuilder: (context, index) {
          final item = allItems[index];

          if (item.isHeader) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    item.headerTitle!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: SurayColors.azulMarinoProfundo.withOpacity(0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.headerCount}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final registro = item.registro!;
          return RegistroCardCompact(
            registro: registro,
            onTap: () => showRegistroActionsSheet(
              context: context,
              registro: registro,
              onEditar: () => onEditar(registro),
              onEliminar: () => onEliminar(registro),
            ),
          );
        },
      ),
    );
  }
}

// Helper para lista plana con headers
class _ListItem {
  final bool isHeader;
  final String? headerTitle;
  final int? headerCount;
  final Map<String, dynamic>? registro;

  _ListItem({
    required this.isHeader,
    this.headerTitle,
    this.headerCount,
    this.registro,
  });
}
