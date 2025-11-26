import 'repuesto_asignado.dart';
import 'reporte_diario.dart';
import 'mantenimiento_preventivo.dart';
import 'tipo_mantenimiento_personalizado.dart';

enum EstadoBus { disponible, enReparacion, fueraDeServicio }

class Bus {
  final String id;
  final String? identificador;
  final String patente;
  final String marca;
  final String modelo;
  final int anio;
  final EstadoBus estado;
  final List<RepuestoAsignado> repuestosAsignados;
  final List<String> historialReportes;
  final DateTime fechaRegistro;
  final DateTime? fechaRevisionTecnica;
  final String? numeroChasis;
  final String? numeroMotor;
  final int capacidadPasajeros;
  final String? ubicacionActual;
  final double? kilometraje;

  // CAMPOS PARA MANTENIMIENTO PREVENTIVO
  final MantenimientoPreventivo? mantenimientoPreventivo;
  final double? promedioKmMensuales; // Para calcular proyecciones
  final DateTime? ultimaActualizacionKm;
  final double? kilometrajeIdeal; // ✅ CAMPO AÑADIDO

  Bus({
    required this.id,
    this.identificador,
    required this.patente,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.estado,
    this.repuestosAsignados = const [],
    this.historialReportes = const [],
    required this.fechaRegistro,
    this.fechaRevisionTecnica,
    this.numeroChasis,
    this.numeroMotor,
    this.capacidadPasajeros = 40,
    this.ubicacionActual,
    this.kilometraje,
    this.mantenimientoPreventivo,
    this.promedioKmMensuales,
    this.ultimaActualizacionKm,
    this.kilometrajeIdeal,
  });

  // Getter para mostrar identificador o patente como fallback
  String get identificadorDisplay => identificador ?? patente;

  // Getter para búsqueda que incluye ambos
  String get textoIdentificacion => '${identificador ?? ''} $patente'.trim();

  // Getters para revisión técnica según normativa chilena
  bool get revisionTecnicaVencida {
    if (fechaRevisionTecnica == null) return false;
    return DateTime.now().isAfter(fechaRevisionTecnica!);
  }

  bool get revisionTecnicaProximaAVencer {
    if (fechaRevisionTecnica == null) return false;
    if (revisionTecnicaVencida) return false;
    final diasRestantes = fechaRevisionTecnica!.difference(DateTime.now()).inDays;
    return diasRestantes <= 30;
  }

  bool get revisionTecnicaVigente {
    if (fechaRevisionTecnica == null) return false;
    return !revisionTecnicaVencida;
  }

  int get diasParaVencimientoRevision {
    if (fechaRevisionTecnica == null) return 0;
    return fechaRevisionTecnica!.difference(DateTime.now()).inDays;
  }

  // GETTERS PARA MANTENIMIENTO PREVENTIVO (mantener compatibilidad con filtros)

  /// Obtiene todos los estados de mantenimiento del bus (solo filtros para compatibilidad)
  List<EstadoMantenimiento> get estadosMantenimiento {
    if (mantenimientoPreventivo == null || kilometraje == null) return [];
    return mantenimientoPreventivo!.obtenerTodosLosEstados(kilometraje!);
  }

  /// Obtiene solo los mantenimientos críticos o urgentes (solo filtros)
  List<EstadoMantenimiento> get mantenimientosCriticos {
    if (mantenimientoPreventivo == null || kilometraje == null) return [];
    return mantenimientoPreventivo!.obtenerEstadosCriticos(kilometraje!);
  }

  /// Indica si el bus tiene mantenimientos vencidos
  bool get tieneMantenimientosVencidos {
    return mantenimientosCriticos
        .any((estado) => estado.urgencia == NivelUrgencia.critico);
  }

  /// Indica si el bus tiene mantenimientos próximos a vencer
  bool get tieneMantenimientosUrgentes {
    return mantenimientosCriticos
        .any((estado) => estado.urgencia == NivelUrgencia.urgente);
  }

  /// Calcula el número total de alertas de mantenimiento
  int get numeroAlertasMantenimiento {
    return mantenimientosCriticos.length;
  }

  /// Obtiene el mantenimiento más urgente
  EstadoMantenimiento? get mantenimientoMasUrgente {
    final criticos = mantenimientosCriticos;
    if (criticos.isEmpty) return null;

    // Ordenar por urgencia y luego por días restantes
    criticos.sort((a, b) {
      final urgenciaComparison = a.urgencia.index.compareTo(b.urgencia.index);
      if (urgenciaComparison != 0) return urgenciaComparison;
      return a.diasRestantes.compareTo(b.diasRestantes);
    });

    return criticos.first;
  }

  // ✅ NUEVOS GETTERS para mantenimientos personalizados

  /// Obtiene todos los mantenimientos personalizados del bus
  List<RegistroMantenimiento> get mantenimientosPersonalizados {
    if (mantenimientoPreventivo == null) return [];
    return mantenimientoPreventivo!.mantenimientosPersonalizados;
  }

  /// Obtiene mantenimientos por tipo
  List<RegistroMantenimiento> mantenimientosPorTipo(TipoMantenimiento tipo) {
    if (mantenimientoPreventivo == null) return [];
    return mantenimientoPreventivo!.mantenimientosPorTipo(tipo);
  }

  /// Obtiene el último mantenimiento realizado (de cualquier tipo)
  RegistroMantenimiento? get ultimoMantenimiento {
    if (mantenimientoPreventivo == null || mantenimientoPreventivo!.historialMantenimientos.isEmpty) {
      return null;
    }

    final mantenimientos = mantenimientoPreventivo!.historialMantenimientos;
    return mantenimientos.fold<RegistroMantenimiento?>(null, (prev, current) {
      if (prev == null) return current;
      return current.fechaUltimoCambio.isAfter(prev.fechaUltimoCambio) ? current : prev;
    });
  }

  /// Cuenta total de mantenimientos realizados (filtros + personalizados)
  int get totalMantenimientosRealizados {
    if (mantenimientoPreventivo == null) return 0;
    return mantenimientoPreventivo!.historialMantenimientos.length;
  }

  /// Estadísticas de mantenimientos por tipo
  Map<TipoMantenimiento, int> get estadisticasMantenimientosPorTipo {
    if (mantenimientoPreventivo == null) return {};

    final stats = <TipoMantenimiento, int>{
      TipoMantenimiento.correctivo: 0,
      TipoMantenimiento.rutinario: 0,
      TipoMantenimiento.preventivo: 0,
    };

    for (final mantenimiento in mantenimientoPreventivo!.historialMantenimientos) {
      final tipo = mantenimiento.tipoMantenimientoEfectivo;
      stats[tipo] = (stats[tipo] ?? 0) + 1;
    }

    return stats;
  }

  /// Estima el kilometraje futuro basado en el promedio mensual
  double? calcularKilometrajeEstimado(DateTime fechaFutura) {
    if (kilometraje == null || promedioKmMensuales == null) return null;

    final mesesHastaFecha = fechaFutura.difference(DateTime.now()).inDays / 30.0;
    return kilometraje! + (promedioKmMensuales! * mesesHastaFecha);
  }

  /// Actualiza el promedio de kilometraje mensual
  double calcularPromedioKmMensuales() {
    if (kilometraje == null || ultimaActualizacionKm == null) {
      return promedioKmMensuales ?? 2000; // Valor por defecto
    }

    final mesesTranscurridos = DateTime.now().difference(ultimaActualizacionKm!).inDays / 30.0;
    if (mesesTranscurridos <= 0) return promedioKmMensuales ?? 2000;

    // Calcular nuevo promedio ponderado
    final kmRecientes = kilometraje! / mesesTranscurridos;
    if (promedioKmMensuales == null) {
      return kmRecientes;
    }

    // Promedio ponderado: 70% histórico, 30% reciente
    return (promedioKmMensuales! * 0.7) + (kmRecientes * 0.3);
  }

  // Getters para repuestos (mantenidos de la versión original)
  List<RepuestoAsignado> get repuestosInstalados =>
      repuestosAsignados.where((r) => r.instalado).toList();

  List<RepuestoAsignado> get repuestosPendientes =>
      repuestosAsignados.where((r) => !r.instalado).toList();

  List<RepuestoAsignado> get repuestosProximosVencer {
    final ahora = DateTime.now();
    return repuestosInstalados.where((r) {
      if (r.proximoCambio == null) return false;
      final diasRestantes = r.proximoCambio!.difference(ahora).inDays;
      return diasRestantes <= 30 && diasRestantes >= 0;
    }).toList();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'identificador': identificador,
    'patente': patente,
    'marca': marca,
    'modelo': modelo,
    'anio': anio,
    'estado': estado.toString(),
    'repuestosAsignados': repuestosAsignados.map((r) => r.toJson()).toList(),
    'historialReportes': historialReportes,
    'fechaRegistro': fechaRegistro.toIso8601String(),
    'fechaRevisionTecnica': fechaRevisionTecnica?.toIso8601String(),
    'numeroChasis': numeroChasis,
    'numeroMotor': numeroMotor,
    'capacidadPasajeros': capacidadPasajeros,
    'ubicacionActual': ubicacionActual,
    'kilometraje': kilometraje,
    'mantenimientoPreventivo': mantenimientoPreventivo?.toJson(),
    'promedioKmMensuales': promedioKmMensuales,
    'ultimaActualizacionKm': ultimaActualizacionKm?.toIso8601String(),
    'kilometrajeIdeal': kilometrajeIdeal,
  };

  factory Bus.fromJson(Map<String, dynamic> json) => Bus(
    id: json['id'],
    identificador: json['identificador'],
    patente: json['patente'],
    marca: json['marca'],
    modelo: json['modelo'],
    anio: json['anio'],
    estado: EstadoBus.values.firstWhere((e) => e.toString() == json['estado']),
    repuestosAsignados: (json['repuestosAsignados'] as List? ?? [])
        .map((r) => RepuestoAsignado.fromJson(r)).toList(),
    historialReportes: List<String>.from(json['historialReportes'] ?? []),
    fechaRegistro: DateTime.parse(json['fechaRegistro']),
    fechaRevisionTecnica: json['fechaRevisionTecnica'] != null
        ? DateTime.parse(json['fechaRevisionTecnica'])
        : null,
    numeroChasis: json['numeroChasis'],
    numeroMotor: json['numeroMotor'],
    capacidadPasajeros: json['capacidadPasajeros'] ?? 40,
    ubicacionActual: json['ubicacionActual'],
    kilometraje: json['kilometraje']?.toDouble(),
    mantenimientoPreventivo: json['mantenimientoPreventivo'] != null
        ? MantenimientoPreventivo.fromJson(json['mantenimientoPreventivo'])
        : null,
    promedioKmMensuales: json['promedioKmMensuales']?.toDouble(),
    ultimaActualizacionKm: json['ultimaActualizacionKm'] != null
        ? DateTime.parse(json['ultimaActualizacionKm'])
        : null,
    kilometrajeIdeal: json['kilometrajeIdeal']?.toDouble(),
  );

  Bus copyWith({
    String? id,
    String? identificador,
    String? patente,
    String? marca,
    String? modelo,
    int? anio,
    EstadoBus? estado,
    List<RepuestoAsignado>? repuestosAsignados,
    List<String>? historialReportes,
    DateTime? fechaRegistro,
    DateTime? fechaRevisionTecnica,
    String? numeroChasis,
    String? numeroMotor,
    int? capacidadPasajeros,
    String? ubicacionActual,
    double? kilometraje,
    MantenimientoPreventivo? mantenimientoPreventivo,
    double? promedioKmMensuales,
    DateTime? ultimaActualizacionKm,
    double? kilometrajeIdeal,
  }) {
    return Bus(
      id: id ?? this.id,
      identificador: identificador ?? this.identificador,
      patente: patente ?? this.patente,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      anio: anio ?? this.anio,
      estado: estado ?? this.estado,
      repuestosAsignados: repuestosAsignados ?? this.repuestosAsignados,
      historialReportes: historialReportes ?? this.historialReportes,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaRevisionTecnica: fechaRevisionTecnica ?? this.fechaRevisionTecnica,
      numeroChasis: numeroChasis ?? this.numeroChasis,
      numeroMotor: numeroMotor ?? this.numeroMotor,
      capacidadPasajeros: capacidadPasajeros ?? this.capacidadPasajeros,
      ubicacionActual: ubicacionActual ?? this.ubicacionActual,
      kilometraje: kilometraje ?? this.kilometraje,
      mantenimientoPreventivo: mantenimientoPreventivo ?? this.mantenimientoPreventivo,
      promedioKmMensuales: promedioKmMensuales ?? this.promedioKmMensuales,
      ultimaActualizacionKm: ultimaActualizacionKm ?? this.ultimaActualizacionKm,
      kilometrajeIdeal: kilometrajeIdeal ?? this.kilometrajeIdeal,
    );
  }
}