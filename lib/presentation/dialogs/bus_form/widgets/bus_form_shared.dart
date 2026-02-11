import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/bus.dart';
import '../../../../models/mantenimiento_preventivo.dart';
import '../../../../models/tipo_mantenimiento_personalizado.dart';
import '../../../../services/chilean_utils.dart';

/// Widgets y funciones compartidas entre desktop y mobile layouts del formulario de bus
class BusFormShared {
  /// Valida si la patente es única
  static Future<bool> validarPatenteUnica(String patente, String? busIdActual,
      Future<List<Bus>> Function() getBuses) async {
    try {
      final buses = await getBuses();
      return !buses.any((b) =>
          b.patente.toUpperCase() == patente.toUpperCase() &&
          b.id != busIdActual);
    } catch (e) {
      return true;
    }
  }

  /// Valida si el identificador es único
  static Future<bool> validarIdentificadorUnico(String identificador,
      String? busIdActual, Future<List<Bus>> Function() getBuses) async {
    if (identificador.isEmpty) return true;

    try {
      final buses = await getBuses();
      return !buses.any((b) =>
          (b.identificador?.toUpperCase() ?? '') ==
              identificador.toUpperCase() &&
          b.id != busIdActual);
    } catch (e) {
      return true;
    }
  }

  /// Builds el widget de estado de revisión técnica
  static Widget buildRevisionTecnicaStatus(DateTime? fechaRevisionTecnica) {
    if (fechaRevisionTecnica == null) return SizedBox.shrink();

    final diasRestantes =
        fechaRevisionTecnica.difference(DateTime.now()).inDays;
    Color color;
    String mensaje;
    IconData icon;

    if (diasRestantes < 0) {
      color = Colors.red;
      mensaje = 'VENCIDA hace ${-diasRestantes} días';
      icon = Icons.error;
    } else if (diasRestantes <= 30) {
      color = Colors.orange;
      mensaje = 'Vence en $diasRestantes días';
      icon = Icons.warning;
    } else {
      color = Colors.green;
      mensaje = 'Vigente ($diasRestantes días restantes)';
      icon = Icons.check_circle;
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Text(
            mensaje,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds el estado de mantenimiento actual (para modo edición)
  static Widget buildEstadoMantenimientoActual(Bus bus) {
    if (bus.mantenimientoPreventivo == null) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Este vehículo aún no tiene configuración de mantenimiento. Se configurará automáticamente al guardar.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final estadisticas = bus.estadisticasMantenimientosPorTipo;
    final totalMantenimientos = bus.totalMantenimientosRealizados;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.green[700]),
              SizedBox(width: 8),
              Text(
                'Estadísticas de Mantenimiento',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green[700]),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text('Total de mantenimientos realizados: $totalMantenimientos'),
          SizedBox(height: 8),
          if (estadisticas.isNotEmpty) ...[
            Text('Distribución por tipo:'),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: estadisticas.entries.map((entry) {
                if (entry.value == 0) return SizedBox.shrink();

                Color color;
                IconData icon;
                String label;

                switch (entry.key) {
                  case TipoMantenimiento.correctivo:
                    color = Color(0xFFE53E3E);
                    icon = Icons.handyman;
                    label = 'Correctivo';
                    break;
                  case TipoMantenimiento.rutinario:
                    color = Color(0xFF3182CE);
                    icon = Icons.schedule;
                    label = 'Rutinario';
                    break;
                  case TipoMantenimiento.preventivo:
                    color = Color(0xFF38A169);
                    icon = Icons.build_circle;
                    label = 'Preventivo';
                    break;
                }

                return Chip(
                  avatar: Icon(icon, size: 14, color: Colors.white),
                  label: Text(
                    '$label: ${entry.value}',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  backgroundColor: color,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
          if (bus.ultimoMantenimiento != null) ...[
            SizedBox(height: 12),
            Text(
              'Último mantenimiento: ${bus.ultimoMantenimiento!.descripcionTipo} '
              '(${ChileanUtils.formatDate(bus.ultimoMantenimiento!.fechaUltimoCambio)})',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}

/// Clase para almacenar los datos del formulario
class BusFormData {
  TextEditingController identificadorController;
  TextEditingController patenteController;
  TextEditingController marcaController;
  TextEditingController modeloController;
  TextEditingController anioController;
  TextEditingController numeroChasisController;
  TextEditingController numeroMotorController;
  TextEditingController capacidadPasajerosController;
  TextEditingController ubicacionController;
  TextEditingController kilometrajeController;
  TextEditingController promedioKmController;
  TextEditingController fechaRevisionController;
  EstadoBus estado;
  DateTime? fechaRevisionTecnica;
  TipoMotor tipoMotor;

  BusFormData({
    required this.identificadorController,
    required this.patenteController,
    required this.marcaController,
    required this.modeloController,
    required this.anioController,
    required this.numeroChasisController,
    required this.numeroMotorController,
    required this.capacidadPasajerosController,
    required this.ubicacionController,
    required this.kilometrajeController,
    required this.promedioKmController,
    required this.fechaRevisionController,
    required this.estado,
    this.fechaRevisionTecnica,
    required this.tipoMotor,
  });

  factory BusFormData.fromBus(Bus? bus) {
    return BusFormData(
      identificadorController:
          TextEditingController(text: bus?.identificador ?? ''),
      patenteController: TextEditingController(text: bus?.patente ?? ''),
      marcaController: TextEditingController(text: bus?.marca ?? ''),
      modeloController: TextEditingController(text: bus?.modelo ?? ''),
      anioController: TextEditingController(text: bus?.anio.toString() ?? ''),
      numeroChasisController:
          TextEditingController(text: bus?.numeroChasis ?? ''),
      numeroMotorController:
          TextEditingController(text: bus?.numeroMotor ?? ''),
      capacidadPasajerosController: TextEditingController(
          text: bus?.capacidadPasajeros.toString() ?? '40'),
      ubicacionController:
          TextEditingController(text: bus?.ubicacionActual ?? ''),
      kilometrajeController:
          TextEditingController(text: bus?.kilometraje?.toString() ?? ''),
      promedioKmController: TextEditingController(
          text: bus?.promedioKmMensuales?.toString() ?? '5000'),
      fechaRevisionController: TextEditingController(
          text: bus?.fechaRevisionTecnica != null
              ? '${bus!.fechaRevisionTecnica!.day.toString().padLeft(2, '0')}/${bus.fechaRevisionTecnica!.month.toString().padLeft(2, '0')}/${(bus.fechaRevisionTecnica!.year % 100).toString().padLeft(2, '0')}'
              : ''),
      estado: bus?.estado ?? EstadoBus.disponible,
      fechaRevisionTecnica: bus?.fechaRevisionTecnica,
      tipoMotor: bus?.mantenimientoPreventivo?.tipoMotor ?? TipoMotor.diesel,
    );
  }

  void dispose() {
    identificadorController.dispose();
    patenteController.dispose();
    marcaController.dispose();
    modeloController.dispose();
    anioController.dispose();
    numeroChasisController.dispose();
    numeroMotorController.dispose();
    capacidadPasajerosController.dispose();
    ubicacionController.dispose();
    kilometrajeController.dispose();
    promedioKmController.dispose();
    fechaRevisionController.dispose();
  }
}
