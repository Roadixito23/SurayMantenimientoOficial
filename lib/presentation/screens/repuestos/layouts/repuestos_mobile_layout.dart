import 'package:flutter/material.dart';
import '../../../../models/repuesto.dart';
import '../../../../main.dart';
import '../../../widgets/repuestos/repuestos_widgets.dart';

// =====================================================================
// === REPUESTOS MOBILE LAYOUT ========================================
// =====================================================================
// Layout móvil: filtros compactos, cards compactas, bottom sheet
// para acciones, FAB para nuevo repuesto, agrupación por sistema
// con headers colapsables

class RepuestosMobileLayout extends StatelessWidget {
  final List<RepuestoCatalogo> repuestosFiltrados;
  final String filtroTexto;
  final String filtroSistema;
  final String filtroTipo;
  final TextEditingController searchController;
  final List<String> sistemasDisponibles;
  final List<String> tiposDisponibles;
  final int totalRepuestos;
  final ValueChanged<String> onTextoChanged;
  final ValueChanged<String> onSistemaChanged;
  final ValueChanged<String> onTipoChanged;
  final VoidCallback onLimpiar;
  final void Function(RepuestoCatalogo) onVerDetalles;
  final void Function(RepuestoCatalogo) onEditar;
  final void Function(RepuestoCatalogo) onEliminar;
  final void Function(RepuestoCatalogo) onCardTap;

  const RepuestosMobileLayout({
    Key? key,
    required this.repuestosFiltrados,
    required this.filtroTexto,
    required this.filtroSistema,
    required this.filtroTipo,
    required this.searchController,
    required this.sistemasDisponibles,
    required this.tiposDisponibles,
    required this.totalRepuestos,
    required this.onTextoChanged,
    required this.onSistemaChanged,
    required this.onTipoChanged,
    required this.onLimpiar,
    required this.onVerDetalles,
    required this.onEditar,
    required this.onEliminar,
    required this.onCardTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header compacto
          _buildMobileHeader(context),
          // Filtros compactos
          RepuestoFilters(
            filtroTexto: filtroTexto,
            filtroSistema: filtroSistema,
            filtroTipo: filtroTipo,
            searchController: searchController,
            sistemasDisponibles: sistemasDisponibles,
            tiposDisponibles: tiposDisponibles,
            compact: true,
            onTextoChanged: onTextoChanged,
            onSistemaChanged: onSistemaChanged,
            onTipoChanged: onTipoChanged,
            onLimpiar: onLimpiar,
          ),
          // Conteo
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${repuestosFiltrados.length} de $totalRepuestos',
                  style: TextStyle(
                    color: SurayColors.grisAntracita,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Lista
          Expanded(
            child: repuestosFiltrados.isEmpty
                ? _buildEmptyState()
                : _buildGroupedList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SurayColors.azulMarinoProfundo,
            SurayColors.azulMarinoClaro,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: SurayColors.azulMarinoProfundo.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: SurayColors.naranjaQuemado,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.build, color: Colors.white, size: 18),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catálogo de Repuestos',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$totalRepuestos repuestos registrados',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(BuildContext context) {
    // Agrupar por sistema
    final porSistema = <String, List<RepuestoCatalogo>>{};
    for (final r in repuestosFiltrados) {
      porSistema.putIfAbsent(r.sistemaLabel, () => []).add(r);
    }

    final sistemas = porSistema.keys.toList();

    return ListView.builder(
      padding: EdgeInsets.only(bottom: 80),
      itemCount: sistemas.length,
      itemBuilder: (context, sIndex) {
        final sistema = sistemas[sIndex];
        final repuestos = porSistema[sistema]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del sistema
            Container(
              margin: EdgeInsets.fromLTRB(12, 8, 12, 4),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: SurayColors.azulMarinoProfundo.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  SistemaVehiculoIcon(
                    sistema: repuestos.first.sistema,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    sistema,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: SurayColors.azulMarinoProfundo,
                    ),
                  ),
                  SizedBox(width: 6),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${repuestos.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Cards de repuestos
            ...repuestos.map((r) => RepuestoCardCompact(
                  repuesto: r,
                  onTap: () => onCardTap(r),
                )),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = filtroTexto.isNotEmpty ||
        filtroSistema != 'Todos' ||
        filtroTipo != 'Todos';

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.build, size: 56, color: SurayColors.grisAntracitaClaro),
            SizedBox(height: 12),
            Text(
              hasFilters
                  ? 'Sin resultados'
                  : 'Sin repuestos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: SurayColors.azulMarinoProfundo,
              ),
            ),
            SizedBox(height: 4),
            Text(
              hasFilters
                  ? 'Intenta con otros filtros'
                  : 'Toca + para agregar el primer repuesto',
              style: TextStyle(
                color: SurayColors.grisAntracita,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              SizedBox(height: 12),
              TextButton(
                onPressed: onLimpiar,
                child: Text('Limpiar filtros'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
