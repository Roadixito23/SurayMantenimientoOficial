import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/bus.dart';
import '../../../../models/mantenimiento_preventivo.dart';
import '../../../../models/tipo_mantenimiento_personalizado.dart';
import '../../../../services/data_service.dart';
import '../../../../services/chilean_utils.dart';

/// Desktop layout del formulario de bus con 3 tabs
class BusFormDesktopLayout extends StatefulWidget {
  final Bus? bus;

  const BusFormDesktopLayout({Key? key, this.bus}) : super(key: key);

  @override
  _BusFormDesktopLayoutState createState() => _BusFormDesktopLayoutState();
}

class _BusFormDesktopLayoutState extends State<BusFormDesktopLayout> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _identificadorController;
  late TextEditingController _patenteController;
  late TextEditingController _marcaController;
  late TextEditingController _modeloController;
  late TextEditingController _anioController;
  late TextEditingController _numeroChasisController;
  late TextEditingController _numeroMotorController;
  late TextEditingController _capacidadPasajerosController;
  late TextEditingController _ubicacionController;
  late TextEditingController _kilometrajeController;
  late EstadoBus _estado;
  DateTime? _fechaRevisionTecnica;

  // CAMPOS PARA MANTENIMIENTO PREVENTIVO (SIMPLIFICADOS)
  TipoMotor _tipoMotor = TipoMotor.diesel;
  late TextEditingController _promedioKmController;

  // ❌ ELIMINADO: CondicionOperacion y configuraciones personalizadas complejas
  // Las configuraciones personalizadas ahora se manejan a nivel de tipo de mantenimiento

  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeControllers();
  }

  void _initializeControllers() {
    _identificadorController = TextEditingController(text: widget.bus?.identificador ?? '');
    _patenteController = TextEditingController(text: widget.bus?.patente ?? '');
    _marcaController = TextEditingController(text: widget.bus?.marca ?? '');
    _modeloController = TextEditingController(text: widget.bus?.modelo ?? '');
    _anioController = TextEditingController(text: widget.bus?.anio.toString() ?? '');
    _numeroChasisController = TextEditingController(text: widget.bus?.numeroChasis ?? '');
    _numeroMotorController = TextEditingController(text: widget.bus?.numeroMotor ?? '');
    _capacidadPasajerosController = TextEditingController(text: widget.bus?.capacidadPasajeros.toString() ?? '40');
    _ubicacionController = TextEditingController(text: widget.bus?.ubicacionActual ?? '');
    _kilometrajeController = TextEditingController(text: widget.bus?.kilometraje?.toString() ?? '');
    _promedioKmController = TextEditingController(text: widget.bus?.promedioKmMensuales?.toString() ?? '5000');

    _estado = widget.bus?.estado ?? EstadoBus.disponible;
    _fechaRevisionTecnica = widget.bus?.fechaRevisionTecnica;

    // Cargar configuración de mantenimiento si existe
    if (widget.bus?.mantenimientoPreventivo != null) {
      _tipoMotor = widget.bus!.mantenimientoPreventivo!.tipoMotor;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _identificadorController.dispose();
    _patenteController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    _numeroChasisController.dispose();
    _numeroMotorController.dispose();
    _capacidadPasajerosController.dispose();
    _ubicacionController.dispose();
    _kilometrajeController.dispose();
    _promedioKmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.bus != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEditing ? Icons.edit : Icons.add,
            color: Color(0xFF1565C0),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEditing ? 'Editar Vehículo' : 'Nuevo Vehículo'),
                if (isEditing)
                  Text(
                    widget.bus!.identificadorDisplay,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
      content: Container(
        width: 800,
        constraints: BoxConstraints(maxHeight: 650),
        child: Column(
          children: [
            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: Color(0xFF1565C0),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF1565C0),
              tabs: [
                Tab(
                  icon: Icon(Icons.info, size: 20),
                  text: 'Información',
                ),
                Tab(
                  icon: Icon(Icons.build_circle, size: 20),
                  text: 'Mantenimiento',
                ),
                Tab(
                  icon: Icon(Icons.assignment_turned_in, size: 20),
                  text: 'Revisión Técnica',
                ),
              ],
            ),
            SizedBox(height: 16),

            // Contenido de las tabs
            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInformacionTab(),
                    _buildMantenimientoTab(),
                    _buildDocumentosTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _guardarBus,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1565C0),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildInformacionTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información básica
          Text(
            'Información Básica',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
          ),
          SizedBox(height: 16),

          // Identificador y Patente
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _identificadorController,
                  decoration: InputDecoration(
                    labelText: 'Identificador',
                    hintText: 'Ej: 45, BUS01, M001',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.tag),
                    helperText: 'Hasta 9 caracteres (opcional)',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 9,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                  ],
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length > 9) {
                      return 'Máximo 9 caracteres';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _patenteController,
                  decoration: InputDecoration(
                    labelText: 'Patente/Identificador Principal',
                    hintText: 'Ej: AB-CD-12, MAQUINA001, etc.',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.confirmation_number),
                    helperText: 'Acepta cualquier formato de patente',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La patente/identificador es requerido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Marca y Modelo
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _marcaController,
                  decoration: InputDecoration(
                    labelText: 'Marca',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.branding_watermark),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La marca es requerida';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _modeloController,
                  decoration: InputDecoration(
                    labelText: 'Modelo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.model_training),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El modelo es requerido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Año y Capacidad
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _anioController,
                  decoration: InputDecoration(
                    labelText: 'Año',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El año es requerido';
                    }
                    final anio = int.tryParse(value);
                    final currentYear = DateTime.now().year;
                    if (anio == null || anio < 1900 || anio > currentYear + 2) {
                      return 'Año inválido (1900-${currentYear + 2})';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _capacidadPasajerosController,
                  decoration: InputDecoration(
                    labelText: 'Capacidad Pasajeros',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                    suffixText: 'asientos',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La capacidad es requerida';
                    }
                    final capacidad = int.tryParse(value);
                    if (capacidad == null || capacidad < 1 || capacidad > 200) {
                      return 'Capacidad inválida (1-200)';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Ubicación y Kilometraje
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ubicacionController,
                  decoration: InputDecoration(
                    labelText: 'Ubicación Actual',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                    hintText: 'Ej: Terminal Norte, Taller, etc.',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _kilometrajeController,
                  decoration: InputDecoration(
                    labelText: 'Kilometraje',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.speed),
                    suffixText: 'km',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Información técnica
          Text(
            'Información Técnica',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
          ),
          SizedBox(height: 16),

          // Número de chasis
          TextFormField(
            controller: _numeroChasisController,
            decoration: InputDecoration(
              labelText: 'Número de Chasis (VIN)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.tag),
              hintText: 'WDB9301761234567',
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          SizedBox(height: 16),

          // Número de motor
          TextFormField(
            controller: _numeroMotorController,
            decoration: InputDecoration(
              labelText: 'Número de Motor',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.settings),
              hintText: 'OM926LA123456',
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          SizedBox(height: 16),

          // Estado
          DropdownButtonFormField<EstadoBus>(
            value: _estado,
            decoration: InputDecoration(
              labelText: 'Estado',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.info),
            ),
            items: EstadoBus.values.map((estado) {
              String label;
              IconData icon;
              Color color;

              switch (estado) {
                case EstadoBus.disponible:
                  label = 'Disponible';
                  icon = Icons.check_circle;
                  color = Colors.green;
                  break;
                case EstadoBus.enReparacion:
                  label = 'En Reparación';
                  icon = Icons.build;
                  color = Colors.orange;
                  break;
                case EstadoBus.fueraDeServicio:
                  label = 'Fuera de Servicio';
                  icon = Icons.cancel;
                  color = Colors.red;
                  break;
              }

              return DropdownMenuItem(
                value: estado,
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    SizedBox(width: 8),
                    Text(label),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _estado = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMantenimientoTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuración de Mantenimiento',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
          ),
          SizedBox(height: 16),

          // Información simplificada
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[600]),
                    SizedBox(width: 8),
                    Text(
                      'Sistema de Mantenimiento Modernizado',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700]),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'El sistema ahora utiliza tipos de mantenimiento personalizados que se configuran '
                      'al registrar cada mantenimiento. Solo necesitas configurar el tipo de motor básico aquí.',
                  style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Tipo de motor (simplificado)
          DropdownButtonFormField<TipoMotor>(
            value: _tipoMotor,
            decoration: InputDecoration(
              labelText: 'Tipo de Motor',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.settings),
              helperText: 'Configuración básica para el sistema de mantenimiento',
            ),
            items: TipoMotor.values.map((tipo) {
              return DropdownMenuItem(
                value: tipo,
                child: Row(
                  children: [
                    Icon(
                      Icons.local_gas_station,
                      size: 20,
                      color: Colors.brown,
                    ),
                    SizedBox(width: 8),
                    Text('Diésel'),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _tipoMotor = value!;
              });
            },
          ),

          SizedBox(height: 16),

          // Promedio kilómetros mensuales
          TextFormField(
            controller: _promedioKmController,
            decoration: InputDecoration(
              labelText: 'Promedio de Kilómetros Mensuales',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.trending_up),
              suffixText: 'km/mes',
              helperText: 'Usado para calcular fechas de mantenimiento estimadas',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),

          SizedBox(height: 24),

          // Estado actual del mantenimiento (solo para edición)
          if (widget.bus != null) _buildEstadoMantenimientoActual(),
        ],
      ),
    );
  }

  Widget _buildDocumentosTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documentación y Revisiones',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
          ),
          SizedBox(height: 16),

          // Revisión técnica
          InkWell(
            onTap: _seleccionarFechaRevision,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Fecha de Vencimiento Revisión Técnica',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.assignment_turned_in),
                suffixIcon: Icon(Icons.calendar_today),
                helperText: 'Opcional - Fecha de vencimiento de documentos',
              ),
              child: Text(
                _fechaRevisionTecnica != null
                    ? ChileanUtils.formatDate(_fechaRevisionTecnica!)
                    : 'Seleccionar fecha (opcional)',
                style: TextStyle(
                  color: _fechaRevisionTecnica != null ? Colors.black : Colors.grey[600],
                ),
              ),
            ),
          ),

          if (_fechaRevisionTecnica != null) ...[
            SizedBox(height: 16),
            _buildRevisionTecnicaStatus(),
          ],

          SizedBox(height: 24),

          if (widget.bus != null) ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información del Registro:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text('Fecha de registro: ${ChileanUtils.formatDate(widget.bus!.fechaRegistro)}'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.history, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text('Mantenciones registradas: ${widget.bus!.historialMantenciones.length}'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.build, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text('Repuestos asignados: ${widget.bus!.repuestosAsignados.length}'),
                    ],
                  ),
                  if (widget.bus!.mantenimientoPreventivo != null) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.build_circle, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text('Total mantenimientos: ${widget.bus!.totalMantenimientosRealizados}'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstadoMantenimientoActual() {
    if (widget.bus!.mantenimientoPreventivo == null) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Este vehículo aún no tiene configuración de mantenimiento. Se configurará automáticamente al guardar.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final estadisticas = widget.bus!.estadisticasMantenimientosPorTipo;
    final totalMantenimientos = widget.bus!.totalMantenimientosRealizados;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.green[700]),
              SizedBox(width: 8),
              Text(
                'Estadísticas de Mantenimiento',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text('Total de mantenimientos realizados: $totalMantenimientos'),
          SizedBox(height: 8),
          if (estadisticas.isNotEmpty) ...[
            Text('Distribución por tipo:'),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: estadisticas.entries.map((entry) {
                if (entry.value == 0) return SizedBox.shrink();

                Color color;
                IconData icon;
                String label;

                switch (entry.key) {
                  case TipoMantenimiento.correctivo:
                    color = Color(0xFFE53E3E);
                    icon = Icons.handyman;
                    label = 'Correctivo';
                    break;
                  case TipoMantenimiento.rutinario:
                    color = Color(0xFF3182CE);
                    icon = Icons.schedule;
                    label = 'Rutinario';
                    break;
                  case TipoMantenimiento.preventivo:
                    color = Color(0xFF38A169);
                    icon = Icons.build_circle;
                    label = 'Preventivo';
                    break;
                }

                return Chip(
                  avatar: Icon(icon, size: 14, color: Colors.white),
                  label: Text(
                    '$label: ${entry.value}',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  backgroundColor: color,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],

          if (widget.bus!.ultimoMantenimiento != null) ...[
            SizedBox(height: 12),
            Text(
              'Último mantenimiento: ${widget.bus!.ultimoMantenimiento!.descripcionTipo} '
                  '(${ChileanUtils.formatDate(widget.bus!.ultimoMantenimiento!.fechaUltimoCambio)})',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRevisionTecnicaStatus() {
    if (_fechaRevisionTecnica == null) return SizedBox.shrink();

    final diasRestantes = _fechaRevisionTecnica!.difference(DateTime.now()).inDays;
    Color color;
    String mensaje;
    IconData icon;

    if (diasRestantes < 0) {
      color = Colors.red;
      mensaje = 'VENCIDA hace ${-diasRestantes} días';
      icon = Icons.error;
    } else if (diasRestantes <= 30) {
      color = Colors.orange;
      mensaje = 'Vence en $diasRestantes días';
      icon = Icons.warning;
    } else {
      color = Colors.green;
      mensaje = 'Vigente ($diasRestantes días restantes)';
      icon = Icons.check_circle;
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Text(
            mensaje,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _seleccionarFechaRevision() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaRevisionTecnica ?? DateTime.now().add(Duration(days: 180)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365 * 5)),
      helpText: 'Seleccionar fecha de vencimiento',
    );

    if (fecha != null) {
      setState(() {
        _fechaRevisionTecnica = fecha;
      });
    }
  }

  Future<bool> _validarPatenteUnica(String patente) async {
    try {
      final buses = await DataService.getBuses();
      return !buses.any((b) =>
      b.patente.toUpperCase() == patente.toUpperCase() &&
          b.id != widget.bus?.id);
    } catch (e) {
      return true;
    }
  }

  Future<bool> _validarIdentificadorUnico(String identificador) async {
    if (identificador.isEmpty) return true;

    try {
      final buses = await DataService.getBuses();
      return !buses.any((b) =>
      (b.identificador?.toUpperCase() ?? '') == identificador.toUpperCase() &&
          b.id != widget.bus?.id);
    } catch (e) {
      return true;
    }
  }

  void _guardarBus() async {
    if (!_formKey.currentState!.validate()) return;

    final patenteUnica = await _validarPatenteUnica(_patenteController.text.trim());
    if (!patenteUnica) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ya existe un vehículo con esta patente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final identificadorUnico = await _validarIdentificadorUnico(_identificadorController.text.trim());
    if (!identificadorUnico) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ya existe un vehículo con este identificador'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(Duration(milliseconds: 300));

    try {
      // Crear o actualizar configuración de mantenimiento preventivo (SIMPLIFICADA)
      MantenimientoPreventivo? mantenimientoPreventivo;
      if (widget.bus?.mantenimientoPreventivo != null) {
        // Actualizar configuración existente
        mantenimientoPreventivo = widget.bus!.mantenimientoPreventivo!.copyWith(
          tipoMotor: _tipoMotor,
          // ❌ ELIMINADO: condicionOperacion y configuracionesPersonalizadas
        );
      } else {
        // Crear nueva configuración (SIMPLIFICADA)
        mantenimientoPreventivo = MantenimientoPreventivo(
          busId: widget.bus?.id ?? '',
          tipoMotor: _tipoMotor,
          fechaCreacion: DateTime.now(),
          // ❌ ELIMINADO: condicionOperacion y configuracionesPersonalizadas
        );
      }

      final bus = Bus(
        id: widget.bus?.id ?? '',
        identificador: _identificadorController.text.trim().isEmpty
            ? null
            : _identificadorController.text.toUpperCase().trim(),
        patente: _patenteController.text.toUpperCase().trim(),
        marca: _marcaController.text.trim(),
        modelo: _modeloController.text.trim(),
        anio: int.parse(_anioController.text),
        estado: _estado,
        historialMantenciones: widget.bus?.historialMantenciones ?? [],
        repuestosAsignados: widget.bus?.repuestosAsignados ?? [],
        historialReportes: widget.bus?.historialReportes ?? [],
        fechaRegistro: widget.bus?.fechaRegistro ?? DateTime.now(),
        fechaRevisionTecnica: _fechaRevisionTecnica,
        numeroChasis: _numeroChasisController.text.trim().isEmpty ? null : _numeroChasisController.text.trim(),
        numeroMotor: _numeroMotorController.text.trim().isEmpty ? null : _numeroMotorController.text.trim(),
        capacidadPasajeros: int.parse(_capacidadPasajerosController.text),
        ubicacionActual: _ubicacionController.text.trim().isEmpty ? null : _ubicacionController.text.trim(),
        kilometraje: _kilometrajeController.text.trim().isEmpty ? null : double.parse(_kilometrajeController.text),
        mantenimientoPreventivo: mantenimientoPreventivo,
        promedioKmMensuales: double.parse(_promedioKmController.text),
        ultimaActualizacionKm: DateTime.now(),
      );

      if (widget.bus == null) {
        await DataService.addBus(bus);
      } else {
        await DataService.updateBus(bus);
      }

      Navigator.of(context).pop(bus);

      final displayName = bus.identificador != null && bus.identificador!.isNotEmpty
          ? '${bus.identificador} (${bus.patente})'
          : bus.patente;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.bus == null
                ? 'Vehículo $displayName agregado exitosamente'
                : 'Vehículo $displayName actualizado exitosamente',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el vehículo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}