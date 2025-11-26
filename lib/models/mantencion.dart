class Mantencion {
  final String id;
  final DateTime fecha;
  final String descripcion;
  final List<String> repuestosUsados;
  final int? costoTotal; // Cambiado a nullable para consistencia
  final bool completada;

  Mantencion({
    required this.id,
    required this.fecha,
    required this.descripcion,
    required this.repuestosUsados,
    this.costoTotal, // Ahora es opcional
    required this.completada,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fecha': fecha.toIso8601String(),
    'descripcion': descripcion,
    'repuestosUsados': repuestosUsados,
    'costoTotal': costoTotal,
    'completada': completada,
  };

  factory Mantencion.fromJson(Map<String, dynamic> json) => Mantencion(
    id: json['id'],
    fecha: DateTime.parse(json['fecha']),
    descripcion: json['descripcion'],
    repuestosUsados: List<String>.from(json['repuestosUsados']),
    costoTotal: json['costoTotal'], // Puede ser null
    completada: json['completada'],
  );

  Mantencion copyWith({
    String? id,
    DateTime? fecha,
    String? descripcion,
    List<String>? repuestosUsados,
    int? costoTotal,
    bool? completada,
  }) {
    return Mantencion(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      descripcion: descripcion ?? this.descripcion,
      repuestosUsados: repuestosUsados ?? this.repuestosUsados,
      costoTotal: costoTotal ?? this.costoTotal,
      completada: completada ?? this.completada,
    );
  }
}