import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/data_service.dart';
import '../../../../models/bus.dart';
import '../../../widgets/dashboard/dashboard_widgets.dart';

// =====================================================================
// === DASHBOARD MOBILE LAYOUT =========================================
// =====================================================================
// Layout optimizado para móviles (< 600px)
// Versión vertical scrolleable con cards apiladas

class DashboardMobileLayout extends StatelessWidget {
  final VoidCallback onRefresh;

  const DashboardMobileLayout({Key? key, required this.onRefresh})
      : super(key: key);

  String _formatNumber(double num) {
    final formatador = NumberFormat("#,##0", "es_CL");
    return formatador.format(num);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          onRefresh();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                'Panel Principal',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 16),

              // Estado de la flota (cards compactas en columna) - OCULTO
              // _buildEstadoBusesCompacto(),
              // SizedBox(height: 16),

              // Alerta ROJA para buses VENCIDOS
              _buildAlertasKilometrajeVencido(),
              SizedBox(height: 16),

              // Aviso NARANJA para buses PRÓXIMOS
              _buildAlertasKilometrajeProximo(),
              SizedBox(height: 16),

              // Revisiones técnicas vencidas
              _buildRevisionTecnicaVencidaCard(),
              SizedBox(height: 16),

              // Revisiones técnicas próximas a vencer
              _buildRevisionTecnicaProximaCard(),
              SizedBox(height: 80), // Espacio para el BottomNavigationBar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoBusesCompacto() {
    return FutureBuilder<Map<String, int>>(
      future: DataService.getEstadisticas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Error al cargar estadísticas'),
            ),
          );
        }

        final stats = snapshot.data ?? {};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estado de la Flota',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: onRefresh,
                  color: Color(0xFF1565C0),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Cards apiladas verticalmente
            StatCard(
              title: 'Disponibles',
              value: (stats['disponibles'] ?? 0).toString(),
              icon: Icons.check_circle,
              color: Colors.green,
              compact: true,
            ),
            SizedBox(height: 8),
            StatCard(
              title: 'En Reparación',
              value: (stats['enReparacion'] ?? 0).toString(),
              icon: Icons.build,
              color: Colors.orange,
              compact: true,
            ),
            SizedBox(height: 8),
            StatCard(
              title: 'Fuera de Servicio',
              value: (stats['fueraServicio'] ?? 0).toString(),
              icon: Icons.cancel,
              color: Colors.red,
              compact: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlertasKilometrajeVencido() {
    return FutureBuilder<List<Bus>>(
      future: DataService.getBusesConKilometrajeVencido(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox.shrink();
        }

        final busesConAlerta = snapshot.data ?? [];

        if (busesConAlerta.isEmpty) {
          return FutureBuilder<List<Bus>>(
            future: DataService.getBusesConKilometrajeProximo(),
            builder: (context, proximoSnapshot) {
              if (proximoSnapshot.hasData && proximoSnapshot.data!.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Flota en Orden',
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Sin alertas de kilometraje',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return SizedBox.shrink();
            },
          );
        }

        return Card(
          color: Colors.red[50],
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red[200]!, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mantenimiento Urgente',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[800],
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${busesConAlerta.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Buses con kilometraje excedido',
                  style: TextStyle(fontSize: 11, color: Colors.red[700]),
                ),
                SizedBox(height: 12),
                ...busesConAlerta.map((bus) => Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: _buildBusAlertaItemCompact(bus, isExceeded: true),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertasKilometrajeProximo() {
    return FutureBuilder<List<Bus>>(
      future: DataService.getBusesConKilometrajeProximo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
          return SizedBox.shrink();
        }

        final busesConAviso = snapshot.data ?? [];

        return Card(
          color: Colors.orange[50],
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orange[200]!, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mantenimiento Próximo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${busesConAviso.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Buses cerca del límite de kilometraje',
                  style: TextStyle(fontSize: 11, color: Colors.orange[700]),
                ),
                SizedBox(height: 12),
                ...busesConAviso.map((bus) => Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child:
                          _buildBusAlertaItemCompact(bus, isExceeded: false),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBusAlertaItemCompact(Bus bus, {required bool isExceeded}) {
    final kmActual = bus.kilometraje ?? 0;
    final kmIdeal = bus.kilometrajeIdeal ?? 0;
    final diferencia = isExceeded ? kmActual - kmIdeal : kmIdeal - kmActual;
    final color = isExceeded ? Colors.red : Colors.orange;

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_bus, color: color, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${bus.identificadorDisplay}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Text(
                isExceeded
                    ? '+${_formatNumber(diferencia)} km'
                    : '-${_formatNumber(diferencia)} km',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            '${bus.marca} ${bus.modelo}',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Actual: ${_formatNumber(kmActual)}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              Text(
                'Ideal: ${_formatNumber(kmIdeal)}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevisionTecnicaVencidaCard() {
    return FutureBuilder<List<Bus>>(
      future: DataService.getBusesRevisionTecnicaVencida(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final busesVencidas = snapshot.data ?? [];

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red.withOpacity(0.3), width: 2),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.error, color: Colors.red, size: 18),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Revisión Técnica Vencida',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[800],
                            ),
                          ),
                          Text(
                            '${busesVencidas.length} ${busesVencidas.length == 1 ? 'bus' : 'buses'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Divider(),
                SizedBox(height: 8),
                if (busesVencidas.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle,
                              size: 36, color: Colors.green),
                          SizedBox(height: 8),
                          Text(
                            'Sin revisiones vencidas',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...busesVencidas.map((bus) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: _buildRevisionItemCompact(
                          bus,
                          'Vencida hace ${-bus.diasParaVencimientoRevision} días',
                          Colors.red,
                          'CRÍTICO',
                        ),
                      )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRevisionTecnicaProximaCard() {
    return FutureBuilder<List<Bus>>(
      future: DataService.getBusesRevisionTecnicaProximaVencer(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final busesProximas = snapshot.data ?? [];

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orange.withOpacity(0.3), width: 2),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          Icon(Icons.warning, color: Colors.orange, size: 18),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Próximas a Vencer',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                          Text(
                            '${busesProximas.length} ${busesProximas.length == 1 ? 'bus' : 'buses'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Divider(),
                SizedBox(height: 8),
                if (busesProximas.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle,
                              size: 36, color: Colors.green),
                          SizedBox(height: 8),
                          Text(
                            'Todo bajo control',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...busesProximas.map((bus) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: _buildRevisionItemCompact(
                          bus,
                          'Vence en ${bus.diasParaVencimientoRevision} días',
                          Colors.orange,
                          'URGENTE',
                        ),
                      )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRevisionItemCompact(
      Bus bus, String mensaje, Color color, String badge) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              badge == 'CRÍTICO' ? Icons.error : Icons.warning,
              color: Colors.white,
              size: 16,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bus.identificadorDisplay,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  mensaje,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${bus.marca} ${bus.modelo}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
