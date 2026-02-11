import 'package:flutter/material.dart';
import '../../../../models/bus.dart';
import '../../../../main.dart';
import '../../../widgets/buses/buses_widgets.dart';

// =====================================================================
// === BUSES MOBILE LAYOUT =============================================
// =====================================================================
// Layout móvil: Cards en ListView, paginación compacta, RefreshIndicator

class BusesMobileLayout extends StatelessWidget {
  final List<Bus> pageBuses;
  final int totalItems;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final void Function(Bus) onBusTap;
  final Future<void> Function() onRefresh;

  const BusesMobileLayout({
    Key? key,
    required this.pageBuses,
    required this.totalItems,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.onBusTap,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (totalItems == 0) {
      return _buildEmptyState(context);
    }

    return SafeArea(
      child: Column(
        children: [
          // Barra de resumen compacta
          _buildMobileHeader(),
          // Lista de buses
          Expanded(
            child: RefreshIndicator(
              onRefresh: onRefresh,
              color: SurayColors.naranjaQuemado,
              child: ListView.builder(
                padding: EdgeInsets.only(top: 8, bottom: 80),
                itemCount: pageBuses.length,
                itemBuilder: (context, index) {
                  return BusCard(
                    bus: pageBuses[index],
                    onTap: () => onBusTap(pageBuses[index]),
                  );
                },
              ),
            ),
          ),
          // Paginación compacta
          BusesPagination(
            currentPage: currentPage,
            totalPages: totalPages,
            totalItems: totalItems,
            compact: true,
            onPageChanged: onPageChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
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
            child: Icon(
              Icons.directions_bus,
              color: Colors.white,
              size: 18,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de Flota',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$totalItems buses registrados',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          // Indicador de página
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${currentPage + 1}/$totalPages',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_bus,
                size: 64,
                color: SurayColors.grisAntracitaClaro,
              ),
              SizedBox(height: 16),
              Text(
                'No hay buses registrados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: SurayColors.azulMarinoProfundo,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Toca el botón + para agregar tu primer bus',
                style: TextStyle(
                  color: SurayColors.grisAntracita,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
