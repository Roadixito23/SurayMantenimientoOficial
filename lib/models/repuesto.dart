enum SistemaVehiculo {
  motor,
  transmision,
  frenos,
  suspension,
  electrico,
  neumaticos,
  carroceria,
  climatizacion,
  combustible,
  refrigeracion,
}

enum TipoRepuesto {
  original,
  alternativo,
  generico,
}

class RepuestoCatalogo {
  final String id;
  final String nombre;
  final String codigo;
  final String descripcion;
  final SistemaVehiculo sistema;
  final TipoRepuesto tipo;
  final String? fabricante;
  final String? numeroOEM;
  final int? precioReferencial;
  final String? observaciones;
  final DateTime fechaActualizacion;

  RepuestoCatalogo({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.descripcion,
    required this.sistema,
    required this.tipo,
    this.fabricante,
    this.numeroOEM,
    this.precioReferencial,
    this.observaciones,
    required this.fechaActualizacion,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'codigo': codigo,
    'descripcion': descripcion,
    'sistema': sistema.toString(),
    'tipo': tipo.toString(),
    'fabricante': fabricante,
    'numeroOEM': numeroOEM,
    'precioReferencial': precioReferencial,
    'observaciones': observaciones,
    'fechaActualizacion': fechaActualizacion.toIso8601String(),
  };

  factory RepuestoCatalogo.fromJson(Map<String, dynamic> json) => RepuestoCatalogo(
    id: json['id'],
    nombre: json['nombre'],
    codigo: json['codigo'],
    descripcion: json['descripcion'],
    sistema: SistemaVehiculo.values.firstWhere((e) => e.toString() == json['sistema']),
    tipo: TipoRepuesto.values.firstWhere((e) => e.toString() == json['tipo']),
    fabricante: json['fabricante'],
    numeroOEM: json['numeroOEM'],
    precioReferencial: json['precioReferencial'],
    observaciones: json['observaciones'],
    fechaActualizacion: DateTime.parse(json['fechaActualizacion']),
  );

  RepuestoCatalogo copyWith({
    String? id,
    String? nombre,
    String? codigo,
    String? descripcion,
    SistemaVehiculo? sistema,
    TipoRepuesto? tipo,
    String? fabricante,
    String? numeroOEM,
    int? precioReferencial,
    String? observaciones,
    DateTime? fechaActualizacion,
  }) {
    return RepuestoCatalogo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      descripcion: descripcion ?? this.descripcion,
      sistema: sistema ?? this.sistema,
      tipo: tipo ?? this.tipo,
      fabricante: fabricante ?? this.fabricante,
      numeroOEM: numeroOEM ?? this.numeroOEM,
      precioReferencial: precioReferencial ?? this.precioReferencial,
      observaciones: observaciones ?? this.observaciones,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  // Métodos de utilidad
  String get sistemaLabel {
    switch (sistema) {
      case SistemaVehiculo.motor:
        return 'Motor';
      case SistemaVehiculo.transmision:
        return 'Transmisión';
      case SistemaVehiculo.frenos:
        return 'Frenos';
      case SistemaVehiculo.suspension:
        return 'Suspensión';
      case SistemaVehiculo.electrico:
        return 'Sistema Eléctrico';
      case SistemaVehiculo.neumaticos:
        return 'Neumáticos y Ruedas';
      case SistemaVehiculo.carroceria:
        return 'Carrocería';
      case SistemaVehiculo.climatizacion:
        return 'Climatización';
      case SistemaVehiculo.combustible:
        return 'Sistema de Combustible';
      case SistemaVehiculo.refrigeracion:
        return 'Refrigeración';
    }
  }

  String get tipoLabel {
    switch (tipo) {
      case TipoRepuesto.original:
        return 'Original (OEM)';
      case TipoRepuesto.alternativo:
        return 'Alternativo';
      case TipoRepuesto.generico:
        return 'Genérico';
    }
  }
}