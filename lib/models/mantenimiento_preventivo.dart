import 'tipo_mantenimiento_personalizado.dart';

enum TipoFiltro {
  aceite,
  aire,
  combustible,
}

enum TipoMotor {
  diesel,
}

class ConfiguracionMantenimiento {
  final TipoFiltro tipoFiltro;
  final int intervalomKilometraje; // en km
  final int intervalomMeses; // en meses
  final TipoMotor? tipoMotor; // solo para combustible

  ConfiguracionMantenimiento({
    required this.tipoFiltro,
    required this.intervalomKilometraje,
    required this.intervalomMeses,
    this.tipoMotor,
  });

  // Configuraciones predeterminadas según especificaciones
  static ConfiguracionMantenimiento getConfiguracionPredeterminada(
      TipoFiltro tipo,
      TipoMotor tipoMotor,
      ) {
    switch (tipo) {
      case TipoFiltro.aceite:
        return ConfiguracionMantenimiento(
          tipoFiltro: tipo,
          intervalomKilometraje: 10000, // Estándar diésel
          intervalomMeses: 24,
          tipoMotor: tipoMotor,
        );

      case TipoFiltro.aire:
        return ConfiguracionMantenimiento(
          tipoFiltro: tipo,
          intervalomKilometraje: 10000, // Estándar
          intervalomMeses: 24,
          tipoMotor: tipoMotor,
        );

      case TipoFiltro.combustible:
        int kilometraje;
        switch (tipoMotor) {
          case TipoMotor.diesel:
            kilometraje = 10000;
            break;
        }
        return ConfiguracionMantenimiento(
          tipoFiltro: tipo,
          intervalomKilometraje: kilometraje,
          intervalomMeses: 24,
          tipoMotor: tipoMotor,
        );
    }
  }

  Map<String, dynamic> toJson() => {
    'tipoFiltro': tipoFiltro.toString(),
    'intervalomKilometraje': intervalomKilometraje,
    'intervalomMeses': intervalomMeses,
    'tipoMotor': tipoMotor?.toString(),
  };

  factory ConfiguracionMantenimiento.fromJson(Map<String, dynamic> json) => ConfiguracionMantenimiento(
    tipoFiltro: TipoFiltro.values.firstWhere((e) => e.toString() == json['tipoFiltro']),
    intervalomKilometraje: json['intervalomKilometraje'],
    intervalomMeses: json['intervalomMeses'],
    tipoMotor: json['tipoMotor'] != null ? TipoMotor.values.firstWhere((e) => e.toString() == json['tipoMotor']) : null,
  );

  ConfiguracionMantenimiento copyWith({
    TipoFiltro? tipoFiltro,
    int? intervalomKilometraje,
    int? intervalomMeses,
    TipoMotor? tipoMotor,
  }) {
    return ConfiguracionMantenimiento(
      tipoFiltro: tipoFiltro ?? this.tipoFiltro,
      intervalomKilometraje: intervalomKilometraje ?? this.intervalomKilometraje,
      intervalomMeses: intervalomMeses ?? this.intervalomMeses,
      tipoMotor: tipoMotor ?? this.tipoMotor,
    );
  }
}

class RegistroMantenimiento {
  final String id;
  final TipoFiltro? tipoFiltro; // Opcional para mantener compatibilidad
  final DateTime fechaUltimoCambio;
  final double kilometrajeUltimoCambio;
  final String? tecnicoResponsable;
  final String? observaciones;
  final String? marcaRepuesto;

  // ✅ NUEVOS CAMPOS para tipos personalizados
  final String? tipoMantenimientoPersonalizadoId; // ID del tipo personalizado
  final TipoMantenimiento? tipoMantenimiento; // Tipo base (correctivo/rutinario/preventivo)
  final String? tituloPersonalizado; // Título custom del mantenimiento

  RegistroMantenimiento({
    required this.id,
    this.tipoFiltro, // Ya no requerido
    required this.fechaUltimoCambio,
    required this.kilometrajeUltimoCambio,
    this.tecnicoResponsable,
    this.observaciones,
    this.marcaRepuesto,
    // Nuevos campos
    this.tipoMantenimientoPersonalizadoId,
    this.tipoMantenimiento,
    this.tituloPersonalizado,
  });

  // Getters de conveniencia
  bool get esMantenimientoPersonalizado => tipoMantenimientoPersonalizadoId != null;
  bool get esMantenimientoFiltro => tipoFiltro != null;

  String get descripcionTipo {
    if (esMantenimientoPersonalizado && tituloPersonalizado != null) {
      return tituloPersonalizado!;
    } else if (esMantenimientoFiltro) {
      return _getFiltroLabel(tipoFiltro!);
    } else {
      return 'Mantenimiento';
    }
  }

  TipoMantenimiento get tipoMantenimientoEfectivo {
    if (tipoMantenimiento != null) {
      return tipoMantenimiento!;
    }
    // Si es un filtro, considerarlo preventivo por compatibilidad
    return TipoMantenimiento.preventivo;
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipoFiltro': tipoFiltro?.toString(),
    'fechaUltimoCambio': fechaUltimoCambio.toIso8601String(),
    'kilometrajeUltimoCambio': kilometrajeUltimoCambio,
    'tecnicoResponsable': tecnicoResponsable,
    'observaciones': observaciones,
    'marcaRepuesto': marcaRepuesto,
    // Nuevos campos
    'tipoMantenimientoPersonalizadoId': tipoMantenimientoPersonalizadoId,
    'tipoMantenimiento': tipoMantenimiento?.toString(),
    'tituloPersonalizado': tituloPersonalizado,
  };

  factory RegistroMantenimiento.fromJson(Map<String, dynamic> json) => RegistroMantenimiento(
    id: json['id'],
    tipoFiltro: json['tipoFiltro'] != null
        ? TipoFiltro.values.firstWhere((e) => e.toString() == json['tipoFiltro'])
        : null,
    fechaUltimoCambio: DateTime.parse(json['fechaUltimoCambio']),
    kilometrajeUltimoCambio: json['kilometrajeUltimoCambio'].toDouble(),
    tecnicoResponsable: json['tecnicoResponsable'],
    observaciones: json['observaciones'],
    marcaRepuesto: json['marcaRepuesto'],
    // Nuevos campos
    tipoMantenimientoPersonalizadoId: json['tipoMantenimientoPersonalizadoId'],
    tipoMantenimiento: json['tipoMantenimiento'] != null
        ? TipoMantenimiento.values.firstWhere((e) => e.toString() == json['tipoMantenimiento'])
        : null,
    tituloPersonalizado: json['tituloPersonalizado'],
  );
}

class EstadoMantenimiento {
  final TipoFiltro tipoFiltro;
  final DateTime? proximoMantenimientoFecha;
  final double? proximoMantenimientoKm;
  final int diasRestantes;
  final double kmRestantes;
  final NivelUrgencia urgencia;

  EstadoMantenimiento({
    required this.tipoFiltro,
    this.proximoMantenimientoFecha,
    this.proximoMantenimientoKm,
    required this.diasRestantes,
    required this.kmRestantes,
    required this.urgencia,
  });

  String get descripcion {
    switch (tipoFiltro) {
      case TipoFiltro.aceite:
        return 'Filtro de Aceite';
      case TipoFiltro.aire:
        return 'Filtro de Aire';
      case TipoFiltro.combustible:
        return 'Filtro de Combustible';
    }
  }
}

enum NivelUrgencia {
  critico, // Vencido o <7 días
  urgente, // 7-30 días
  proximo, // 30-90 días
  normal,  // >90 días
}

class MantenimientoPreventivo {
  final String busId;
  final TipoMotor tipoMotor;
  final List<RegistroMantenimiento> historialMantenimientos;
  final DateTime fechaCreacion;

  // Configuraciones personalizadas por filtro (mantener para compatibilidad)
  final Map<TipoFiltro, ConfiguracionMantenimiento> configuracionesPersonalizadas;

  MantenimientoPreventivo({
    required this.busId,
    required this.tipoMotor,
    this.historialMantenimientos = const [],
    required this.fechaCreacion,
    this.configuracionesPersonalizadas = const {},
  });

  // Obtener configuración para un filtro específico (personalizada o predeterminada)
  ConfiguracionMantenimiento getConfiguracion(TipoFiltro filtro) {
    return configuracionesPersonalizadas[filtro] ??
        ConfiguracionMantenimiento.getConfiguracionPredeterminada(filtro, tipoMotor);
  }

  // ✅ NUEVO: Función auxiliar para obtener el título esperado de un filtro
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

  // Calcular estado de mantenimiento para un filtro específico
  EstadoMantenimiento calcularEstado(TipoFiltro filtro, double kilometrajeActual) {
    final configuracion = getConfiguracion(filtro);

    // ✅ CORREGIDO: Buscar último mantenimiento de este tipo (compatible con ambos sistemas)
    final ultimoMantenimiento = historialMantenimientos
        .where((m) {
      // Condición 1: Compatibilidad con registros antiguos (usando enum)
      final esTipoFiltroCompatible = m.tipoFiltro == filtro;
      // Condición 2: Compatibilidad con registros nuevos (usando título)
      final esTituloPersonalizadoCompatible = m.tituloPersonalizado == _getFiltroLabel(filtro);

      return esTipoFiltroCompatible || esTituloPersonalizadoCompatible;
    })
        .fold<RegistroMantenimiento?>(null, (prev, current) {
      if (prev == null) return current;
      return current.fechaUltimoCambio.isAfter(prev.fechaUltimoCambio) ? current : prev;
    });

    DateTime fechaBase;
    double kmBase;

    if (ultimoMantenimiento != null) {
      fechaBase = ultimoMantenimiento.fechaUltimoCambio;
      kmBase = ultimoMantenimiento.kilometrajeUltimoCambio;
    } else {
      // Si no hay historial, usar fecha de creación como base
      fechaBase = fechaCreacion;
      kmBase = 0; // Asumir que empezó sin kilometraje registrado
    }

    // Calcular próximo mantenimiento
    final proximaFecha = fechaBase.add(Duration(days: configuracion.intervalomMeses * 30));
    final proximoKm = kmBase + configuracion.intervalomKilometraje;

    // Calcular días y km restantes
    final diasRestantes = proximaFecha.difference(DateTime.now()).inDays;
    final kmRestantes = proximoKm - kilometrajeActual;

    // Determinar urgencia
    NivelUrgencia urgencia;
    if (diasRestantes < 0 || kmRestantes < 0) {
      urgencia = NivelUrgencia.critico;
    } else if (diasRestantes <= 7 || kmRestantes <= 1000) {
      urgencia = NivelUrgencia.critico;
    } else if (diasRestantes <= 30 || kmRestantes <= 3000) {
      urgencia = NivelUrgencia.urgente;
    } else if (diasRestantes <= 90 || kmRestantes <= 10000) {
      urgencia = NivelUrgencia.proximo;
    } else {
      urgencia = NivelUrgencia.normal;
    }

    return EstadoMantenimiento(
      tipoFiltro: filtro,
      proximoMantenimientoFecha: proximaFecha,
      proximoMantenimientoKm: proximoKm,
      diasRestantes: diasRestantes,
      kmRestantes: kmRestantes,
      urgencia: urgencia,
    );
  }

  // Obtener todos los estados de mantenimiento
  List<EstadoMantenimiento> obtenerTodosLosEstados(double kilometrajeActual) {
    return TipoFiltro.values
        .map((filtro) => calcularEstado(filtro, kilometrajeActual))
        .toList();
  }

  // Obtener estados críticos o urgentes
  List<EstadoMantenimiento> obtenerEstadosCriticos(double kilometrajeActual) {
    return obtenerTodosLosEstados(kilometrajeActual)
        .where((estado) =>
    estado.urgencia == NivelUrgencia.critico ||
        estado.urgencia == NivelUrgencia.urgente)
        .toList();
  }

  // ✅ NUEVOS MÉTODOS para mantenimientos personalizados
  List<RegistroMantenimiento> get mantenimientosPersonalizados {
    return historialMantenimientos.where((m) => m.esMantenimientoPersonalizado).toList();
  }

  List<RegistroMantenimiento> get mantenimientosFiltros {
    return historialMantenimientos.where((m) => m.esMantenimientoFiltro).toList();
  }

  List<RegistroMantenimiento> mantenimientosPorTipo(TipoMantenimiento tipo) {
    return historialMantenimientos.where((m) => m.tipoMantenimientoEfectivo == tipo).toList();
  }

  Map<String, dynamic> toJson() => {
    'busId': busId,
    'tipoMotor': tipoMotor.toString(),
    'historialMantenimientos': historialMantenimientos.map((m) => m.toJson()).toList(),
    'fechaCreacion': fechaCreacion.toIso8601String(),
    'configuracionesPersonalizadas': configuracionesPersonalizadas.map(
            (key, value) => MapEntry(key.toString(), value.toJson())
    ),
  };

  factory MantenimientoPreventivo.fromJson(Map<String, dynamic> json) {
    Map<TipoFiltro, ConfiguracionMantenimiento> configuraciones = {};

    if (json['configuracionesPersonalizadas'] != null) {
      final configMap = json['configuracionesPersonalizadas'] as Map<String, dynamic>;
      configMap.forEach((key, value) {
        final tipoFiltro = TipoFiltro.values.firstWhere((e) => e.toString() == key);
        configuraciones[tipoFiltro] = ConfiguracionMantenimiento.fromJson(value);
      });
    }

    return MantenimientoPreventivo(
      busId: json['busId'],
      tipoMotor: TipoMotor.values.firstWhere((e) => e.toString() == json['tipoMotor']),
      historialMantenimientos: (json['historialMantenimientos'] as List? ?? [])
          .map((m) => RegistroMantenimiento.fromJson(m))
          .toList(),
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      configuracionesPersonalizadas: configuraciones,
    );
  }

  MantenimientoPreventivo copyWith({
    String? busId,
    TipoMotor? tipoMotor,
    List<RegistroMantenimiento>? historialMantenimientos,
    DateTime? fechaCreacion,
    Map<TipoFiltro, ConfiguracionMantenimiento>? configuracionesPersonalizadas,
  }) {
    return MantenimientoPreventivo(
      busId: busId ?? this.busId,
      tipoMotor: tipoMotor ?? this.tipoMotor,
      historialMantenimientos: historialMantenimientos ?? this.historialMantenimientos,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      configuracionesPersonalizadas: configuracionesPersonalizadas ?? this.configuracionesPersonalizadas,
    );
  }
}