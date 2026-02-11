import 'package:flutter/material.dart';
import '../../../../models/repuesto.dart';
import '../../../widgets/repuestos/repuestos_widgets.dart';

// =====================================================================
// === REPUESTOS DESKTOP LAYOUT =======================================
// =====================================================================
// Layout desktop: filtros en fila, lista con ExpansionTiles agrupados
// por sistema, cards con acciones inline (detalles, editar, eliminar)

class RepuestosDesktopLayout extends StatelessWidget {
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
  final VoidCallback onNuevoRepuesto;
  final void Function(RepuestoCatalogo) onVerDetalles;
  final void Function(RepuestoCatalogo) onEditar;
  final void Function(RepuestoCatalogo) onEliminar;

  const RepuestosDesktopLayout({
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
    required this.onNuevoRepuesto,
    required this.onVerDetalles,
    required this.onEditar,
    required this.onEliminar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Catálogo de Repuestos',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              ElevatedButton.icon(
                onPressed: onNuevoRepuesto,
                icon: Icon(Icons.add),
                label: Text('Nuevo Repuesto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          // Filtros
          RepuestoFilters(
            filtroTexto: filtroTexto,
            filtroSistema: filtroSistema,
            filtroTipo: filtroTipo,
            searchController: searchController,
            sistemasDisponibles: sistemasDisponibles,
            tiposDisponibles: tiposDisponibles,
            compact: false,
            onTextoChanged: onTextoChanged,
            onSistemaChanged: onSistemaChanged,
            onTipoChanged: onTipoChanged,
            onLimpiar: onLimpiar,
          ),
          SizedBox(height: 8),
          // Conteo
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              'Mostrando ${repuestosFiltrados.length} de $totalRepuestos repuestos',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          SizedBox(height: 8),
          // Lista agrupada
          Expanded(
            child: repuestosFiltrados.isEmpty
                ? _buildEmptyState()
                : _buildGroupedList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList() {
    // Agrupar por sistema
    final porSistema = <String, List<RepuestoCatalogo>>{};
    for (final r in repuestosFiltrados) {
      porSistema.putIfAbsent(r.sistemaLabel, () => []).add(r);
    }

    return ListView.builder(
      itemCount: porSistema.keys.length,
      itemBuilder: (context, index) {
        final sistema = porSistema.keys.elementAt(index);
        final repuestos = porSistema[sistema]!;

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Row(
              children: [
                SistemaVehiculoIcon(sistema: repuestos.first.sistema),
                SizedBox(width: 12),
                Text(
                  sistema,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(width: 8),
                Chip(
                  label: Text('${repuestos.length}'),
                  backgroundColor: Colors.blue[100],
                ),
              ],
            ),
            children: repuestos
                .map((r) => RepuestoCardFull(
                      repuesto: r,
                      onVerDetalles: () => onVerDetalles(r),
                      onEditar: () => onEditar(r),
                      onEliminar: () => onEliminar(r),
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = filtroTexto.isNotEmpty ||
        filtroSistema != 'Todos' ||
        filtroTipo != 'Todos';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            hasFilters
                ? 'No se encontraron repuestos con los filtros aplicados'
                : 'No hay repuestos en el catálogo',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          if (hasFilters)
            ElevatedButton(
              onPressed: onLimpiar,
              child: Text('Limpiar filtros'),
            )
          else
            Text('Agrega el primer repuesto para comenzar'),
        ],
      ),
    );
  }
}
