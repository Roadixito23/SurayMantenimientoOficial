import 'package:flutter/material.dart';

class RepuestoAsignado {
  final String id;
  final String repuestoCatalogoId;
  final String busId;
  final DateTime fechaAsignacion;
  final int cantidad;
  final String? ubicacionBus; // Ej: "Motor", "Eje delantero", etc.
  final DateTime? fechaInstalacion;
  final DateTime? proximoCambio;
  final String? observaciones;
  final bool instalado;
  final String? tecnicoResponsable;

  RepuestoAsignado({
    required this.id,
    required this.repuestoCatalogoId,
    required this.busId,
    required this.fechaAsignacion,
    required this.cantidad,
    this.ubicacionBus,
    this.fechaInstalacion,
    this.proximoCambio,
    this.observaciones,
    this.instalado = false,
    this.tecnicoResponsable,
  });



  Map<String, dynamic> toJson() => {
    'id': id,
    'repuestoCatalogoId': repuestoCatalogoId,
    'busId': busId,
    'fechaAsignacion': fechaAsignacion.toIso8601String(),
    'cantidad': cantidad,
    'ubicacionBus': ubicacionBus,
    'fechaInstalacion': fechaInstalacion?.toIso8601String(),
    'proximoCambio': proximoCambio?.toIso8601String(),
    'observaciones': observaciones,
    'instalado': instalado,
    'tecnicoResponsable': tecnicoResponsable,
  };

  factory RepuestoAsignado.fromJson(Map<String, dynamic> json) => RepuestoAsignado(
    id: json['id'],
    repuestoCatalogoId: json['repuestoCatalogoId'],
    busId: json['busId'],
    fechaAsignacion: DateTime.parse(json['fechaAsignacion']),
    cantidad: json['cantidad'],
    ubicacionBus: json['ubicacionBus'],
    fechaInstalacion: json['fechaInstalacion'] != null
        ? DateTime.parse(json['fechaInstalacion'])
        : null,
    proximoCambio: json['proximoCambio'] != null
        ? DateTime.parse(json['proximoCambio'])
        : null,
    observaciones: json['observaciones'],
    instalado: json['instalado'] ?? false,
    tecnicoResponsable: json['tecnicoResponsable'],
  );

  RepuestoAsignado copyWith({
    String? id,
    String? repuestoCatalogoId,
    String? busId,
    DateTime? fechaAsignacion,
    int? cantidad,
    String? ubicacionBus,
    DateTime? fechaInstalacion,
    DateTime? proximoCambio,
    String? observaciones,
    bool? instalado,
    String? tecnicoResponsable,
  }) {
    return RepuestoAsignado(
      id: id ?? this.id,
      repuestoCatalogoId: repuestoCatalogoId ?? this.repuestoCatalogoId,
      busId: busId ?? this.busId,
      fechaAsignacion: fechaAsignacion ?? this.fechaAsignacion,
      cantidad: cantidad ?? this.cantidad,
      ubicacionBus: ubicacionBus ?? this.ubicacionBus,
      fechaInstalacion: fechaInstalacion ?? this.fechaInstalacion,
      proximoCambio: proximoCambio ?? this.proximoCambio,
      observaciones: observaciones ?? this.observaciones,
      instalado: instalado ?? this.instalado,
      tecnicoResponsable: tecnicoResponsable ?? this.tecnicoResponsable,
    );
  }
}

// Modelo para filtros personalizables de repuestos
class FiltroRepuesto {
  final String id;
  final String nombre;
  final String descripcion;
  final List<String> palabrasClave;
  final Color color;
  final IconData icono;
  final bool esPredeterminado;

  FiltroRepuesto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.palabrasClave,
    required this.color,
    required this.icono,
    this.esPredeterminado = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'descripcion': descripcion,
    'palabrasClave': palabrasClave,
    'color': color.value,
    'icono': icono.codePoint,
    'esPredeterminado': esPredeterminado,
  };

  factory FiltroRepuesto.fromJson(Map<String, dynamic> json) => FiltroRepuesto(
    id: json['id'],
    nombre: json['nombre'],
    descripcion: json['descripcion'],
    palabrasClave: List<String>.from(json['palabrasClave']),
    color: Color(json['color']),
    icono: IconData(json['icono'], fontFamily: 'MaterialIcons'),
    esPredeterminado: json['esPredeterminado'] ?? false,
  );
}