import 'package:flutter/material.dart';

// =====================================================================
// === DASHBOARD WIDGETS - Widgets compartidos para layouts ============
// =====================================================================
// Widgets reutilizables para las diferentes versiones del dashboard

/// Card de estadística (usado en ambos layouts)
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool compact;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Row(
          children: [
            Icon(icon, size: compact ? 20 : 24, color: color),
            SizedBox(width: compact ? 8 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: compact ? 16 : 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: compact ? 10 : 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de alerta de bus (tanto rojas como naranjas)
class BusAlertCard extends StatelessWidget {
  final String identificador;
  final String marca;
  final String modelo;
  final String patente;
  final String mensaje;
  final String detalleActual;
  final String detalleIdeal;
  final Color color;
  final bool isExceeded; // true si está excedido, false si es próximo

  const BusAlertCard({
    Key? key,
    required this.identificador,
    required this.marca,
    required this.modelo,
    required this.patente,
    required this.mensaje,
    required this.detalleActual,
    required this.detalleIdeal,
    required this.color,
    required this.isExceeded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.directions_bus, color: color.withOpacity(0.8)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$identificador ($patente)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '$marca $modelo',
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
                mensaje,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
              Text(
                detalleActual,
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
              Text(
                detalleIdeal,
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
            ],
          )
        ],
      ),
    );
  }
}

/// Card de revisión técnica (para lista de buses con vencimientos)
class RevisionTecnicaCard extends StatelessWidget {
  final String identificador;
  final String marca;
  final String modelo;
  final String mensaje;
  final Color color;
  final String badge;

  const RevisionTecnicaCard({
    Key? key,
    required this.identificador,
    required this.marca,
    required this.modelo,
    required this.mensaje,
    required this.color,
    required this.badge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            badge == 'CRÍTICO' ? Icons.error : Icons.warning,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          identificador,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: color),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    mensaje,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              '$marca $modelo',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badge,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
