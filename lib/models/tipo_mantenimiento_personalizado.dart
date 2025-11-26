import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum TipoMantenimiento {
  correctivo,
  rutinario,
  preventivo,
}

class TipoMantenimientoPersonalizado {
  final String id;
  final String titulo;
  final String? descripcion;
  final TipoMantenimiento tipoBase;
  final DateTime fechaCreacion;
  final int vecesUsado;
  final bool activo;
  final bool esFiltroCritico; // ✅ NUEVO: Para identificar filtros que pueden generar alertas

  TipoMantenimientoPersonalizado({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.tipoBase,
    required this.fechaCreacion,
    this.vecesUsado = 1,
    this.activo = true,
    this.esFiltroCritico = false, // ✅ NUEVO
  });

  // Métodos de utilidad para obtener información del tipo base
  String get tipoBaseLabel {
    switch (tipoBase) {
      case TipoMantenimiento.correctivo:
        return 'Correctivo';
      case TipoMantenimiento.rutinario:
        return 'Rutinario';
      case TipoMantenimiento.preventivo:
        return 'Preventivo';
    }
  }

  String get tipoBaseDescripcion {
    switch (tipoBase) {
      case TipoMantenimiento.correctivo:
        return 'Reparación de fallos o averías';
      case TipoMantenimiento.rutinario:
        return 'Mantenimiento programado regular';
      case TipoMantenimiento.preventivo:
        return 'Prevención de fallos futuros';
    }
  }

  Color get tipoBaseColor {
    switch (tipoBase) {
      case TipoMantenimiento.correctivo:
        return Color(0xFFE53E3E); // Rojo
      case TipoMantenimiento.rutinario:
        return Color(0xFF3182CE); // Azul
      case TipoMantenimiento.preventivo:
        return Color(0xFF38A169); // Verde
    }
  }

  IconData get tipoBaseIcon {
    switch (tipoBase) {
      case TipoMantenimiento.correctivo:
        return Icons.handyman; // Reparación
      case TipoMantenimiento.rutinario:
        return Icons.schedule; // Programado
      case TipoMantenimiento.preventivo:
        return Icons.build_circle; // Preventivo
    }
  }

  // ✅ NUEVO: Getter para obtener el icono específico del filtro crítico
  IconData get iconoEspecifico {
    if (!esFiltroCritico) return tipoBaseIcon;

    switch (titulo) {
      case 'Filtro de Aceite':
        return Icons.opacity;
      case 'Filtro de Aire':
        return Icons.air;
      case 'Filtro de Combustible':
        return Icons.local_gas_station;
      default:
        return tipoBaseIcon;
    }
  }

  // ✅ NUEVO: Getter para obtener el color específico del filtro crítico
  Color get colorEspecifico {
    if (!esFiltroCritico) return tipoBaseColor;

    switch (titulo) {
      case 'Filtro de Aceite':
        return Color(0xFFFF9800); // Naranja
      case 'Filtro de Aire':
        return Color(0xFF9E9E9E); // Gris
      case 'Filtro de Combustible':
        return Color(0xFF795548); // Marrón
      default:
        return tipoBaseColor;
    }
  }

  // Métodos de serialización
  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'descripcion': descripcion,
    'tipoBase': tipoBase.toString(),
    'fechaCreacion': fechaCreacion.toIso8601String(),
    'vecesUsado': vecesUsado,
    'activo': activo,
    'esFiltroCritico': esFiltroCritico, // ✅ NUEVO
  };

  factory TipoMantenimientoPersonalizado.fromJson(Map<String, dynamic> json) {
    return TipoMantenimientoPersonalizado(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      tipoBase: TipoMantenimiento.values.firstWhere(
            (e) => e.toString() == json['tipoBase'],
      ),
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      vecesUsado: json['vecesUsado'] ?? 1,
      activo: json['activo'] ?? true,
      esFiltroCritico: json['esFiltroCritico'] ?? false, // ✅ NUEVO
    );
  }

  // Método copyWith para actualizaciones
  TipoMantenimientoPersonalizado copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    TipoMantenimiento? tipoBase,
    DateTime? fechaCreacion,
    int? vecesUsado,
    bool? activo,
    bool? esFiltroCritico,
  }) {
    return TipoMantenimientoPersonalizado(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      tipoBase: tipoBase ?? this.tipoBase,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      vecesUsado: vecesUsado ?? this.vecesUsado,
      activo: activo ?? this.activo,
      esFiltroCritico: esFiltroCritico ?? this.esFiltroCritico,
    );
  }

  // Incrementar contador de uso
  TipoMantenimientoPersonalizado incrementarUso() {
    return copyWith(vecesUsado: vecesUsado + 1);
  }

  // ✅ ACTUALIZADO: Tipos predeterminados del sistema con filtros críticos destacados
  static List<TipoMantenimientoPersonalizado> get tiposPredeterminados => [
    // ✅ FILTROS CRÍTICOS PRINCIPALES (Los que requiere el usuario)
    TipoMantenimientoPersonalizado(
      id: 'filtro_aceite_critico',
      titulo: 'Filtro de Aceite',
      descripcion: 'Cambio preventivo del filtro de aceite del motor. Crítico para alertas de kilometraje.',
      tipoBase: TipoMantenimiento.preventivo,
      fechaCreacion: DateTime.now(),
      vecesUsado: 0,
      esFiltroCritico: true, // ✅ MARCADO COMO CRÍTICO
    ),
    TipoMantenimientoPersonalizado(
      id: 'filtro_aire_critico',
      titulo: 'Filtro de Aire',
      descripcion: 'Cambio preventivo del filtro de aire del motor. Crítico para alertas de kilometraje.',
      tipoBase: TipoMantenimiento.preventivo,
      fechaCreacion: DateTime.now(),
      vecesUsado: 0,
      esFiltroCritico: true, // ✅ MARCADO COMO CRÍTICO
    ),
    TipoMantenimientoPersonalizado(
      id: 'filtro_combustible_critico',
      titulo: 'Filtro de Combustible',
      descripcion: 'Cambio preventivo del filtro de combustible. Crítico para alertas de kilometraje.',
      tipoBase: TipoMantenimiento.preventivo,
      fechaCreacion: DateTime.now(),
      vecesUsado: 0,
      esFiltroCritico: true, // ✅ MARCADO COMO CRÍTICO
    ),

    // CORRECTIVOS
    TipoMantenimientoPersonalizado(
      id: 'correctivo_motor',
      titulo: 'Reparación Motor',
      descripcion: 'Reparación de componentes del motor',
      tipoBase: TipoMantenimiento.correctivo,
      fechaCreacion: DateTime.now(),
      vecesUsado: 0,
    ),
    TipoMantenimientoPersonalizado(
      id: 'correctivo_frenos',
      titulo: 'Reparación Frenos',
      descripcion: 'Reparación del sistema de frenos',
      tipoBase: TipoMantenimiento.correctivo,
      fechaCreacion: DateTime.now(),
      vecesUsado: 0,
    ),
    TipoMantenimientoPersonalizado(
      id: 'correctivo_suspension',
      titulo: 'Reparación Suspensión',
      descripcion: 'Reparación del sistema de suspensión',
      tipoBase: TipoMantenimiento.correctivo,
      fechaCreacion: DateTime.now(),
      vecesUsado: 0,
    ),
    TipoMantenimientoPersonalizado(
      id: 'correctivo_electrico',
      titulo: 'Reparación Eléctrica',
      descripcion: 'Reparación del sistema eléctrico',
      tipoBase: TipoMantenimiento.correctivo,
      fechaCreacion: DateTime.now(),
      vecesUsado: 0,
    ),

    // RUTINARIOS
    TipoMantenimientoPersonalizado(
      id: 'rutinario_inspeccion',
      titulo: 'Inspección General',
      descripcion: 'Inspección rutinaria de seguridad',
      tipoBase: TipoMantenimiento.rutinario,
      fechaCreacion: DateTime.now(),
      vecesUsado: 0,
    ),
    TipoMantenimientoPersonalizado(
      id: 'rutinario_limpieza',
      titulo: 'Limpieza y Mantenimiento',
      descripcion: 'Limpieza general del vehículo',
      tipoBase: TipoMantenimiento.rutinario,
      fechaCreacion: DateTime.now(),
      vecesUsado: 0,
    ),
    TipoMantenimientoPersonalizado(
      id: 'rutinario_revision',
      titulo: 'Revisión Técnica',
      descripcion: 'Revisión técnica programada',
      tipoBase: TipoMantenimiento.rutinario,
      fechaCreacion: DateTime.now(),
      vecesUsado: 0,
    ),

    // PREVENTIVOS ADICIONALES
    TipoMantenimientoPersonalizado(
      id: 'preventivo_pastillas',
      titulo: 'Cambio de Pastillas de Freno',
      descripcion: 'Cambio preventivo de pastillas de freno',
      tipoBase: TipoMantenimiento.preventivo,
      fechaCreacion: DateTime.now(),
      vecesUsado: 0,
    ),
    TipoMantenimientoPersonalizado(
      id: 'preventivo_neumaticos',
      titulo: 'Rotación de Neumáticos',
      descripcion: 'Rotación y revisión de neumáticos',
      tipoBase: TipoMantenimiento.preventivo,
      fechaCreacion: DateTime.now(),
      vecesUsado: 0,
    ),
  ];

  // ✅ NUEVO: Getter para obtener solo los filtros críticos
  static List<TipoMantenimientoPersonalizado> get filtrosCriticos =>
      tiposPredeterminados.where((tipo) => tipo.esFiltroCritico).toList();

  @override
  String toString() => titulo;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is TipoMantenimientoPersonalizado &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}