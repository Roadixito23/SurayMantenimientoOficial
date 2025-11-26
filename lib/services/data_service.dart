import 'package:flutter/material.dart';
import '../models/bus.dart';
import '../models/mantencion.dart';
import '../models/repuesto.dart';
import '../models/repuesto_asignado.dart';
import '../models/reporte_diario.dart';
import '../models/mantenimiento_preventivo.dart';
import '../models/tipo_mantenimiento_personalizado.dart';
import 'firebase_service.dart';

// ✅ CONFIGURACIÓN DE MANTENIMIENTO MOVILIDA AQUÍ PARA SER ACCESIBLE GLOBALMENTE
class MantenimientoConfig {
  static int kilometrajeIdeal = 10000; // km para mantenimiento ideal
  static int diasFechaIdeal = 30; // días para fecha ideal de mantenimiento

  // El cálculo ahora se puede hacer desde cualquier parte de la app.
  static double calcularKilometrajeIdeal(Bus bus) {
    final ultimoKm = bus.kilometraje ?? 0;
    return ultimoKm + kilometrajeIdeal;
  }

  static DateTime calcularFechaIdeal(Bus bus) {
    if (bus.ultimoMantenimiento != null) {
      return bus.ultimoMantenimiento!.fechaUltimoCambio.add(Duration(days: diasFechaIdeal));
    }
    return DateTime.now().add(Duration(days: diasFechaIdeal));
  }
}


class DataService {
  // =============================================================================
  // ✅ NUEVO MÉTODO PARA ALERTAS DE KILOMETRAJE
  // =============================================================================

  /// Obtiene todos los buses cuyo kilometraje actual supera el ideal.
  static Future<List<Bus>> getBusesConKilometrajeVencido() async {
    final buses = await getBuses();
    return buses.where((bus) {
      final kmActual = bus.kilometraje;
      final kmIdeal = bus.kilometrajeIdeal;
      if (kmActual != null && kmIdeal != null && kmIdeal > 0) {
        return kmActual > kmIdeal;
      }
      return false;
    }).toList();
  }

  static Future<List<Bus>> getBusesConKilometrajeProximo() async {
    final buses = await getBuses();
    final umbral = MantenimientoConfig.kilometrajeIdeal * 0.2;

    return buses.where((bus) {
      final kmActual = bus.kilometraje;
      final kmIdeal = bus.kilometrajeIdeal;

      if (kmActual != null && kmIdeal != null && kmIdeal > 0) {
        final diferencia = kmIdeal - kmActual;
        return diferencia >= 0 && diferencia < umbral;
      }
      return false;
    }).toList();
  }

  // =============================================================================
  // ✅ MÉTODOS PARA TIPOS DE MANTENIMIENTO PERSONALIZADOS
  // =============================================================================

  /// Obtiene todos los tipos de mantenimiento personalizados
  static Future<List<TipoMantenimientoPersonalizado>> getTiposMantenimientoPersonalizados() =>
      FirebaseService.getTiposMantenimientoPersonalizados();

  /// Obtiene tipos activos ordenados por frecuencia de uso
  static Future<List<TipoMantenimientoPersonalizado>> getTiposMantenimientoActivos() async {
    final tipos = await getTiposMantenimientoPersonalizados();
    final activos = tipos.where((t) => t.activo).toList();

    // Ordenar por frecuencia de uso (más usados primero)
    activos.sort((a, b) => b.vecesUsado.compareTo(a.vecesUsado));

    return activos;
  }

  /// Obtiene tipos por categoría base
  static Future<List<TipoMantenimientoPersonalizado>> getTiposPorCategoria(TipoMantenimiento categoria) async {
    final tipos = await getTiposMantenimientoActivos();
    return tipos.where((t) => t.tipoBase == categoria).toList();
  }

  /// Busca tipos por título (para autocompletado)
  static Future<List<TipoMantenimientoPersonalizado>> buscarTiposPorTitulo(String query) async {
    if (query.isEmpty) return [];

    final tipos = await getTiposMantenimientoActivos();
    final queryLower = query.toLowerCase();

    return tipos.where((t) =>
    t.titulo.toLowerCase().contains(queryLower) ||
        (t.descripcion?.toLowerCase().contains(queryLower) ?? false)
    ).toList();
  }

  /// Agrega un nuevo tipo personalizado
  static Future<String> addTipoMantenimientoPersonalizado(TipoMantenimientoPersonalizado tipo) =>
      FirebaseService.addTipoMantenimientoPersonalizado(tipo);

  /// Actualiza un tipo existente
  static Future<void> updateTipoMantenimientoPersonalizado(TipoMantenimientoPersonalizado tipo) =>
      FirebaseService.updateTipoMantenimientoPersonalizado(tipo);

  /// Incrementa el contador de uso de un tipo
  static Future<void> incrementarUsoTipo(String tipoId) async {
    final tipos = await getTiposMantenimientoPersonalizados();
    final tipo = tipos.firstWhere((t) => t.id == tipoId);
    final tipoActualizado = tipo.incrementarUso();
    await updateTipoMantenimientoPersonalizado(tipoActualizado);
  }

  /// Crea o reutiliza un tipo personalizado basado en título
  static Future<TipoMantenimientoPersonalizado> crearOreutilizarTipo({
    required String titulo,
    String? descripcion,
    required TipoMantenimiento tipoBase,
  }) async {
    // Buscar si ya existe un tipo con ese título
    final tiposExistentes = await getTiposMantenimientoActivos();

    try {
      final tipoExistente = tiposExistentes.firstWhere(
            (t) => t.titulo.toLowerCase() == titulo.toLowerCase() && t.tipoBase == tipoBase,
      );

      // Si existe, incrementar uso y retornar
      await incrementarUsoTipo(tipoExistente.id);
      return tipoExistente.incrementarUso();
    } catch (e) {
      // Si no existe, crear nuevo
      final nuevoTipo = TipoMantenimientoPersonalizado(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        titulo: titulo.trim(),
        descripcion: descripcion?.trim(),
        tipoBase: tipoBase,
        fechaCreacion: DateTime.now(),
        vecesUsado: 1,
        activo: true,
      );

      await addTipoMantenimientoPersonalizado(nuevoTipo);
      return nuevoTipo;
    }
  }

  // =============================================================================
  // MÉTODOS PARA BUSES
  // =============================================================================

  static Future<List<Bus>> getBuses() => FirebaseService.getBuses();

  static Future<String> addBus(Bus bus) async {
    // Crear mantenimiento preventivo si no existe
    Bus busConMantenimiento = bus;
    if (bus.mantenimientoPreventivo == null) {
      final mantenimientoPreventivo = MantenimientoPreventivo(
        busId: bus.id,
        tipoMotor: TipoMotor.diesel, // Por defecto diésel para buses
        fechaCreacion: DateTime.now(),
      );

      busConMantenimiento = bus.copyWith(
        mantenimientoPreventivo: mantenimientoPreventivo,
        promedioKmMensuales: 2000.0, // Valor por defecto
        ultimaActualizacionKm: DateTime.now(),
        // ✅ Asignar kilometraje ideal inicial al crear un bus
        kilometrajeIdeal: (bus.kilometraje ?? 0) + MantenimientoConfig.kilometrajeIdeal,
      );
    }

    final busId = await FirebaseService.addBus(busConMantenimiento);

    // Asignar repuestos predeterminados al bus nuevo
    await _asignarRepuestosPredeterminados(busId);

    return busId;
  }

  static Future<void> updateBus(Bus updatedBus) async {
    final originalBus = await getBusById(updatedBus.id);

    if (originalBus != null) {
      // Crea la versión final del bus a guardar.
      // Esto preserva el 'kilometrajeIdeal' si no fue proporcionado en el formulario de actualización,
      // evitando que se borre accidentalmente.
      final busToSave = updatedBus.copyWith(
        kilometrajeIdeal: updatedBus.kilometrajeIdeal ?? originalBus.kilometrajeIdeal,
      );
      await FirebaseService.updateBus(busToSave);
    } else {
      // Si por alguna razón el bus original no existe, guarda el actualizado tal cual.
      await FirebaseService.updateBus(updatedBus);
    }
  }

  static Future<void> deleteBus(String id) => FirebaseService.deleteBus(id);

  static Future<Bus?> getBusById(String id) => FirebaseService.getBusById(id);

  // =============================================================================
  // MÉTODOS PARA MANTENIMIENTO PREVENTIVO - CORREGIDOS
  // =============================================================================

  /// Actualiza el kilometraje de un bus y recalcula el promedio mensual
  static Future<void> actualizarKilometraje(String busId, double nuevoKilometraje) async {
    final bus = await getBusById(busId);
    if (bus == null) return;

    final promedioActualizado = bus.calcularPromedioKmMensuales();

    final busActualizado = bus.copyWith(
      kilometraje: nuevoKilometraje,
      promedioKmMensuales: promedioActualizado,
      ultimaActualizacionKm: DateTime.now(),
    );

    await updateBus(busActualizado);
  }

  /// ✅ CORREGIDO: Registra un mantenimiento personalizado SIN DUPLICAR
  static Future<void> registrarMantenimientoPersonalizado({
    required String busId,
    required String tituloMantenimiento,
    String? descripcionMantenimiento,
    required TipoMantenimiento tipoMantenimiento,
    required double kilometrajeActual,
    DateTime? fechaMantenimiento,
    String? tecnicoResponsable,
    String? observaciones,
    String? marcaRepuesto,
  }) async {
    final bus = await getBusById(busId);
    if (bus == null) throw Exception('Bus no encontrado');

    final fechaCambio = fechaMantenimiento ?? DateTime.now();

    final tipoPersonalizado = await crearOreutilizarTipo(
      titulo: tituloMantenimiento,
      descripcion: descripcionMantenimiento,
      tipoBase: tipoMantenimiento,
    );

    final nuevoRegistro = RegistroMantenimiento(
      id: '${busId}_custom_${fechaCambio.millisecondsSinceEpoch}',
      fechaUltimoCambio: fechaCambio,
      kilometrajeUltimoCambio: kilometrajeActual,
      tecnicoResponsable: tecnicoResponsable,
      observaciones: observaciones,
      marcaRepuesto: marcaRepuesto,
      tipoMantenimientoPersonalizadoId: tipoPersonalizado.id,
      tipoMantenimiento: tipoMantenimiento,
      tituloPersonalizado: tituloMantenimiento,
    );

    MantenimientoPreventivo mantenimientoActualizado;
    if (bus.mantenimientoPreventivo != null) {
      final nuevosRegistros = List<RegistroMantenimiento>.from(
          bus.mantenimientoPreventivo!.historialMantenimientos
      );
      nuevosRegistros.add(nuevoRegistro);
      mantenimientoActualizado = bus.mantenimientoPreventivo!.copyWith(
        historialMantenimientos: nuevosRegistros,
      );
    } else {
      mantenimientoActualizado = MantenimientoPreventivo(
        busId: busId,
        tipoMotor: TipoMotor.diesel,
        historialMantenimientos: [nuevoRegistro],
        fechaCreacion: fechaCambio,
      );
    }

    // --- SE ELIMINÓ LA CREACIÓN DEL OBJETO 'Mantencion' ANTIGUO ---
    // Ya no se crea una entrada duplicada en historialMantenciones.

    final nuevoKmIdeal = kilometrajeActual + MantenimientoConfig.kilometrajeIdeal;

    final busActualizado = bus.copyWith(
      kilometraje: kilometrajeActual,
      kilometrajeIdeal: nuevoKmIdeal,
      mantenimientoPreventivo: mantenimientoActualizado,
      // La siguiente línea se elimina para no añadir el duplicado:
      // historialMantenciones: nuevasMantencionesHistorial,
      ultimaActualizacionKm: fechaCambio,
    );

    await updateBus(busActualizado);
    print('✅ Mantenimiento registrado (sin duplicados) y kilometraje ideal actualizado para el bus $busId');
  }

  /// ✅ CORREGIDO: Registra un mantenimiento preventivo SIN DUPLICAR
  static Future<void> registrarMantenimientoPreventivo({
    required String busId,
    required TipoFiltro tipoFiltro,
    required double kilometrajeActual,
    DateTime? fechaMantenimiento,
    String? tecnicoResponsable,
    String? observaciones,
    String? marcaRepuesto,
  }) async {
    final bus = await getBusById(busId);
    if (bus == null) throw Exception('Bus no encontrado');

    final fechaCambio = fechaMantenimiento ?? DateTime.now();

    final nuevoRegistro = RegistroMantenimiento(
      id: '${busId}_${tipoFiltro.toString()}_${fechaCambio.millisecondsSinceEpoch}',
      tipoFiltro: tipoFiltro,
      fechaUltimoCambio: fechaCambio,
      kilometrajeUltimoCambio: kilometrajeActual,
      tecnicoResponsable: tecnicoResponsable,
      observaciones: observaciones,
      marcaRepuesto: marcaRepuesto,
      tipoMantenimiento: TipoMantenimiento.preventivo,
      tituloPersonalizado: _getFiltroLabel(tipoFiltro),
    );

    MantenimientoPreventivo mantenimientoActualizado;
    if (bus.mantenimientoPreventivo != null) {
      final nuevosRegistros = List<RegistroMantenimiento>.from(
          bus.mantenimientoPreventivo!.historialMantenimientos
      );
      nuevosRegistros.add(nuevoRegistro);

      mantenimientoActualizado = bus.mantenimientoPreventivo!.copyWith(
        historialMantenimientos: nuevosRegistros,
      );
    } else {
      mantenimientoActualizado = MantenimientoPreventivo(
        busId: busId,
        tipoMotor: TipoMotor.diesel,
        historialMantenimientos: [nuevoRegistro],
        fechaCreacion: fechaCambio,
      );
    }

    // --- SE ELIMINÓ LA CREACIÓN DEL OBJETO 'Mantencion' ANTIGUO ---
    // Ya no se crea una entrada duplicada en historialMantenciones.

    final nuevoKmIdeal = kilometrajeActual + MantenimientoConfig.kilometrajeIdeal;

    final busActualizado = bus.copyWith(
      kilometraje: kilometrajeActual,
      kilometrajeIdeal: nuevoKmIdeal,
      mantenimientoPreventivo: mantenimientoActualizado,
      // La siguiente línea se elimina para no añadir el duplicado:
      // historialMantenciones: nuevasMantencionesHistorial,
      ultimaActualizacionKm: fechaCambio,
    );

    await updateBus(busActualizado);
    print('✅ Mantenimiento preventivo registrado (sin duplicados) y kilometraje ideal actualizado para el bus $busId');
  }

  static String _getDescripcionMantenimiento(TipoFiltro tipoFiltro) {
    switch (tipoFiltro) {
      case TipoFiltro.aceite:
        return 'Mantenimiento Preventivo - Cambio de Filtro de Aceite';
      case TipoFiltro.aire:
        return 'Mantenimiento Preventivo - Cambio de Filtro de Aire';
      case TipoFiltro.combustible:
        return 'Mantenimiento Preventivo - Cambio de Filtro de Combustible';
    }
  }

  static String _getFiltroLabel(TipoFiltro filtro) {
    switch (filtro) {
      case TipoFiltro.aceite:
        return 'Filtro de Aceite';
      case TipoFiltro.aire:
        return 'Filtro de Aire';
      case TipoFiltro.combustible:
        return 'Filtro de Combustible';
    }
  }

  /// Configura el tipo de motor para un bus
  static Future<void> configurarMantenimientoPreventivo({
    required String busId,
    required TipoMotor tipoMotor,
  }) async {
    final bus = await getBusById(busId);
    if (bus == null) throw Exception('Bus no encontrado');

    MantenimientoPreventivo mantenimientoActualizado;
    if (bus.mantenimientoPreventivo != null) {
      mantenimientoActualizado = bus.mantenimientoPreventivo!.copyWith(
        tipoMotor: tipoMotor,
      );
    } else {
      mantenimientoActualizado = MantenimientoPreventivo(
        busId: busId,
        tipoMotor: tipoMotor,
        fechaCreacion: DateTime.now(),
      );
    }

    final busActualizado = bus.copyWith(
      mantenimientoPreventivo: mantenimientoActualizado,
    );

    await updateBus(busActualizado);
  }

  // Resto de métodos sin cambios significativos...
  static Future<List<ReporteDiario>> getReportesPorBus(String busPatente) async {
    final todosLosReportes = await getReportes();
    return todosLosReportes.where((reporte) =>
        reporte.busesAtendidos.contains(busPatente)
    ).toList();
  }

  static Future<List<ReporteDiario>> getReportesPorBusYTipo(
      String busPatente,
      String? tipoFiltro
      ) async {
    var reportes = await getReportesPorBus(busPatente);

    if (tipoFiltro != null && tipoFiltro != 'Todos') {
      reportes = reportes.where((reporte) =>
      reporte.tipoTrabajoDisplay == tipoFiltro
      ).toList();
    }

    return reportes;
  }

  /// Obtiene todos los buses que requieren mantenimiento crítico
  static Future<List<Bus>> getBusesConMantenimientoCritico() async {
    final buses = await getBuses();
    return buses.where((bus) =>
    bus.tieneMantenimientosVencidos || bus.tieneMantenimientosUrgentes
    ).toList();
  }

  /// Obtiene todos los buses que requieren mantenimiento en los próximos días
  static Future<List<Bus>> getBusesConMantenimientoProximo(int dias) async {
    final buses = await getBuses();
    return buses.where((bus) {
      return bus.estadosMantenimiento.any((estado) =>
      estado.diasRestantes <= dias && estado.diasRestantes > 0
      );
    }).toList();
  }

  /// Obtiene estadísticas de mantenimiento preventivo
  static Future<Map<String, dynamic>> getEstadisticasMantenimiento() async {
    final buses = await getBuses();

    int busesConMantenimientoCritico = 0;
    int busesConMantenimientoUrgente = 0;
    int totalFiltrosVencidos = 0;
    int totalFiltrosUrgentes = 0;

    Map<TipoFiltro, int> filtrosVencidosPorTipo = {};
    Map<TipoFiltro, int> filtrosUrgentesPorTipo = {};

    for (final bus in buses) {
      if (bus.tieneMantenimientosVencidos) busesConMantenimientoCritico++;
      if (bus.tieneMantenimientosUrgentes) busesConMantenimientoUrgente++;

      for (final estado in bus.mantenimientosCriticos) {
        if (estado.urgencia == NivelUrgencia.critico) {
          totalFiltrosVencidos++;
          filtrosVencidosPorTipo[estado.tipoFiltro] =
              (filtrosVencidosPorTipo[estado.tipoFiltro] ?? 0) + 1;
        } else if (estado.urgencia == NivelUrgencia.urgente) {
          totalFiltrosUrgentes++;
          filtrosUrgentesPorTipo[estado.tipoFiltro] =
              (filtrosUrgentesPorTipo[estado.tipoFiltro] ?? 0) + 1;
        }
      }
    }

    return {
      'busesConMantenimientoCritico': busesConMantenimientoCritico,
      'busesConMantenimientoUrgente': busesConMantenimientoUrgente,
      'totalFiltrosVencidos': totalFiltrosVencidos,
      'totalFiltrosUrgentes': totalFiltrosUrgentes,
      'filtrosVencidosPorTipo': filtrosVencidosPorTipo,
      'filtrosUrgentesPorTipo': filtrosUrgentesPorTipo,
      'totalBuses': buses.length,
      'porcentajeBusesConAlertas': buses.isNotEmpty
          ? ((busesConMantenimientoCritico + busesConMantenimientoUrgente) / buses.length * 100).round()
          : 0,
    };
  }

  // =============================================================================
  // MÉTODOS AUXILIARES PARA REPUESTOS PREDETERMINADOS
  // =============================================================================

  static Future<void> _asignarRepuestosPredeterminados(String busId) async {
    try {
      final catalogoRepuestos = await getCatalogoRepuestos();

      final codigosPredeterminados = [
        'FLT-ACE-001', // Filtro de aceite
        'FLT-CMB-001', // Filtro de combustible
        'FLT-AIR-001', // Filtro de aire
      ];

      final ahora = DateTime.now();

      for (final codigo in codigosPredeterminados) {
        final repuesto = catalogoRepuestos.firstWhere(
              (r) => r.codigo == codigo,
          orElse: () => throw Exception('Repuesto predeterminado $codigo no encontrado'),
        );

        final repuestoAsignado = RepuestoAsignado(
          id: '${busId}_${repuesto.id}_${ahora.millisecondsSinceEpoch}',
          repuestoCatalogoId: repuesto.id,
          busId: busId,
          fechaAsignacion: ahora,
          cantidad: 1,
          ubicacionBus: _getUbicacionPredeterminada(repuesto.sistema),
          instalado: false,
          observaciones: 'Repuesto predeterminado asignado automáticamente',
          tecnicoResponsable: 'Sistema',
        );

        await addRepuestoAsignado(repuestoAsignado);
      }

      print('Repuestos predeterminados asignados al bus $busId');
    } catch (e) {
      print('Error al asignar repuestos predeterminados: $e');
    }
  }

  static String _getUbicacionPredeterminada(SistemaVehiculo sistema) {
    switch (sistema) {
      case SistemaVehiculo.motor:
        return 'Compartimento Motor';
      case SistemaVehiculo.combustible:
        return 'Sistema Combustible';
      case SistemaVehiculo.electrico:
        return 'Compartimento Eléctrico';
      case SistemaVehiculo.frenos:
        return 'Sistema Frenos';
      case SistemaVehiculo.suspension:
        return 'Eje Delantero';
      case SistemaVehiculo.transmision:
        return 'Caja Transmisión';
      case SistemaVehiculo.refrigeracion:
        return 'Sistema Refrigeración';
      case SistemaVehiculo.climatizacion:
        return 'Sistema Climatización';
      case SistemaVehiculo.neumaticos:
        return 'Ruedas';
      case SistemaVehiculo.carroceria:
        return 'Carrocería';
      default:
        return 'Ubicación General';
    }
  }

  // =============================================================================
  // MÉTODOS PARA CATÁLOGO DE REPUESTOS (SIN CAMBIOS)
  // =============================================================================

  static Future<List<RepuestoCatalogo>> getCatalogoRepuestos() =>
      FirebaseService.getCatalogoRepuestos();

  static Future<String> addRepuestoCatalogo(RepuestoCatalogo repuesto) =>
      FirebaseService.addRepuestoCatalogo(repuesto);

  static Future<void> updateRepuestoCatalogo(RepuestoCatalogo updatedRepuesto) =>
      FirebaseService.updateRepuestoCatalogo(updatedRepuesto);

  static Future<void> deleteRepuestoCatalogo(String id) =>
      FirebaseService.deleteRepuestoCatalogo(id);

  static Future<RepuestoCatalogo?> getRepuestoCatalogoById(String id) =>
      FirebaseService.getRepuestoCatalogoById(id);

  // =============================================================================
  // MÉTODOS PARA REPUESTOS ASIGNADOS (SIN CAMBIOS)
  // =============================================================================

  static Future<List<RepuestoAsignado>> getRepuestosAsignados() =>
      FirebaseService.getRepuestosAsignados();

  static Future<String> addRepuestoAsignado(RepuestoAsignado repuesto) =>
      FirebaseService.addRepuestoAsignado(repuesto);

  static Future<void> updateRepuestoAsignado(RepuestoAsignado updatedRepuesto) =>
      FirebaseService.updateRepuestoAsignado(updatedRepuesto);

  static Future<void> deleteRepuestoAsignado(String id) =>
      FirebaseService.deleteRepuestoAsignado(id);

  static Future<List<RepuestoAsignado>> getRepuestosAsignadosPorBus(String busId) =>
      FirebaseService.getRepuestosAsignadosPorBus(busId);

  static Future<List<Map<String, dynamic>>> getRepuestosAsignadosConInfo(String busId) async {
    final repuestosAsignados = await getRepuestosAsignadosPorBus(busId);
    final catalogoRepuestos = await getCatalogoRepuestos();

    return repuestosAsignados.map((repuestoAsignado) {
      final repuestoCatalogo = catalogoRepuestos.firstWhere(
            (r) => r.id == repuestoAsignado.repuestoCatalogoId,
        orElse: () => RepuestoCatalogo(
          id: 'not_found',
          nombre: 'Repuesto no encontrado',
          codigo: 'N/A',
          descripcion: 'Este repuesto ya no existe en el catálogo',
          sistema: SistemaVehiculo.motor,
          tipo: TipoRepuesto.generico,
          fechaActualizacion: DateTime.now(),
        ),
      );

      return {
        'repuestoAsignado': repuestoAsignado,
        'repuestoCatalogo': repuestoCatalogo,
      };
    }).toList();
  }

  // =============================================================================
  // MÉTODOS PARA REPORTES (SIN CAMBIOS)
  // =============================================================================

  static Future<List<ReporteDiario>> getReportes() => FirebaseService.getReportes();
  static Future<String> addReporte(ReporteDiario reporte) => FirebaseService.addReporte(reporte);
  static Future<void> updateReporte(ReporteDiario updatedReporte) => FirebaseService.updateReporte(updatedReporte);
  static Future<void> deleteReporte(String id) => FirebaseService.deleteReporte(id);
  static Future<ReporteDiario?> getReporteById(String id) => FirebaseService.getReporteById(id);
  static Future<List<ReporteDiario>> getReportesPorFecha(DateTime fecha) => FirebaseService.getReportesPorFecha(fecha);

  static Future<String> generarNumeroReporte(DateTime fecha) async {
    final reportesDelDia = await getReportesPorFecha(fecha);
    final numeroSecuencial = reportesDelDia.length + 1;
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString().substring(2);
    final numero = numeroSecuencial.toString().padLeft(3, '0');
    return '$numero/$dia/$mes/$anio';
  }

  static Future<List<Bus>> getBusesParaReportes() async {
    final buses = await getBuses();
    buses.sort((a, b) => a.patente.compareTo(b.patente));
    return buses;
  }

  static Future<Map<String, dynamic>> getEstadisticasReportes() async {
    final ahora = DateTime.now();
    final inicioMes = DateTime(ahora.year, ahora.month, 1);
    final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));

    final reportes = await getReportes();
    final reportesHoy = (await getReportesPorFecha(ahora)).length;
    final reportesSemana = reportes.where((r) => r.fecha.isAfter(inicioSemana)).length;
    final reportesMes = reportes.where((r) => r.fecha.isAfter(inicioMes)).length;

    final busesAtendidosMes = <String>{};
    for (final reporte in reportes.where((r) => r.fecha.isAfter(inicioMes))) {
      busesAtendidosMes.addAll(reporte.busesAtendidos);
    }

    return {
      'total': reportes.length,
      'hoy': reportesHoy,
      'semana': reportesSemana,
      'mes': reportesMes,
      'busesAtendidosMes': busesAtendidosMes.length,
      'ultimoReporte': reportes.isNotEmpty ? reportes.last.fecha : null,
    };
  }

  // =============================================================================
  // ESTADÍSTICAS GENERALES
  // =============================================================================

  static Future<Map<String, int>> getEstadisticas() async {
    final buses = await getBuses();
    final catalogoRepuestos = await getCatalogoRepuestos();
    final repuestosAsignados = await getRepuestosAsignados();
    final busesRevisionVencida = await getBusesRevisionTecnicaVencida();
    final busesRevisionProximaVencer = await getBusesRevisionTecnicaProximaVencer();
    final busesMantenimientoCritico = await getBusesConMantenimientoCritico();

    final disponibles = buses.where((b) => b.estado == EstadoBus.disponible).length;
    final enReparacion = buses.where((b) => b.estado == EstadoBus.enReparacion).length;
    final fueraServicio = buses.where((b) => b.estado == EstadoBus.fueraDeServicio).length;

    return {
      'total': buses.length,
      'disponibles': disponibles,
      'enReparacion': enReparacion,
      'fueraServicio': fueraServicio,
      'catalogoRepuestos': catalogoRepuestos.length,
      'repuestosAsignados': repuestosAsignados.length,
      'revisionVencida': busesRevisionVencida.length,
      'revisionProximaVencer': busesRevisionProximaVencer.length,
      'mantenimientoCritico': busesMantenimientoCritico.length,
    };
  }

  // =============================================================================
  // MÉTODOS PARA REVISIÓN TÉCNICA (SIN CAMBIOS)
  // =============================================================================

  static Future<List<Bus>> getBusesRevisionTecnicaVencida() async {
    final buses = await getBuses();
    return buses.where((b) => b.revisionTecnicaVencida).toList();
  }

  static Future<List<Bus>> getBusesRevisionTecnicaProximaVencer() async {
    final buses = await getBuses();
    return buses.where((b) => b.revisionTecnicaProximaAVencer).toList();
  }

  static Future<List<Bus>> getBusesRevisionTecnicaVigente() async {
    final buses = await getBuses();
    return buses.where((b) => b.revisionTecnicaVigente).toList();
  }

  static Future<List<Bus>> getBusesEnReparacion() async {
    final buses = await getBuses();
    return buses.where((b) => b.estado == EstadoBus.enReparacion).toList();
  }

  static Future<List<Bus>> getBusesDisponibles() async {
    final buses = await getBuses();
    return buses.where((b) => b.estado == EstadoBus.disponible).toList();
  }

  static Future<List<Bus>> getBusesFueraDeServicio() async {
    final buses = await getBuses();
    return buses.where((b) => b.estado == EstadoBus.fueraDeServicio).toList();
  }

  // =============================================================================
  // MÉTODOS DE INICIALIZACIÓN Y UTILIDADES (SIN CAMBIOS)
  // =============================================================================

  static Future<void> initializeSampleData() async {
    await FirebaseService.initializeSampleData();
  }

  static Future<String> exportBusesToCSV() async {
    final buses = await getBuses();
    final buffer = StringBuffer();
    buffer.writeln('Patente,Identificador,Marca,Modelo,Anio,Estado,Ubicacion,Kilometraje,RevisionTecnica,TipoMotor');

    for (final bus in buses) {
      buffer.writeln([
        bus.patente,
        bus.identificador ?? '',
        bus.marca,
        bus.modelo,
        bus.anio,
        bus.estado.toString().split('.').last,
        bus.ubicacionActual ?? '',
        bus.kilometraje ?? '',
        bus.fechaRevisionTecnica?.toIso8601String() ?? '',
        bus.mantenimientoPreventivo?.tipoMotor.toString().split('.').last ?? 'diesel',
      ].join(','));
    }

    return buffer.toString();
  }

  static Future<void> importBusesFromCSV(String csvContent) async {
    final lines = csvContent.split('\n');
    if (lines.isEmpty) return;

    for (int i = 1; i < lines.length; i++) {
      final row = lines[i].split(',');
      if (row.length >= 4) {
        try {
          final bus = Bus(
            id: '',
            patente: row[0].trim(),
            identificador: row.length > 1 && row[1].trim().isNotEmpty ? row[1].trim() : null,
            marca: row.length > 2 ? row[2].trim() : '',
            modelo: row.length > 3 ? row[3].trim() : '',
            anio: row.length > 4 ? int.parse(row[4].trim()) : DateTime.now().year,
            estado: EstadoBus.disponible,
            historialMantenciones: [],
            fechaRegistro: DateTime.now(),
            ubicacionActual: row.length > 6 ? row[6].trim() : null,
            kilometraje: row.length > 7 ? double.tryParse(row[7].trim()) : null,
          );
          await addBus(bus);
        } catch (e) {
          print('Error al importar fila $i: $e');
        }
      }
    }
  }

  // ✅ NUEVOS MÉTODOS para manejar filtros críticos y alertas de kilometraje

  /// Verifica si un bus tiene filtros críticos que requieren mantenimiento basado en kilometraje
  static Future<List<Map<String, dynamic>>> verificarAlertasFiltrosCriticos(String busId) async {
    final bus = await getBusById(busId);
    if (bus == null || bus.mantenimientoPreventivo == null || bus.kilometraje == null) {
      return [];
    }

    final alertas = <Map<String, dynamic>>[];
    final promedioMensual = bus.promedioKmMensuales ?? 5000; // Default 5000 km/mes
    const umbralCritico = 5000; // Umbral de 5000 km/mes según el usuario

    // Obtener tipos críticos desde la base de datos
    final tiposCriticos = await getTiposMantenimientoPersonalizados();
    final filtrosCriticos = tiposCriticos.where((t) => t.esFiltroCritico && t.activo).toList();

    for (final filtroCritico in filtrosCriticos) {
      // Buscar el último mantenimiento de este filtro específico
      final ultimoMantenimiento = bus.mantenimientoPreventivo!.historialMantenimientos
          .where((m) => m.tituloPersonalizado == filtroCritico.titulo)
          .fold<RegistroMantenimiento?>(null, (prev, current) {
        if (prev == null) return current;
        return current.fechaUltimoCambio.isAfter(prev.fechaUltimoCambio) ? current : prev;
      });

      double kmDesdeUltimoMantenimiento;
      DateTime fechaBase;

      if (ultimoMantenimiento != null) {
        kmDesdeUltimoMantenimiento = bus.kilometraje! - ultimoMantenimiento.kilometrajeUltimoCambio;
        fechaBase = ultimoMantenimiento.fechaUltimoCambio;
      } else {
        // Si no hay historial, usar desde la creación del sistema de mantenimiento
        kmDesdeUltimoMantenimiento = bus.kilometraje!;
        fechaBase = bus.mantenimientoPreventivo!.fechaCreacion;
      }

      // Calcular meses transcurridos
      final mesesTranscurridos = DateTime.now().difference(fechaBase).inDays / 30.0;
      final kmPromedioMensual = mesesTranscurridos > 0 ? kmDesdeUltimoMantenimiento / mesesTranscurridos : 0;

      // Verificar si supera el umbral crítico
      if (kmPromedioMensual > umbralCritico) {
        String nivelUrgencia;
        Color colorAlerta;

        if (kmPromedioMensual > umbralCritico * 1.5) { // Más de 7500 km/mes
          nivelUrgencia = 'CRÍTICO';
          colorAlerta = Colors.red;
        } else if (kmPromedioMensual > umbralCritico * 1.2) { // Más de 6000 km/mes
          nivelUrgencia = 'URGENTE';
          colorAlerta = Colors.orange;
        } else {
          nivelUrgencia = 'ATENCIÓN';
          colorAlerta = Colors.yellow[700]!;
        }

        alertas.add({
          'filtro': filtroCritico,
          'kmDesdeUltimo': kmDesdeUltimoMantenimiento,
          'kmPromedioMensual': kmPromedioMensual,
          'mesesTranscurridos': mesesTranscurridos,
          'nivelUrgencia': nivelUrgencia,
          'colorAlerta': colorAlerta,
          'ultimoMantenimiento': ultimoMantenimiento,
          'bus': bus,
        });
      }
    }

    // Ordenar por nivel de urgencia y km promedio
    alertas.sort((a, b) {
      final urgenciaA = a['nivelUrgencia'] as String;
      final urgenciaB = b['nivelUrgencia'] as String;

      if (urgenciaA == 'CRÍTICO' && urgenciaB != 'CRÍTICO') return -1;
      if (urgenciaB == 'CRÍTICO' && urgenciaA != 'CRÍTICO') return 1;
      if (urgenciaA == 'URGENTE' && urgenciaB == 'ATENCIÓN') return -1;
      if (urgenciaB == 'URGENTE' && urgenciaA == 'ATENCIÓN') return 1;

      // Si mismo nivel, ordenar por km promedio mensual
      final kmA = a['kmPromedioMensual'] as double;
      final kmB = b['kmPromedioMensual'] as double;
      return kmB.compareTo(kmA);
    });

    return alertas;
  }

  /// Obtiene todas las alertas de filtros críticos para todos los buses
  static Future<List<Map<String, dynamic>>> obtenerTodasLasAlertasFiltrosCriticos() async {
    final buses = await getBuses();
    final todasLasAlertas = <Map<String, dynamic>>[];

    for (final bus in buses) {
      final alertasBus = await verificarAlertasFiltrosCriticos(bus.id);
      todasLasAlertas.addAll(alertasBus);
    }

    return todasLasAlertas;
  }

  /// Obtiene estadísticas de filtros críticos para el dashboard
  static Future<Map<String, dynamic>> getEstadisticasFiltrosCriticos() async {
    final todasLasAlertas = await obtenerTodasLasAlertasFiltrosCriticos();

    final alertasCriticas = todasLasAlertas.where((a) => a['nivelUrgencia'] == 'CRÍTICO').length;
    final alertasUrgentes = todasLasAlertas.where((a) => a['nivelUrgencia'] == 'URGENTE').length;
    final alertasAtencion = todasLasAlertas.where((a) => a['nivelUrgencia'] == 'ATENCIÓN').length;

    // Contar por tipo de filtro
    final alertasPorFiltro = <String, int>{};
    for (final alerta in todasLasAlertas) {
      final filtro = alerta['filtro'] as TipoMantenimientoPersonalizado;
      alertasPorFiltro[filtro.titulo] = (alertasPorFiltro[filtro.titulo] ?? 0) + 1;
    }

    // Calcular promedio de km mensuales general
    double promedioKmGeneral = 0;
    if (todasLasAlertas.isNotEmpty) {
      final totalKm = todasLasAlertas.fold<double>(0, (sum, alerta) => sum + (alerta['kmPromedioMensual'] as double));
      promedioKmGeneral = totalKm / todasLasAlertas.length;
    }

    return {
      'totalAlertas': todasLasAlertas.length,
      'alertasCriticas': alertasCriticas,
      'alertasUrgentes': alertasUrgentes,
      'alertasAtencion': alertasAtencion,
      'alertasPorFiltro': alertasPorFiltro,
      'promedioKmGeneral': promedioKmGeneral,
      'umbralConfigurado': 5000, // Umbral de referencia
      'alertasCompletas': todasLasAlertas,
    };
  }

  /// Registra un mantenimiento de filtro crítico con seguimiento especial
  static Future<void> registrarMantenimientoFiltroCritico({
    required String busId,
    required String tituloFiltro, // 'Filtro de Aceite', 'Filtro de Aire', etc.
    required double kilometrajeActual,
    DateTime? fechaMantenimiento,
    String? tecnicoResponsable,
    String? observaciones,
    String? marcaRepuesto,
  }) async {
    // Verificar que sea un filtro crítico válido
    final filtrosCriticos = ['Filtro de Aceite', 'Filtro de Aire', 'Filtro de Combustible'];
    if (!filtrosCriticos.contains(tituloFiltro)) {
      throw Exception('$tituloFiltro no es un filtro crítico válido');
    }

    // Obtener o crear el tipo personalizado para este filtro crítico
    final tipoPersonalizado = await crearOreutilizarTipo(
      titulo: tituloFiltro,
      descripcion: 'Cambio preventivo del ${tituloFiltro.toLowerCase()}. Crítico para alertas de kilometraje.',
      tipoBase: TipoMantenimiento.preventivo,
    );

    print('🔧 Registrando mantenimiento de filtro crítico: $tituloFiltro');

    // Usar el método estándar pero con información adicional
    await registrarMantenimientoPersonalizado(
      busId: busId,
      tituloMantenimiento: tituloFiltro,
      descripcionMantenimiento: 'Mantenimiento crítico con seguimiento de kilometraje. Umbral: 5000 km/mes.',
      tipoMantenimiento: TipoMantenimiento.preventivo,
      kilometrajeActual: kilometrajeActual,
      fechaMantenimiento: fechaMantenimiento,
      tecnicoResponsable: tecnicoResponsable,
      observaciones: observaciones,
      marcaRepuesto: marcaRepuesto,
    );

    print('✅ Filtro crítico $tituloFiltro registrado para seguimiento de kilometraje');
  }

  /// Actualiza la configuración del umbral de kilometraje para filtros críticos
  static Future<void> configurarUmbralFiltrosCriticos(int nuevoUmbral) async {
    // En una implementación completa, esto se guardaría en Firebase
    // Por ahora, es una constante pero se puede expandir
    print('🔧 Umbral de filtros críticos configurado a: $nuevoUmbral km/mes');
  }

  /// Método auxiliar para verificar si un mantenimiento corresponde a un filtro crítico
  static bool esMantenimientoFiltroCritico(RegistroMantenimiento mantenimiento) {
    final filtrosCriticos = ['Filtro de Aceite', 'Filtro de Aire', 'Filtro de Combustible'];
    return mantenimiento.tituloPersonalizado != null &&
        filtrosCriticos.contains(mantenimiento.tituloPersonalizado!);
  }

  /// Obtiene recomendaciones para el mantenimiento de filtros críticos
  static Future<List<Map<String, dynamic>>> obtenerRecomendacionesFiltrosCriticos(String busId) async {
    final alertas = await verificarAlertasFiltrosCriticos(busId);
    final recomendaciones = <Map<String, dynamic>>[];

    for (final alerta in alertas) {
      final filtro = alerta['filtro'] as TipoMantenimientoPersonalizado;
      final kmPromedio = alerta['kmPromedioMensual'] as double;
      final mesesTranscurridos = alerta['mesesTranscurridos'] as double;

      String recomendacion;
      String prioridad;
      Color color;

      if (kmPromedio > 7500) {
        recomendacion = 'Cambio INMEDIATO del ${filtro.titulo}. Riesgo de daño al motor.';
        prioridad = 'CRÍTICA';
        color = Colors.red;
      } else if (kmPromedio > 6000) {
        recomendacion = 'Programar cambio del ${filtro.titulo} dentro de los próximos 3 días.';
        prioridad = 'URGENTE';
        color = Colors.orange;
      } else {
        recomendacion = 'Considerar cambio del ${filtro.titulo} en la próxima semana.';
        prioridad = 'ATENCIÓN';
        color = Colors.yellow[700]!;
      }

      recomendaciones.add({
        'filtro': filtro,
        'recomendacion': recomendacion,
        'prioridad': prioridad,
        'color': color,
        'kmPromedio': kmPromedio,
        'mesesTranscurridos': mesesTranscurridos,
      });
    }

    return recomendaciones;
  }

  // Métodos para filtros (sin cambios)
  static Future<List<FiltroRepuesto>> getFiltrosRepuestos() =>
      FirebaseService.getFiltrosRepuestos();

  static Future<String> addFiltroRepuesto(FiltroRepuesto filtro) =>
      FirebaseService.addFiltroRepuesto(filtro);

  static Future<void> updateFiltroRepuesto(FiltroRepuesto updatedFiltro) =>
      FirebaseService.updateFiltroRepuesto(updatedFiltro);

  static Future<void> deleteFiltroRepuesto(String id) =>
      FirebaseService.deleteFiltroRepuesto(id);

  static Future<void> deleteMantenimientoFromBus(String busId, String mantenimientoId, String tipoMantenimiento) async {
    final bus = await getBusById(busId);
    if (bus == null) throw Exception('Bus no encontrado para eliminar mantenimiento.');

    if (tipoMantenimiento == 'nuevo') {
      bus.mantenimientoPreventivo?.historialMantenimientos.removeWhere((m) => m.id == mantenimientoId);
    } else { // 'antiguo'
      bus.historialMantenciones.removeWhere((m) => m.id == mantenimientoId);
    }

    await updateBus(bus);
  }

  static Future<void> updateMantenimientoRegistro(String busId, RegistroMantenimiento registroActualizado) async {
    final bus = await getBusById(busId);
    if (bus == null) throw Exception('Bus no encontrado para actualizar mantenimiento.');

    if (bus.mantenimientoPreventivo != null) {
      final historial = bus.mantenimientoPreventivo!.historialMantenimientos;
      final index = historial.indexWhere((m) => m.id == registroActualizado.id);

      if (index != -1) {
        historial[index] = registroActualizado;
        await updateBus(bus);
      } else {
        throw Exception('No se encontró el registro de mantenimiento para actualizar.');
      }
    } else {
      throw Exception('El bus no tiene un sistema de mantenimiento preventivo configurado.');
    }
  }
}