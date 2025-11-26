import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/data_service.dart';
import '../models/bus.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _initializeDataIfNeeded();
  }

  void _initializeDataIfNeeded() async {
    final buses = await DataService.getBuses();
    if (buses.isEmpty) {
      await DataService.initializeSampleData();
      if (mounted) {
        setState(() {});
      }
    }
  }

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
          setState(() {});
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEstadoBusesCompacto(),
            SizedBox(height: 20),

            // Muestra la alerta ROJA para buses VENCIDOS
            _buildAlertasKilometrajeVencido(),
            SizedBox(height: 20),

            // ✅ PASO 1: AÑADIR EL NUEVO WIDGET DE AVISO
            // Muestra el aviso NARANJA para buses PRÓXIMOS A MANTENIMIENTO
            _buildAlertasKilometrajeProximo(),
            SizedBox(height: 20),

            // Contenido principal - Una sola columna para revisión técnica
            Expanded(
              child: FutureBuilder<List<List<Bus>>>(
                future: Future.wait([
                  DataService.getBusesRevisionTecnicaProximaVencer(),
                  DataService.getBusesRevisionTecnicaVencida(),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Card(child: Center(child: CircularProgressIndicator()));
                  }
                  final busesProximasVencer = snapshot.data?[0] ?? [];
                  final busesVencidas = snapshot.data?[1] ?? [];
                  return _buildAlertasRevisionTecnicaCard(busesProximasVencer, busesVencidas);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ PASO 2: CREAR EL NUEVO WIDGET PARA LOS AVISOS
  Widget _buildAlertasKilometrajeProximo() {
    return FutureBuilder<List<Bus>>(
      future: DataService.getBusesConKilometrajeProximo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData || snapshot.data!.isEmpty) {
          // Si no hay buses en esta categoría, no muestra nada.
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
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Aviso de Mantenimiento Próximo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[800]),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${busesConAviso.length} ${busesConAviso.length > 1 ? "BUSES" : "BUS"} REQUIEREN ATENCIÓN',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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

  // ✅ PASO 3: CREAR EL ITEM PARA LA LISTA DE AVISOS
  Widget _buildBusAvisoItem(Bus bus) {
    final kmActual = bus.kilometraje ?? 0;
    final kmIdeal = bus.kilometrajeIdeal ?? 0;
    final diferencia = kmIdeal - kmActual;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.directions_bus, color: Colors.orange[700]),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${bus.identificadorDisplay} (${bus.patente})',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '${bus.marca} ${bus.modelo}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Faltan ${_formatNumber(diferencia)} km',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800], fontSize: 13),
              ),
              Text(
                'Actual: ${_formatNumber(kmActual)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
              Text(
                'Ideal: ${_formatNumber(kmIdeal)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
            ],
          )
        ],
      ),
    );
  }


  // --- Widgets existentes (con pequeñas modificaciones o sin cambios) ---

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
              child: Text('Error al cargar alertas de kilometraje: ${snapshot.error}'),
            ),
          );
        }

        final busesConAlerta = snapshot.data ?? [];

        // ✅ MODIFICACIÓN: Ahora el panel verde solo aparece si no hay alertas de NINGÚN tipo (rojas o naranjas)
        if (busesConAlerta.isEmpty) {
          return FutureBuilder<List<Bus>>(
            future: DataService.getBusesConKilometrajeProximo(),
            builder: (context, proximoSnapshot) {
              if (proximoSnapshot.hasData && proximoSnapshot.data!.isEmpty) {
                // Solo muestra el panel verde si tampoco hay avisos naranjas
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
                      Icon(Icons.check_circle_outline, color: Colors.green, size: 24),
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
              // Si hay avisos naranjas, no muestra el panel verde.
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[800]),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${busesConAlerta.length} ${busesConAlerta.length > 1 ? "BUSES REQUIEREN" : "BUS REQUIERE"} ATENCIÓN',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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

  // ... (El resto de los métodos como _buildBusAlertaItem, _buildEstadoBusesCompacto, etc., no necesitan cambios)
  Widget _buildBusAlertaItem(Bus bus) {
    final kmActual = bus.kilometraje ?? 0;
    final kmIdeal = bus.kilometrajeIdeal ?? 0;
    final diferencia = kmActual - kmIdeal;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.directions_bus, color: Colors.red[700]),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${bus.identificadorDisplay} (${bus.patente})',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '${bus.marca} ${bus.modelo}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Excedido por ${_formatNumber(diferencia)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[800], fontSize: 13),
              ),
              Text(
                'Actual: ${_formatNumber(kmActual)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
              Text(
                'Ideal: ${_formatNumber(kmIdeal)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEstadoBusesCompacto() {
    return FutureBuilder<Map<String, int>>(
      future: DataService.getEstadisticas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(height: 80, child: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Container(
            height: 80,
            child: Center(child: Text('Error al cargar estadísticas: ${snapshot.error}')),
          );
        }

        final stats = snapshot.data ?? {};
        return Row(
          children: [
            Text(
              'Estado de la Flota:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            SizedBox(width: 24),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildStatCard('Disponibles', (stats['disponibles'] ?? 0).toString(), Icons.check_circle, Colors.green)),
                  SizedBox(width: 12),
                  Expanded(child: _buildStatCard('En Reparación', (stats['enReparacion'] ?? 0).toString(), Icons.build, Colors.orange)),
                  SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Fuera Servicio', (stats['fueraServicio'] ?? 0).toString(), Icons.cancel, Colors.red)),
                ],
              ),
            ),
            SizedBox(width: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: color),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusesEnReparacionCard(List<Bus> busesEnReparacion) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: Colors.orange, size: 24),
                SizedBox(width: 12),
                Text(
                  'Buses en Reparación',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: busesEnReparacion.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.green),
                    SizedBox(height: 16),
                    Text('No hay buses en reparación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    SizedBox(height: 8),
                    Text('Toda la flota está operativa', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: busesEnReparacion.length,
                itemBuilder: (context, index) {
                  final bus = busesEnReparacion[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(Icons.build, color: Colors.orange, size: 24),
                      title: Text('${bus.identificadorDisplay}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text('${bus.marca} ${bus.modelo} (${bus.anio})'),
                          if (bus.ubicacionActual != null)
                            Text('Ubicación: ${bus.ubicacionActual}'),
                          if (bus.totalMantenimientosRealizados > 0)
                            Text('Mantenimientos realizados: ${bus.totalMantenimientosRealizados}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'EN REPARACIÓN',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertasRevisionTecnicaCard(List<Bus> busesProximasVencer, List<Bus> busesVencidas) {
    final totalAlertas = busesProximasVencer.length + busesVencidas.length;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment_turned_in, color: Colors.red, size: 24),
                SizedBox(width: 12),
                Text(
                  'Revisión Técnica - Estado Normativo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: totalAlertas == 0
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.green),
                    SizedBox(height: 16),
                    Text('Todas las revisiones al día', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    SizedBox(height: 8),
                    Text('Cumplimiento normativo 100%', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              )
                  : ListView(
                children: [
                  ...busesVencidas.map((bus) => Card(
                    color: Colors.red[50],
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(Icons.error, color: Colors.red, size: 24),
                      title: Text(bus.identificadorDisplay, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text('VENCIDA hace ${-bus.diasParaVencimientoRevision} días'),
                          Text('${bus.marca} ${bus.modelo}'),
                        ],
                      ),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('CRÍTICO', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  )),
                  ...busesProximasVencer.map((bus) => Card(
                    color: Colors.orange[50],
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(Icons.warning, color: Colors.orange, size: 24),
                      title: Text(bus.identificadorDisplay, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text('Vence en ${bus.diasParaVencimientoRevision} días'),
                          Text('${bus.marca} ${bus.modelo}'),
                        ],
                      ),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('URGENTE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}