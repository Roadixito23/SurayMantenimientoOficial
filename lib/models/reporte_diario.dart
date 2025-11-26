import 'package:flutter/material.dart';

class ReporteDiario {
  final String id;
  final DateTime fecha;
  final String numeroReporte; // Formato "001/13/06/25"
  final String observaciones;
  final List<String> busesAtendidos; // Buses trabajados
  final String autor;
  final String? tipoTrabajo; // NUEVO: Tipo de trabajo realizado

  ReporteDiario({
    required this.id,
    required this.fecha,
    required this.numeroReporte,
    required this.observaciones,
    required this.busesAtendidos,
    required this.autor,
    this.tipoTrabajo, // Nuevo campo opcional
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fecha': fecha.toIso8601String(),
    'numeroReporte': numeroReporte,
    'observaciones': observaciones,
    'busesAtendidos': busesAtendidos,
    'autor': autor,
    'tipoTrabajo': tipoTrabajo, // Incluir en JSON
  };

  factory ReporteDiario.fromJson(Map<String, dynamic> json) => ReporteDiario(
    id: json['id'],
    fecha: DateTime.parse(json['fecha']),
    numeroReporte: json['numeroReporte'] ?? '',
    observaciones: json['observaciones'],
    busesAtendidos: List<String>.from(json['busesAtendidos'] ?? json['busesReparados'] ?? []),
    autor: json['autor'],
    tipoTrabajo: json['tipoTrabajo'], // Cargar desde JSON
  );

  ReporteDiario copyWith({
    String? id,
    DateTime? fecha,
    String? numeroReporte,
    String? observaciones,
    List<String>? busesAtendidos,
    String? autor,
    String? tipoTrabajo,
  }) {
    return ReporteDiario(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      numeroReporte: numeroReporte ?? this.numeroReporte,
      observaciones: observaciones ?? this.observaciones,
      busesAtendidos: busesAtendidos ?? this.busesAtendidos,
      autor: autor ?? this.autor,
      tipoTrabajo: tipoTrabajo ?? this.tipoTrabajo,
    );
  }

  // Getter para mantener compatibilidad con código existente
  List<String> get busesReparados => busesAtendidos;

  // NUEVO: Extraer tipo de trabajo del contenido si no está definido explícitamente
  String get tipoTrabajoDisplay {
    if (tipoTrabajo != null) return tipoTrabajo!;

    // Intentar extraer del contenido para reportes antiguos
    final lines = observaciones.split('\n');
    for (final line in lines) {
      if (line.startsWith('TIPO DE TRABAJO:')) {
        return line.replaceFirst('TIPO DE TRABAJO:', '').trim();
      }
    }

    return 'Sin Categorizar'; // Valor por defecto
  }

  // NUEVO: Determinar color según el tipo de trabajo
  Color get colorTipoTrabajo {
    switch (tipoTrabajoDisplay) {
      case 'Mantenimiento Rutinario':
        return Colors.blue;
      case 'Reparación Correctiva':
        return Colors.red;
      case 'Inspección Técnica':
        return Colors.purple;
      case 'Mantenimiento Preventivo':
        return Colors.green;
      case 'Diagnóstico':
        return Colors.orange;
      case 'Limpieza y Mantenimiento':
        return Colors.teal;
      case 'Otros':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // NUEVO: Obtener icono según el tipo de trabajo
  IconData get iconoTipoTrabajo {
    switch (tipoTrabajoDisplay) {
      case 'Mantenimiento Rutinario':
        return Icons.schedule;
      case 'Reparación Correctiva':
        return Icons.build;
      case 'Inspección Técnica':
        return Icons.search;
      case 'Mantenimiento Preventivo':
        return Icons.shield;
      case 'Diagnóstico':
        return Icons.analytics;
      case 'Limpieza y Mantenimiento':
        return Icons.cleaning_services;
      case 'Otros':
        return Icons.more_horiz;
      default:
        return Icons.description;
    }
  }
}