import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/bus.dart';
import '../models/repuesto.dart';
import '../models/repuesto_asignado.dart';
import '../models/reporte_diario.dart';
import '../models/mantenimiento_preventivo.dart';
import '../models/tipo_mantenimiento_personalizado.dart'; // ✅ NUEVO IMPORT

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Nombres de las colecciones
  static const String _busesCollection = 'buses';
  static const String _repuestosCollection = 'repuestos_catalogo';
  static const String _repuestosAsignadosCollection = 'repuestos_asignados';
  static const String _reportesCollection = 'reportes_diarios';
  static const String _filtrosCollection = 'filtros_repuestos';
  static const String _tiposMantenimientoCollection = 'tipos_mantenimiento_personalizados'; // ✅ NUEVA COLECCIÓN

  // =============================================================================
  // ✅ NUEVOS MÉTODOS PARA TIPOS DE MANTENIMIENTO PERSONALIZADOS
  // =============================================================================

  static Future<List<TipoMantenimientoPersonalizado>> getTiposMantenimientoPersonalizados() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_tiposMantenimientoCollection)
          .orderBy('vecesUsado', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return TipoMantenimientoPersonalizado.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error al obtener tipos de mantenimiento: $e');
      return [];
    }
  }

  static Future<String> addTipoMantenimientoPersonalizado(TipoMantenimientoPersonalizado tipo) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(_tiposMantenimientoCollection)
          .add(tipo.toJson());
      return docRef.id;
    } catch (e) {
      print('Error al agregar tipo de mantenimiento: $e');
      throw Exception('Error al guardar el tipo de mantenimiento: $e');
    }
  }

  static Future<void> updateTipoMantenimientoPersonalizado(TipoMantenimientoPersonalizado tipo) async {
    try {
      await _firestore
          .collection(_tiposMantenimientoCollection)
          .doc(tipo.id)
          .update(tipo.toJson());
    } catch (e) {
      print('Error al actualizar tipo de mantenimiento: $e');
      throw Exception('Error al actualizar el tipo de mantenimiento: $e');
    }
  }

  static Future<void> deleteTipoMantenimientoPersonalizado(String id) async {
    try {
      await _firestore.collection(_tiposMantenimientoCollection).doc(id).delete();
    } catch (e) {
      print('Error al eliminar tipo de mantenimiento: $e');
      throw Exception('Error al eliminar el tipo de mantenimiento: $e');
    }
  }

  static Future<TipoMantenimientoPersonalizado?> getTipoMantenimientoPersonalizadoById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_tiposMantenimientoCollection)
          .doc(id)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return TipoMantenimientoPersonalizado.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error al obtener tipo de mantenimiento por ID: $e');
      return null;
    }
  }

  // =============================================================================
  // MÉTODOS PARA BUSES (MANTENER SIN CAMBIOS SIGNIFICATIVOS)
  // =============================================================================

  static Future<List<Bus>> getBuses() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_busesCollection).get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Bus.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error al obtener buses: $e');
      return [];
    }
  }

  static Future<String> addBus(Bus bus) async {
    try {
      DocumentReference docRef = await _firestore.collection(_busesCollection).add(bus.toJson());
      return docRef.id;
    } catch (e) {
      print('Error al agregar bus: $e');
      throw Exception('Error al guardar el bus: $e');
    }
  }

  static Future<void> updateBus(Bus bus) async {
    try {
      await _firestore.collection(_busesCollection).doc(bus.id).update(bus.toJson());
    } catch (e) {
      print('Error al actualizar bus: $e');
      throw Exception('Error al actualizar el bus: $e');
    }
  }

  static Future<void> deleteBus(String id) async {
    try {
      await _firestore.collection(_busesCollection).doc(id).delete();
      // También eliminar repuestos asignados a este bus
      QuerySnapshot repuestosAsignados = await _firestore
          .collection(_repuestosAsignadosCollection)
          .where('busId', isEqualTo: id)
          .get();

      for (QueryDocumentSnapshot doc in repuestosAsignados.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error al eliminar bus: $e');
      throw Exception('Error al eliminar el bus: $e');
    }
  }

  static Future<Bus?> getBusById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_busesCollection).doc(id).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Bus.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error al obtener bus por ID: $e');
      return null;
    }
  }

  // =============================================================================
  // MÉTODOS PARA CATÁLOGO DE REPUESTOS (SIN CAMBIOS)
  // =============================================================================

  static Future<List<RepuestoCatalogo>> getCatalogoRepuestos() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_repuestosCollection).get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return RepuestoCatalogo.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error al obtener catálogo de repuestos: $e');
      return [];
    }
  }

  static Future<String> addRepuestoCatalogo(RepuestoCatalogo repuesto) async {
    try {
      DocumentReference docRef = await _firestore.collection(_repuestosCollection).add(repuesto.toJson());
      return docRef.id;
    } catch (e) {
      print('Error al agregar repuesto: $e');
      throw Exception('Error al guardar el repuesto: $e');
    }
  }

  static Future<void> updateRepuestoCatalogo(RepuestoCatalogo repuesto) async {
    try {
      await _firestore.collection(_repuestosCollection).doc(repuesto.id).update(repuesto.toJson());
    } catch (e) {
      print('Error al actualizar repuesto: $e');
      throw Exception('Error al actualizar el repuesto: $e');
    }
  }

  static Future<void> deleteRepuestoCatalogo(String id) async {
    try {
      await _firestore.collection(_repuestosCollection).doc(id).delete();
    } catch (e) {
      print('Error al eliminar repuesto: $e');
      throw Exception('Error al eliminar el repuesto: $e');
    }
  }

  static Future<RepuestoCatalogo?> getRepuestoCatalogoById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_repuestosCollection).doc(id).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return RepuestoCatalogo.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error al obtener repuesto por ID: $e');
      return null;
    }
  }

  // =============================================================================
  // MÉTODOS PARA REPUESTOS ASIGNADOS (SIN CAMBIOS)
  // =============================================================================

  static Future<List<RepuestoAsignado>> getRepuestosAsignados() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_repuestosAsignadosCollection).get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return RepuestoAsignado.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error al obtener repuestos asignados: $e');
      return [];
    }
  }

  static Future<String> addRepuestoAsignado(RepuestoAsignado repuesto) async {
    try {
      DocumentReference docRef = await _firestore.collection(_repuestosAsignadosCollection).add(repuesto.toJson());
      return docRef.id;
    } catch (e) {
      print('Error al agregar repuesto asignado: $e');
      throw Exception('Error al guardar el repuesto asignado: $e');
    }
  }

  static Future<void> updateRepuestoAsignado(RepuestoAsignado repuesto) async {
    try {
      await _firestore.collection(_repuestosAsignadosCollection).doc(repuesto.id).update(repuesto.toJson());
    } catch (e) {
      print('Error al actualizar repuesto asignado: $e');
      throw Exception('Error al actualizar el repuesto asignado: $e');
    }
  }

  static Future<void> deleteRepuestoAsignado(String id) async {
    try {
      await _firestore.collection(_repuestosAsignadosCollection).doc(id).delete();
    } catch (e) {
      print('Error al eliminar repuesto asignado: $e');
      throw Exception('Error al eliminar el repuesto asignado: $e');
    }
  }

  static Future<List<RepuestoAsignado>> getRepuestosAsignadosPorBus(String busId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_repuestosAsignadosCollection)
          .where('busId', isEqualTo: busId)
          .get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return RepuestoAsignado.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error al obtener repuestos por bus: $e');
      return [];
    }
  }

  // =============================================================================
  // MÉTODOS PARA REPORTES (SIN CAMBIOS)
  // =============================================================================

  static Future<List<ReporteDiario>> getReportes() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_reportesCollection)
          .orderBy('fecha', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ReporteDiario.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error al obtener reportes: $e');
      return [];
    }
  }

  static Future<String> addReporte(ReporteDiario reporte) async {
    try {
      DocumentReference docRef = await _firestore.collection(_reportesCollection).add(reporte.toJson());
      return docRef.id;
    } catch (e) {
      print('Error al agregar reporte: $e');
      throw Exception('Error al guardar el reporte: $e');
    }
  }

  static Future<void> updateReporte(ReporteDiario reporte) async {
    try {
      await _firestore.collection(_reportesCollection).doc(reporte.id).update(reporte.toJson());
    } catch (e) {
      print('Error al actualizar reporte: $e');
      throw Exception('Error al actualizar el reporte: $e');
    }
  }

  static Future<void> deleteReporte(String id) async {
    try {
      await _firestore.collection(_reportesCollection).doc(id).delete();
    } catch (e) {
      print('Error al eliminar reporte: $e');
      throw Exception('Error al eliminar el reporte: $e');
    }
  }

  static Future<ReporteDiario?> getReporteById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_reportesCollection).doc(id).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ReporteDiario.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error al obtener reporte por ID: $e');
      return null;
    }
  }

  static Future<List<ReporteDiario>> getReportesPorFecha(DateTime fecha) async {
    try {
      DateTime startOfDay = DateTime(fecha.year, fecha.month, fecha.day);
      DateTime endOfDay = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);

      QuerySnapshot snapshot = await _firestore
          .collection(_reportesCollection)
          .where('fecha', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('fecha', isLessThanOrEqualTo: endOfDay.toIso8601String())
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ReporteDiario.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error al obtener reportes por fecha: $e');
      return [];
    }
  }

  // =============================================================================
  // MÉTODOS PARA FILTROS DE REPUESTOS (SIN CAMBIOS)
  // =============================================================================

  static Future<List<FiltroRepuesto>> getFiltrosRepuestos() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_filtrosCollection).get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return FiltroRepuesto.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error al obtener filtros: $e');
      return [];
    }
  }

  static Future<String> addFiltroRepuesto(FiltroRepuesto filtro) async {
    try {
      DocumentReference docRef = await _firestore.collection(_filtrosCollection).add(filtro.toJson());
      return docRef.id;
    } catch (e) {
      print('Error al agregar filtro: $e');
      throw Exception('Error al guardar el filtro: $e');
    }
  }

  static Future<void> updateFiltroRepuesto(FiltroRepuesto filtro) async {
    try {
      await _firestore.collection(_filtrosCollection).doc(filtro.id).update(filtro.toJson());
    } catch (e) {
      print('Error al actualizar filtro: $e');
      throw Exception('Error al actualizar el filtro: $e');
    }
  }

  static Future<void> deleteFiltroRepuesto(String id) async {
    try {
      await _firestore.collection(_filtrosCollection).doc(id).delete();
    } catch (e) {
      print('Error al eliminar filtro: $e');
      throw Exception('Error al eliminar el filtro: $e');
    }
  }

  // =============================================================================
  // MÉTODOS DE INICIALIZACIÓN ACTUALIZADOS
  // =============================================================================

  static Future<void> initializeSampleData() async {
    try {
      // Verificar si ya hay datos
      QuerySnapshot busesSnapshot = await _firestore.collection(_busesCollection).limit(1).get();
      if (busesSnapshot.docs.isNotEmpty) {
        print('Los datos de ejemplo ya existen');
        return;
      }

      print('Inicializando datos de ejemplo...');

      // ✅ NUEVO: Inicializar tipos de mantenimiento personalizados
      await _initializeTiposMantenimientoPersonalizados();

      // Inicializar filtros predeterminados
      await _initializeFiltrosPredeterminados();

      // ✅ ACTUALIZADO: Inicializar buses de ejemplo CON KILOMETRAJE IDEAL
      await _initializeSampleBusesWithMaintenance();

      // Inicializar catálogo de repuestos
      await _initializeCatalogoRepuestos();

      // Inicializar reportes de ejemplo
      await _initializeSampleReportes();

      print('Datos de ejemplo inicializados correctamente');
    } catch (e) {
      print('Error al inicializar datos de ejemplo: $e');
      throw Exception('Error al inicializar datos: $e');
    }
  }

// ✅ NUEVO MÉTODO: Inicializar tipos de mantenimiento personalizados con filtros críticos
  static Future<void> _initializeTiposMantenimientoPersonalizados() async {
    final tiposPredeterminados = TipoMantenimientoPersonalizado.tiposPredeterminados;

    for (final tipo in tiposPredeterminados) {
      await _firestore.collection(_tiposMantenimientoCollection).doc(tipo.id).set(tipo.toJson());
    }

    print('Tipos de mantenimiento personalizados inicializados: ${tiposPredeterminados.length}');

    // ✅ NUEVO: Contar y reportar filtros críticos
    final filtrosCriticos = tiposPredeterminados.where((t) => t.esFiltroCritico).length;
    print('Filtros críticos configurados para alertas de kilometraje: $filtrosCriticos');
    print('Umbral configurado: 5000 km/mes');
  }



  static Future<void> _initializeFiltrosPredeterminados() async {
    final filtros = [
      FiltroRepuesto(
        id: 'filtro_agua',
        nombre: 'Agua',
        descripcion: 'Filtros y componentes relacionados con agua',
        palabrasClave: ['agua', 'water', 'líquido', 'bomba agua', 'radiador', 'refrigerante'],
        color: Color(0xFF2196F3),
        icono: Icons.water_drop,
        esPredeterminado: true,
      ),
      FiltroRepuesto(
        id: 'filtro_aceite',
        nombre: 'Aceite',
        descripcion: 'Filtros y componentes relacionados con aceite',
        palabrasClave: ['aceite', 'oil', 'lubricante', 'filtro aceite', 'bomba aceite'],
        color: Color(0xFFFF9800),
        icono: Icons.opacity,
        esPredeterminado: true,
      ),
      FiltroRepuesto(
        id: 'filtro_aire',
        nombre: 'Aire',
        descripcion: 'Filtros y componentes relacionados con aire',
        palabrasClave: ['aire', 'air', 'filtro aire', 'compresor', 'válvula aire'],
        color: Color(0xFF9E9E9E),
        icono: Icons.air,
        esPredeterminado: true,
      ),
    ];

    for (final filtro in filtros) {
      await _firestore.collection(_filtrosCollection).doc(filtro.id).set(filtro.toJson());
    }
  }

  // ✅ ACTUALIZADO: Se añade el campo `kilometrajeIdeal` a los buses de ejemplo.
  static Future<void> _initializeSampleBusesWithMaintenance() async {
    final buses = [
      Bus(
        id: 'bus_1',
        patente: 'AB-CD-12',
        identificador: '001',
        marca: 'Mercedes-Benz',
        modelo: 'Citaro',
        anio: 2020,
        estado: EstadoBus.disponible,
        historialMantenciones: [],
        fechaRegistro: DateTime.now().subtract(Duration(days: 30)),
        fechaRevisionTecnica: DateTime.now().add(Duration(days: 90)),
        numeroChasis: 'WDB9301761234567',
        numeroMotor: 'OM926LA123456',
        capacidadPasajeros: 85,
        ubicacionActual: 'Terminal Norte',
        kilometraje: 45000,
        kilometrajeIdeal: 55000, // ✅ NUEVO
        mantenimientoPreventivo: MantenimientoPreventivo(
          busId: 'bus_1',
          tipoMotor: TipoMotor.diesel,
          fechaCreacion: DateTime.now().subtract(Duration(days: 30)),
          historialMantenimientos: [
            RegistroMantenimiento(
              id: 'mant_1',
              tipoFiltro: TipoFiltro.aceite,
              fechaUltimoCambio: DateTime.now().subtract(Duration(days: 100)),
              kilometrajeUltimoCambio: 15000,
              tecnicoResponsable: 'Juan Pérez',
              observaciones: 'Cambio de filtro de aceite rutinario',
              marcaRepuesto: 'Mann Filter',
              tipoMantenimiento: TipoMantenimiento.preventivo,
              tituloPersonalizado: 'Filtro de Aceite',
            ),
          ],
        ),
        promedioKmMensuales: 2500.0,
        ultimaActualizacionKm: DateTime.now().subtract(Duration(days: 5)),
      ),
      Bus(
        id: 'bus_2',
        patente: 'EF-GH-34',
        identificador: '002',
        marca: 'Volvo',
        modelo: 'B12M',
        anio: 2019,
        estado: EstadoBus.enReparacion,
        historialMantenciones: [],
        fechaRegistro: DateTime.now().subtract(Duration(days: 25)),
        fechaRevisionTecnica: DateTime.now().add(Duration(days: 15)),
        numeroChasis: 'YV1NH1234567890',
        numeroMotor: 'D12D123456',
        capacidadPasajeros: 50,
        ubicacionActual: 'Taller Principal',
        kilometraje: 67000,
        kilometrajeIdeal: 65000, // ✅ NUEVO: Este bus activará una alerta
        mantenimientoPreventivo: MantenimientoPreventivo(
          busId: 'bus_2',
          tipoMotor: TipoMotor.diesel,
          fechaCreacion: DateTime.now().subtract(Duration(days: 25)),
          historialMantenimientos: [
            RegistroMantenimiento(
              id: 'mant_2',
              tipoFiltro: TipoFiltro.combustible,
              fechaUltimoCambio: DateTime.now().subtract(Duration(days: 200)),
              kilometrajeUltimoCambio: 37000,
              tecnicoResponsable: 'María González',
              observaciones: 'Cambio de filtro de combustible',
              marcaRepuesto: 'Bosch',
              tipoMantenimiento: TipoMantenimiento.preventivo,
              tituloPersonalizado: 'Filtro de Combustible',
            ),
          ],
        ),
        promedioKmMensuales: 3000.0,
        ultimaActualizacionKm: DateTime.now().subtract(Duration(days: 2)),
      ),
      Bus(
        id: 'bus_3',
        patente: 'IJ-KL-56',
        identificador: '003',
        marca: 'Scania',
        modelo: 'K410',
        anio: 2021,
        estado: EstadoBus.disponible,
        historialMantenciones: [],
        fechaRegistro: DateTime.now().subtract(Duration(days: 15)),
        fechaRevisionTecnica: DateTime.now().subtract(Duration(days: 10)),
        numeroChasis: 'XLBSA2345678901',
        numeroMotor: 'DC1202123456',
        capacidadPasajeros: 45,
        ubicacionActual: 'Terminal Sur',
        kilometraje: 23000,
        kilometrajeIdeal: 33000, // ✅ NUEVO
        mantenimientoPreventivo: MantenimientoPreventivo(
          busId: 'bus_3',
          tipoMotor: TipoMotor.diesel,
          fechaCreacion: DateTime.now().subtract(Duration(days: 15)),
          historialMantenimientos: [],
        ),
        promedioKmMensuales: 1800.0,
        ultimaActualizacionKm: DateTime.now().subtract(Duration(days: 1)),
      ),
      Bus(
        id: 'bus_4',
        patente: 'MN-OP-78',
        identificador: '004',
        marca: 'Iveco',
        modelo: 'Crossway',
        anio: 2018,
        estado: EstadoBus.disponible,
        historialMantenciones: [],
        fechaRegistro: DateTime.now().subtract(Duration(days: 45)),
        fechaRevisionTecnica: DateTime.now().add(Duration(days: 120)),
        numeroChasis: 'ZCFC65851234567',
        numeroMotor: 'F4AE3481123456',
        capacidadPasajeros: 55,
        ubicacionActual: 'Terminal Central',
        kilometraje: 89000,
        kilometrajeIdeal: 99000, // ✅ NUEVO
        mantenimientoPreventivo: MantenimientoPreventivo(
          busId: 'bus_4',
          tipoMotor: TipoMotor.diesel,
          fechaCreacion: DateTime.now().subtract(Duration(days: 45)),
          historialMantenimientos: [
            RegistroMantenimiento(
              id: 'mant_4',
              tipoFiltro: TipoFiltro.aceite,
              fechaUltimoCambio: DateTime.now().subtract(Duration(days: 180)),
              kilometrajeUltimoCambio: 59000,
              tecnicoResponsable: 'Carlos López',
              observaciones: 'Mantenimiento programado completado',
              marcaRepuesto: 'Filtron',
              tipoMantenimiento: TipoMantenimiento.preventivo,
              tituloPersonalizado: 'Filtro de Aceite',
            ),
            RegistroMantenimiento(
              id: 'mant_4_2',
              tipoFiltro: TipoFiltro.aire,
              fechaUltimoCambio: DateTime.now().subtract(Duration(days: 90)),
              kilometrajeUltimoCambio: 74000,
              tecnicoResponsable: 'Ana Ruiz',
              observaciones: 'Filtro de aire reemplazado por obstrucción',
              marcaRepuesto: 'Donaldson',
              tipoMantenimiento: TipoMantenimiento.preventivo,
              tituloPersonalizado: 'Filtro de Aire',
            ),
          ],
        ),
        promedioKmMensuales: 2200.0,
        ultimaActualizacionKm: DateTime.now().subtract(Duration(days: 3)),
      ),
      Bus(
        id: 'bus_5',
        patente: 'QR-ST-90',
        marca: 'MAN',
        modelo: 'Lion City',
        anio: 2022,
        estado: EstadoBus.fueraDeServicio,
        historialMantenciones: [],
        fechaRegistro: DateTime.now().subtract(Duration(days: 10)),
        fechaRevisionTecnica: DateTime.now().add(Duration(days: 300)),
        numeroChasis: 'WMA13XZZ1234567',
        numeroMotor: 'D2066LF123456',
        capacidadPasajeros: 70,
        ubicacionActual: 'Taller Especializado',
        kilometraje: 12000,
        kilometrajeIdeal: 22000, // ✅ NUEVO
        // Sin configuración de mantenimiento preventivo para demostrar el estado "sin configurar"
        promedioKmMensuales: 1500.0,
        ultimaActualizacionKm: DateTime.now().subtract(Duration(days: 4)),
      ),
    ];

    for (final bus in buses) {
      await _firestore.collection(_busesCollection).doc(bus.id).set(bus.toJson());
    }
  }

  static Future<void> _initializeCatalogoRepuestos() async {
    final repuestos = [
      RepuestoCatalogo(
        id: 'rep_1',
        nombre: 'Filtro de Aceite Motor',
        codigo: 'FLT-ACE-001',
        descripcion: 'Filtro de aceite para motor diésel. Compatible con diversos modelos de buses urbanos.',
        sistema: SistemaVehiculo.motor,
        tipo: TipoRepuesto.original,
        fabricante: 'Mann Filter',
        numeroOEM: 'W950/26',
        precioReferencial: 25000,
        observaciones: 'Cambiar cada 15,000 km. Verificar compatibilidad antes de instalación.',
        fechaActualizacion: DateTime.now(),
      ),
      RepuestoCatalogo(
        id: 'rep_2',
        nombre: 'Filtro de Aire Motor',
        codigo: 'FLT-AIR-001',
        descripcion: 'Filtro de aire principal para sistema de admisión. Alta eficiencia de filtrado.',
        sistema: SistemaVehiculo.motor,
        tipo: TipoRepuesto.alternativo,
        fabricante: 'Donaldson',
        numeroOEM: 'P776695',
        precioReferencial: 45000,
        observaciones: 'Inspeccionar cada 10,000 km. Cambiar cuando esté sucio o cada 30,000 km.',
        fechaActualizacion: DateTime.now(),
      ),
      RepuestoCatalogo(
        id: 'rep_3',
        nombre: 'Pastillas de Freno Delanteras',
        codigo: 'FRN-PAS-001',
        descripcion: 'Juego completo de pastillas de freno para eje delantero. Material libre de asbesto.',
        sistema: SistemaVehiculo.frenos,
        tipo: TipoRepuesto.original,
        fabricante: 'Brembo',
        numeroOEM: 'P06033',
        precioReferencial: 120000,
        observaciones: 'Verificar grosor mínimo 3mm. Cambiar en conjunto con discos si es necesario.',
        fechaActualizacion: DateTime.now(),
      ),
      RepuestoCatalogo(
        id: 'rep_4',
        nombre: 'Filtro de Combustible',
        codigo: 'FLT-CMB-001',
        descripcion: 'Filtro separador de agua para sistema de combustible diésel. Previene contaminación.',
        sistema: SistemaVehiculo.combustible,
        tipo: TipoRepuesto.generico,
        fabricante: 'Parker Racor',
        precioReferencial: 35000,
        observaciones: 'Drenar agua semanalmente. Cambiar filtro cada 20,000 km o cuando se obstruya.',
        fechaActualizacion: DateTime.now(),
      ),
      RepuestoCatalogo(
        id: 'rep_5',
        nombre: 'Amortiguador Delantero',
        codigo: 'SUS-AMO-001',
        descripcion: 'Amortiguador telescópico para eje delantero. Mejora estabilidad y confort.',
        sistema: SistemaVehiculo.suspension,
        tipo: TipoRepuesto.original,
        fabricante: 'Monroe',
        numeroOEM: 'G7377',
        precioReferencial: 180000,
        observaciones: 'Cambiar en pares. Verificar bujes y soportes al mismo tiempo.',
        fechaActualizacion: DateTime.now(),
      ),
      RepuestoCatalogo(
        id: 'rep_6',
        nombre: 'Correa del Alternador',
        codigo: 'ELE-COR-001',
        descripcion: 'Correa trapezoidal para accionamiento del alternador. Material reforzado.',
        sistema: SistemaVehiculo.electrico,
        tipo: TipoRepuesto.alternativo,
        fabricante: 'Gates',
        numeroOEM: '6PK1720',
        precioReferencial: 35000,
        observaciones: 'Verificar tensión regularmente. Cambiar cada 60,000 km o si presenta grietas.',
        fechaActualizacion: DateTime.now(),
      ),
      RepuestoCatalogo(
        id: 'rep_7',
        nombre: 'Neumático 275/70R22.5',
        codigo: 'NEU-DIR-001',
        descripcion: 'Neumático direccional para eje delantero. Compuesto especial para buses urbanos.',
        sistema: SistemaVehiculo.neumaticos,
        tipo: TipoRepuesto.original,
        fabricante: 'Michelin',
        numeroOEM: 'X MULTIWAY 3D',
        precioReferencial: 350000,
        observaciones: 'Rotar cada 20,000 km. Verificar presión semanalmente (120 PSI).',
        fechaActualizacion: DateTime.now(),
      ),
      RepuestoCatalogo(
        id: 'rep_8',
        nombre: 'Bomba de Agua',
        codigo: 'REF-BOM-001',
        descripcion: 'Bomba centrífuga para sistema de refrigeración. Incluye junta y tornillería.',
        sistema: SistemaVehiculo.refrigeracion,
        tipo: TipoRepuesto.original,
        fabricante: 'Febi Bilstein',
        numeroOEM: '01262',
        precioReferencial: 185000,
        observaciones: 'Cambiar líquido refrigerante al mismo tiempo. Verificar termostato.',
        fechaActualizacion: DateTime.now(),
      ),
    ];

    for (final repuesto in repuestos) {
      await _firestore.collection(_repuestosCollection).doc(repuesto.id).set(repuesto.toJson());
    }
  }



  static Future<void> _initializeSampleReportes() async {
    final reportes = [
      ReporteDiario(
        id: 'rep_1',
        fecha: DateTime.now().subtract(Duration(days: 1)),
        numeroReporte: '001/${DateTime.now().subtract(Duration(days: 1)).day.toString().padLeft(2, '0')}/${DateTime.now().subtract(Duration(days: 1)).month.toString().padLeft(2, '0')}/${DateTime.now().subtract(Duration(days: 1)).year.toString().substring(2)}',
        observaciones: 'Mantenimiento preventivo realizado en buses de la flota. Se cambió aceite de motor y filtros en AB-CD-12. Revisión general de sistemas de frenos y suspensión en EF-GH-34.',
        busesAtendidos: ['AB-CD-12', 'EF-GH-34'],
        autor: 'Juan Pérez',
      ),
      ReporteDiario(
        id: 'rep_2',
        fecha: DateTime.now(),
        numeroReporte: '001/${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year.toString().substring(2)}',
        observaciones: 'Inspección rutinaria de flota completa. Se realizó diagnóstico con scanner en todos los vehículos. Resto de la flota sin novedades.',
        busesAtendidos: ['AB-CD-12', 'EF-GH-34', 'IJ-KL-56'],
        autor: 'María González',
      ),
    ];

    for (final reporte in reportes) {
      await _firestore.collection(_reportesCollection).doc(reporte.id).set(reporte.toJson());
    }
  }
}