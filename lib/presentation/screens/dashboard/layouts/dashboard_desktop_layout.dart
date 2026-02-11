import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/data_service.dart';
import '../../../../models/bus.dart';
import '../../../widgets/dashboard/dashboard_widgets.dart';

// =====================================================================
// === DASHBOARD DESKTOP LAYOUT ========================================
// =====================================================================
// Layout optimizado para pantallas de escritorio (>= 900px)
// Mantiene el diseño original de dos columnas y grids

class DashboardDesktopLayout extends StatelessWidget {
  final VoidCallback onRefresh;

  const DashboardDesktopLayout({Key? key, required this.onRefresh})
      : super(key: key);

  String _formatNumber(double num) {
    final formatador = NumberFormat("#,##0", "es_CL");
    return formatador.format(num);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: RefreshIndicator(
        onRefresh: () async {
          onRefresh();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEstadoBusesCompacto(),
            SizedBox(height: 20),

            // Alerta ROJA para buses VENCIDOS
            _buildAlertasKilometrajeVencido(),
            SizedBox(height: 20),

            // Aviso NARANJA para buses PRÓXIMOS A MANTENIMIENTO
            _buildAlertasKilometrajeProximo(),
            SizedBox(height: 20),

            // Contenido principal - Dos columnas para revisión técnica
            Expanded(
              child: FutureBuilder<List<List<Bus>>>(
                future: Future.wait([
                  DataService.getBusesRevisionTecnicaProximaVencer(),
                  DataService.getBusesRevisionTecnicaVencida(),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Card(
                        child: Center(child: CircularProgressIndicator()));
                  }
                  final busesProximasVencer = snapshot.data?[0] ?? [];
                  final busesVencidas = snapshot.data?[1] ?? [];

                  return Row(
                    children: [
                      // Columna izquierda - Vencidas
                      Expanded(
                        child: _buildRevisionTecnicaVencidaCard(busesVencidas),
                      ),
                      SizedBox(width: 20),
                      // Columna derecha - Próximas a vencer
                      Expanded(
                        child: _buildRevisionTecnicaProximaCard(
                            busesProximasVencer),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orange[200]!, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Aviso de Mantenimiento Próximo',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800]),
                    ),
                    Spacer(),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${busesConAviso.length} ${busesConAviso.length > 1 ? "BUSES" : "BUS"} REQUIEREN ATENCIÓN',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Los siguientes buses están a menos del 20% de su kilometraje ideal para mantenimiento.',
                  style: TextStyle(fontSize: 13, color: Colors.orange[700]),
                ),
                SizedBox(height: 16),
                ...busesConAviso.map((bus) => _buildBusAvisoItem(bus)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBusAvisoItem(Bus bus) {
    final kmActual = bus.kilometraje ?? 0;
    final kmIdeal = bus.kilometrajeIdeal ?? 0;
    final diferencia = kmIdeal - kmActual;

    return BusAlertCard(
      identificador: bus.identificadorDisplay,
      marca: bus.marca,
      modelo: bus.modelo,
      patente: bus.patente,
      mensaje: 'Faltan ${_formatNumber(diferencia)} km',
      detalleActual: 'Actual: ${_formatNumber(kmActual)}',
      detalleIdeal: 'Ideal: ${_formatNumber(kmIdeal)}',
      color: Colors.orange,
      isExceeded: false,
    );
  }

  Widget _buildAlertasKilometrajeVencido() {
    return FutureBuilder<List<Bus>>(
      future: DataService.getBusesConKilometrajeVencido(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(width: 16),
                  Text('Verificando alertas de kilometraje...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            color: Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                  'Error al cargar alertas de kilometraje: ${snapshot.error}'),
            ),
          );
        }

        final busesConAlerta = snapshot.data ?? [];

        if (busesConAlerta.isEmpty) {
          return FutureBuilder<List<Bus>>(
            future: DataService.getBusesConKilometrajeProximo(),
            builder: (context, proximoSnapshot) {
              if (proximoSnapshot.hasData && proximoSnapshot.data!.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.green, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kilometraje Ideal - Flota en Orden',
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Ningún bus presenta alertas o avisos por kilometraje.',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
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
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red[200]!, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Alerta de Mantenimiento por Kilometraje',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[800]),
                    ),
                    Spacer(),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${busesConAlerta.length} ${busesConAlerta.length > 1 ? "BUSES REQUIEREN" : "BUS REQUIERE"} ATENCIÓN',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Los siguientes buses han superado su kilometraje ideal y necesitan mantenimiento inmediato.',
                  style: TextStyle(fontSize: 13, color: Colors.red[700]),
                ),
                SizedBox(height: 16),
                ...busesConAlerta.map((bus) => _buildBusAlertaItem(bus)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBusAlertaItem(Bus bus) {
    final kmActual = bus.kilometraje ?? 0;
    final kmIdeal = bus.kilometrajeIdeal ?? 0;
    final diferencia = kmActual - kmIdeal;

    return BusAlertCard(
      identificador: bus.identificadorDisplay,
      marca: bus.marca,
      modelo: bus.modelo,
      patente: bus.patente,
      mensaje: 'Excedido por ${_formatNumber(diferencia)}',
      detalleActual: 'Actual: ${_formatNumber(kmActual)}',
      detalleIdeal: 'Ideal: ${_formatNumber(kmIdeal)}',
      color: Colors.red,
      isExceeded: true,
    );
  }

  Widget _buildEstadoBusesCompacto() {
    return FutureBuilder<Map<String, int>>(
      future: DataService.getEstadisticas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
              height: 80, child: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Container(
            height: 80,
            child: Center(
                child: Text('Error al cargar estadísticas: ${snapshot.error}')),
          );
        }

        final stats = snapshot.data ?? {};
        return Row(
          children: [
            Text(
              'Estado de la Flota:',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800]),
            ),
            SizedBox(width: 24),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                      child: StatCard(
                    title: 'Disponibles',
                    value: (stats['disponibles'] ?? 0).toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  )),
                  SizedBox(width: 12),
                  Expanded(
                      child: StatCard(
                    title: 'En Reparación',
                    value: (stats['enReparacion'] ?? 0).toString(),
                    icon: Icons.build,
                    color: Colors.orange,
                  )),
                  SizedBox(width: 12),
                  Expanded(
                      child: StatCard(
                    title: 'Fuera Servicio',
                    value: (stats['fueraServicio'] ?? 0).toString(),
                    icon: Icons.cancel,
                    color: Colors.red,
                  )),
                ],
              ),
            ),
            SizedBox(width: 24),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: Icon(Icons.refresh, size: 16),
              label: Text('Actualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRevisionTecnicaVencidaCard(List<Bus> busesVencidas) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.error, color: Colors.red, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revisión Técnica Vencida',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${busesVencidas.length} ${busesVencidas.length == 1 ? 'bus' : 'buses'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            Expanded(
              child: busesVencidas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              size: 48, color: Colors.green),
                          SizedBox(height: 12),
                          Text(
                            'Sin revisiones vencidas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.green[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '¡Todo en orden!',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: busesVencidas.length,
                      itemBuilder: (context, index) {
                        final bus = busesVencidas[index];
                        return RevisionTecnicaCard(
                          identificador: bus.identificadorDisplay,
                          marca: bus.marca,
                          modelo: bus.modelo,
                          mensaje:
                              'Vencida hace ${-bus.diasParaVencimientoRevision} días',
                          color: Colors.red,
                          badge: 'CRÍTICO',
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevisionTecnicaProximaCard(List<Bus> busesProximasVencer) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.warning, color: Colors.orange, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Próximas a Vencer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${busesProximasVencer.length} ${busesProximasVencer.length == 1 ? 'bus' : 'buses'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            Expanded(
              child: busesProximasVencer.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              size: 48, color: Colors.green),
                          SizedBox(height: 12),
                          Text(
                            'Sin vencimientos próximos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.green[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Todo bajo control',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: busesProximasVencer.length,
                      itemBuilder: (context, index) {
                        final bus = busesProximasVencer[index];
                        return RevisionTecnicaCard(
                          identificador: bus.identificadorDisplay,
                          marca: bus.marca,
                          modelo: bus.modelo,
                          mensaje:
                              'Vence en ${bus.diasParaVencimientoRevision} días',
                          color: Colors.orange,
                          badge: 'URGENTE',
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
