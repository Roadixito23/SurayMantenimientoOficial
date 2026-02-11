import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/bus.dart';
import '../../../models/mantenimiento_preventivo.dart';
import '../../../main.dart';

/// Diálogo para ver el estado detallado de mantenimientos de un bus
/// Muestra qué mantenimientos están vencidos, próximos o al día
class VerEstadoMantenimientoDialog extends StatelessWidget {
  final Bus bus;

  const VerEstadoMantenimientoDialog({
    Key? key,
    required this.bus,
  }) : super(key: key);

  static Future<void> show(BuildContext context, {required Bus bus}) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    
    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (context) => VerEstadoMantenimientoDialog(bus: bus),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _MobileBottomSheet(bus: bus),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SurayColors.naranjaQuemado.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.analytics,
              color: SurayColors.naranjaQuemado,
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado de Mantenimientos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  bus.identificadorDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Container(
        width: 550,
        constraints: BoxConstraints(maxHeight: 600),
        child: _buildContent(context),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final estados = bus.estadosMantenimiento;
    final repuestosVencidos = bus.repuestosProximosVencer;
    
    if (bus.kilometraje == null) {
      return _buildNoKilometrajeWidget();
    }
    
    if (bus.mantenimientoPreventivo == null && repuestosVencidos.isEmpty) {
      return _buildNoMantenimientoWidget();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Resumen del bus
          _buildResumenBus(),
          SizedBox(height: 16),
          
          // Filtros críticos (aceite, aire, combustible)
          if (estados.isNotEmpty) ...[
            _buildSeccionTitulo('Filtros Críticos', Icons.filter_alt),
            SizedBox(height: 8),
            ...estados.map((estado) => _buildEstadoFiltroCard(estado)),
            SizedBox(height: 16),
          ],
          
          // Repuestos próximos a vencer o vencidos
          if (repuestosVencidos.isNotEmpty) ...[
            _buildSeccionTitulo('Repuestos con Alerta', Icons.build),
            SizedBox(height: 8),
            ...repuestosVencidos.map((r) => _buildRepuestoCard(r)),
            SizedBox(height: 16),
          ],
          
          // Revisión técnica
          _buildSeccionTitulo('Revisión Técnica', Icons.assignment),
          SizedBox(height: 8),
          _buildRevisionTecnicaCard(),
        ],
      ),
    );
  }

  Widget _buildNoKilometrajeWidget() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.speed,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Kilometraje no registrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Para calcular el estado de los mantenimientos, primero debe registrar el kilometraje actual del bus.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMantenimientoWidget() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green,
          ),
          SizedBox(height: 16),
          Text(
            'Sin alertas de mantenimiento',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Este bus no tiene mantenimientos configurados o todos están al día.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenBus() {
    final formatador = NumberFormat("#,##0", "es_CL");
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SurayColors.azulMarinoProfundo,
            SurayColors.azulMarinoClaro,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.directions_bus, color: Colors.white, size: 40),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${bus.marca} ${bus.modelo} (${bus.anio})',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kilometraje actual: ${formatador.format(bus.kilometraje ?? 0)} km',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildAlertasResumen(),
        ],
      ),
    );
  }

  Widget _buildAlertasResumen() {
    final vencidos = bus.mantenimientosCriticos
        .where((e) => e.urgencia == NivelUrgencia.critico)
        .length;
    final urgentes = bus.mantenimientosCriticos
        .where((e) => e.urgencia == NivelUrgencia.urgente)
        .length;

    if (vencidos == 0 && urgentes == 0) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'Al día',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (vencidos > 0)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$vencidos vencido${vencidos > 1 ? 's' : ''}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        if (urgentes > 0) ...[
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: SurayColors.naranjaQuemado,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$urgentes próximo${urgentes > 1 ? 's' : ''}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSeccionTitulo(String titulo, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: SurayColors.azulMarinoProfundo),
        SizedBox(width: 8),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: SurayColors.azulMarinoProfundo,
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoFiltroCard(EstadoMantenimiento estado) {
    final formatador = NumberFormat("#,##0", "es_CL");
    
    Color color;
    IconData icon;
    String estadoLabel;
    
    switch (estado.urgencia) {
      case NivelUrgencia.critico:
        color = Colors.red;
        icon = Icons.error;
        estadoLabel = 'VENCIDO';
        break;
      case NivelUrgencia.urgente:
        color = SurayColors.naranjaQuemado;
        icon = Icons.warning;
        estadoLabel = 'PRÓXIMO';
        break;
      case NivelUrgencia.proximo:
        color = Colors.amber;
        icon = Icons.schedule;
        estadoLabel = 'Programado';
        break;
      case NivelUrgencia.normal:
        color = Colors.green;
        icon = Icons.check_circle;
        estadoLabel = 'Al día';
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        estado.descripcion,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        estadoLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                if (estado.proximoMantenimientoKm != null)
                  Text(
                    'Próximo cambio: ${formatador.format(estado.proximoMantenimientoKm!)} km',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                if (estado.kmRestantes < 0)
                  Text(
                    'Excedido por ${formatador.format(estado.kmRestantes.abs())} km',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else if (estado.kmRestantes > 0)
                  Text(
                    'Faltan ${formatador.format(estado.kmRestantes)} km',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                if (estado.diasRestantes < 0)
                  Text(
                    'Vencido hace ${estado.diasRestantes.abs()} días',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else if (estado.diasRestantes <= 30)
                  Text(
                    'Faltan ${estado.diasRestantes} días',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepuestoCard(repuesto) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SurayColors.naranjaQuemado.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SurayColors.naranjaQuemado.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.build, color: SurayColors.naranjaQuemado),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Repuesto próximo a vencer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (repuesto.proximoCambio != null)
                  Text(
                    'Vence: ${DateFormat('dd/MM/yyyy').format(repuesto.proximoCambio!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevisionTecnicaCard() {
    Color color;
    IconData icon;
    String estadoLabel;
    String detalle;

    if (bus.fechaRevisionTecnica == null) {
      color = Colors.grey;
      icon = Icons.help_outline;
      estadoLabel = 'No registrada';
      detalle = 'Registre la fecha de revisión técnica';
    } else if (bus.revisionTecnicaVencida) {
      color = Colors.red;
      icon = Icons.error;
      estadoLabel = 'VENCIDA';
      detalle = 'Venció el ${DateFormat('dd/MM/yyyy').format(bus.fechaRevisionTecnica!)}';
    } else if (bus.revisionTecnicaProximaAVencer) {
      color = SurayColors.naranjaQuemado;
      icon = Icons.warning;
      estadoLabel = 'Próxima a vencer';
      detalle = 'Vence en ${bus.diasParaVencimientoRevision} días';
    } else {
      color = Colors.green;
      icon = Icons.check_circle;
      estadoLabel = 'Vigente';
      detalle = 'Vence el ${DateFormat('dd/MM/yyyy').format(bus.fechaRevisionTecnica!)}';
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Revisión Técnica',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        estadoLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  detalle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet para móvil
class _MobileBottomSheet extends StatelessWidget {
  final Bus bus;

  const _MobileBottomSheet({required this.bus});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: SurayColors.naranjaQuemado.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.analytics,
                    color: SurayColors.naranjaQuemado,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado de Mantenimientos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        bus.identificadorDisplay,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: VerEstadoMantenimientoDialog(bus: bus)._buildContent(context),
            ),
          ),
        ],
      ),
    );
  }
}
