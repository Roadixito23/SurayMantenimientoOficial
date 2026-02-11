import 'package:flutter/material.dart';
import '../../../../main.dart';
import '../../../widgets/reportes/reportes_widgets.dart';

// =====================================================================
// === REPORTES DESKTOP LAYOUT ========================================
// =====================================================================
// Vista de escritorio: filtros en fila, lista expandible agrupada por
// fecha con cards detalladas y acciones inline.

class ReportesDesktopLayout extends StatelessWidget {
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
  final bool isLoading;

  const ReportesDesktopLayout({
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
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Título ---
          Row(
            children: [
              Text(
                'Historial Global de Actividades',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // Conteo de resultados
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: SurayColors.azulMarinoProfundo.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.list_alt,
                        size: 16, color: SurayColors.azulMarinoProfundo),
                    const SizedBox(width: 6),
                    Text(
                      '${actividades.length} registros',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: SurayColors.azulMarinoProfundo,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // --- Filtros ---
          ReportesFiltrosDesktop(
            filtroBusId: filtroBusId,
            filtroFecha: filtroFecha,
            buses: buses,
            onBusChanged: onBusChanged,
            onFechaPressed: onFechaPressed,
            onClearBus: onClearBus,
            onClearFecha: onClearFecha,
          ),
          const SizedBox(height: 16),
          // --- Lista ---
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
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

    return ListView.builder(
      itemCount: grupos.length,
      itemBuilder: (context, index) {
        final grupoNombre = grupos.keys.elementAt(index);
        final grupoItems = grupos[grupoNombre]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del grupo
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(
                children: [
                  Text(
                    grupoNombre,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: SurayColors.azulMarinoProfundo.withOpacity(0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${grupoItems.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
            ),
            // Items del grupo
            ...grupoItems.map(
              (registro) => RegistroCardDesktop(
                registro: registro,
                onEditar: () => onEditar(registro),
                onEliminar: () => onEliminar(registro),
              ),
            ),
          ],
        );
      },
    );
  }
}
