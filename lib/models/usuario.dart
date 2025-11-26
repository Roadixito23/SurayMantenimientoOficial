import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String id;
  final String nombreUsuario;
  final String contrasena; // En un sistema real, esto debería estar hasheado
  final DateTime fechaCreacion;
  final DateTime? ultimaActualizacion;

  Usuario({
    required this.id,
    required this.nombreUsuario,
    required this.contrasena,
    required this.fechaCreacion,
    this.ultimaActualizacion,
  });

  // Convertir de Firestore Document a Usuario
  factory Usuario.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Usuario(
      id: doc.id,
      nombreUsuario: data['nombreUsuario'] ?? '',
      contrasena: data['contrasena'] ?? '',
      fechaCreacion: (data['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ultimaActualizacion: (data['ultimaActualizacion'] as Timestamp?)?.toDate(),
    );
  }

  // Convertir Usuario a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombreUsuario': nombreUsuario,
      'contrasena': contrasena,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'ultimaActualizacion': ultimaActualizacion != null
          ? Timestamp.fromDate(ultimaActualizacion!)
          : null,
    };
  }

  // Crear copia con campos modificados
  Usuario copyWith({
    String? id,
    String? nombreUsuario,
    String? contrasena,
    DateTime? fechaCreacion,
    DateTime? ultimaActualizacion,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      contrasena: contrasena ?? this.contrasena,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      ultimaActualizacion: ultimaActualizacion ?? this.ultimaActualizacion,
    );
  }
}
