import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/bus.dart';
import '../../../../models/repuesto.dart';
import '../../../../models/repuesto_asignado.dart';
import '../../../../services/data_service.dart';
import '../../../../services/chilean_utils.dart';

class AsignarRepuestoMobileLayout extends StatefulWidget {
  final Bus bus;
  final Function()? onRepuestoAsignado;

  const AsignarRepuestoMobileLayout({
    Key? key,
    required this.bus,
    this.onRepuestoAsignado,
  }) : super(key: key);

  @override
  State<AsignarRepuestoMobileLayout> createState() => _AsignarRepuestoMobileLayoutState();
}

class _AsignarRepuestoMobileLayoutState extends State<AsignarRepuestoMobileLayout> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  late TextEditingController _cantidadController;
  late TextEditingController _ubicacionController;
  late TextEditingController _observacionesController;
  late TextEditingController _tecnicoController;
  late TextEditingController _busquedaController;

  RepuestoCatalogo? _repuestoSeleccionado;
  DateTime? _fechaInstalacion;
  DateTime? _proximoCambio;
  bool _instalado = false;
  bool _isLoading = false;
  String _filtroSistema = 'Todos';
  String _filtroBusqueda = '';

  List<RepuestoCatalogo> _catalogoRepuestos = [];
  List<RepuestoCatalogo> _repuestosFiltrados = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cantidadController = TextEditingController(text: '1');
    _ubicacionController = TextEditingController();
    _observacionesController = TextEditingController();
    _tecnicoController = TextEditingController();
    _busquedaController = TextEditingController();
    _cargarCatalogo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cantidadController.dispose();
    _ubicacionController.dispose();
    _observacionesController.dispose();
    _tecnicoController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  void _cargarCatalogo() async {
    final catalogo = await DataService.getCatalogoRepuestos();
    setState(() {
      _catalogoRepuestos = catalogo;
      _aplicarFiltros();
    });
  }

  void _aplicarFiltros() {
    var repuestos = List<RepuestoCatalogo>.from(_catalogoRepuestos);

    if (_filtroSistema != 'Todos') {
      repuestos = repuestos.where((r) => r.sistemaLabel == _filtroSistema).toList();
    }

    if (_filtroBusqueda.isNotEmpty) {
      final busquedaLower = _filtroBusqueda.toLowerCase();
      repuestos = repuestos.where((r) =>
      r.nombre.toLowerCase().contains(busquedaLower) ||
          r.codigo.toLowerCase().contains(busquedaLower) ||
          r.descripcion.toLowerCase().contains(busquedaLower)
      ).toList();
    }

    setState(() {
      _repuestosFiltrados = repuestos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header con gradiente
          Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.add_box, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Asignar Repuesto',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.bus.patente,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Tabs
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Color(0xFF1565C0),
                    unselectedLabelColor: Colors.white,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 18),
                            SizedBox(width: 4),
                            Text('Buscar'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 4),
                            Text('Detalles'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),

          // Contenido de las tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBuscarTab(),
                _buildDetallesTab(),
              ],
            ),
          ),

          // Botón de acción
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading || _repuestoSeleccionado == null ? null : _asignarRepuesto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      : Text(
                    'Asignar Repuesto',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuscarTab() {
    return Column(
      children: [
        // Filtros
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _busquedaController,
                decoration: InputDecoration(
                  labelText: 'Buscar repuesto',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (value) {
                  setState(() {
                    _filtroBusqueda = value;
                    _aplicarFiltros();
                  });
                },
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _filtroSistema,
                decoration: InputDecoration(
                  labelText: 'Filtrar por sistema',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  prefixIcon: Icon(Icons.filter_list),
                ),
                items: _getSistemasDisponibles()
                    .map((sistema) => DropdownMenuItem(
                  value: sistema,
                  child: Text(sistema),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _filtroSistema = value!;
                    _aplicarFiltros();
                  });
                },
              ),
            ],
          ),
        ),

        // Lista de repuestos
        Expanded(
          child: _repuestosFiltrados.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No se encontraron repuestos',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _repuestosFiltrados.length,
            itemBuilder: (context, index) {
              final repuesto = _repuestosFiltrados[index];
              final isSelected = _repuestoSeleccionado?.id == repuesto.id;

              return Card(
                margin: EdgeInsets.only(bottom: 12),
                elevation: isSelected ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? Color(0xFF1565C0) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(12),
                  leading: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getSistemaColor(repuesto.sistema),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getSistemaIcon(repuesto.sistema),
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    repuesto.nombre,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text('${repuesto.codigo}'),
                      Text(repuesto.sistemaLabel),
                      if (repuesto.precioReferencial != null)
                        Text(
                          ChileanUtils.formatCurrency(repuesto.precioReferencial!),
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: Color(0xFF1565C0), size: 32)
                      : Icon(Icons.radio_button_unchecked, color: Colors.grey),
                  onTap: () {
                    setState(() {
                      _repuestoSeleccionado = repuesto;
                      _ubicacionController.text = _getUbicacionSugerida(repuesto.sistema);
                    });
                    // Cambiar a la tab de detalles
                    _tabController.animateTo(1);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetallesTab() {
    if (_repuestoSeleccionado == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_back, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Selecciona un repuesto',
              style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Ve a la pestaña "Buscar" y selecciona un repuesto de la lista',
                style: TextStyle(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del repuesto seleccionado
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[50]!, Colors.blue[100]!],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getSistemaColor(_repuestoSeleccionado!.sistema),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getSistemaIcon(_repuestoSeleccionado!.sistema),
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _repuestoSeleccionado!.nombre,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Código: ${_repuestoSeleccionado!.codigo}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('Sistema: ${_repuestoSeleccionado!.sistemaLabel}'),
                  if (_repuestoSeleccionado!.fabricante != null)
                    Text('Fabricante: ${_repuestoSeleccionado!.fabricante}'),
                ],
              ),
            ),
            SizedBox(height: 24),

            Text(
              'Detalles de Asignación',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
            ),
            SizedBox(height: 16),

            // Formulario
            TextFormField(
              controller: _cantidadController,
              decoration: InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.numbers),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La cantidad es requerida';
                }
                final cantidad = int.tryParse(value);
                if (cantidad == null || cantidad <= 0) {
                  return 'Cantidad inválida';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            TextFormField(
              controller: _ubicacionController,
              decoration: InputDecoration(
                labelText: 'Ubicación en el vehículo',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.location_on),
                hintText: 'Ej: Motor, Eje delantero, etc.',
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            SizedBox(height: 16),

            TextFormField(
              controller: _tecnicoController,
              decoration: InputDecoration(
                labelText: 'Técnico responsable',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.person),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            SizedBox(height: 16),

            Card(
              child: CheckboxListTile(
                title: Text('Repuesto ya instalado'),
                subtitle: Text('Marcar si el repuesto ya está instalado'),
                value: _instalado,
                onChanged: (value) {
                  setState(() {
                    _instalado = value!;
                    if (_instalado) {
                      _fechaInstalacion = DateTime.now();
                    } else {
                      _fechaInstalacion = null;
                      _proximoCambio = null;
                    }
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),

            if (_instalado) ...[
              SizedBox(height: 16),
              InkWell(
                onTap: _seleccionarFechaInstalacion,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha de instalación',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.calendar_today),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  child: Text(
                    _fechaInstalacion != null
                        ? ChileanUtils.formatDate(_fechaInstalacion!)
                        : 'Seleccionar fecha',
                  ),
                ),
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: _seleccionarFechaProximoCambio,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Próximo cambio (opcional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.schedule),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  child: Text(
                    _proximoCambio != null
                        ? ChileanUtils.formatDate(_proximoCambio!)
                        : 'Seleccionar fecha',
                  ),
                ),
              ),
            ],

            SizedBox(height: 16),
            TextFormField(
              controller: _observacionesController,
              decoration: InputDecoration(
                labelText: 'Observaciones',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.note),
                hintText: 'Notas adicionales...',
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 4,
            ),
            SizedBox(height: 80), // Espacio para el botón fijo
          ],
        ),
      ),
    );
  }

  List<String> _getSistemasDisponibles() {
    final sistemas = <String>{'Todos'};
    for (final repuesto in _catalogoRepuestos) {
      sistemas.add(repuesto.sistemaLabel);
    }
    return sistemas.toList()..sort();
  }

  Color _getSistemaColor(SistemaVehiculo sistema) {
    switch (sistema) {
      case SistemaVehiculo.motor:
        return Colors.red;
      case SistemaVehiculo.frenos:
        return Colors.orange;
      case SistemaVehiculo.transmision:
        return Colors.purple;
      case SistemaVehiculo.electrico:
        return Colors.yellow[700]!;
      case SistemaVehiculo.suspension:
        return Colors.green;
      case SistemaVehiculo.neumaticos:
        return Colors.black;
      case SistemaVehiculo.carroceria:
        return Colors.blue;
      case SistemaVehiculo.climatizacion:
        return Colors.cyan;
      case SistemaVehiculo.combustible:
        return Colors.brown;
      case SistemaVehiculo.refrigeracion:
        return Colors.lightBlue;
    }
  }

  IconData _getSistemaIcon(SistemaVehiculo sistema) {
    switch (sistema) {
      case SistemaVehiculo.motor:
        return Icons.settings;
      case SistemaVehiculo.frenos:
        return Icons.disc_full;
      case SistemaVehiculo.transmision:
        return Icons.settings_applications;
      case SistemaVehiculo.electrico:
        return Icons.electrical_services;
      case SistemaVehiculo.suspension:
        return Icons.compare_arrows;
      case SistemaVehiculo.neumaticos:
        return Icons.tire_repair;
      case SistemaVehiculo.carroceria:
        return Icons.directions_bus;
      case SistemaVehiculo.climatizacion:
        return Icons.ac_unit;
      case SistemaVehiculo.combustible:
        return Icons.local_gas_station;
      case SistemaVehiculo.refrigeracion:
        return Icons.thermostat;
    }
  }

  String _getUbicacionSugerida(SistemaVehiculo sistema) {
    switch (sistema) {
      case SistemaVehiculo.motor:
        return 'Compartimento Motor';
      case SistemaVehiculo.frenos:
        return 'Sistema Frenos';
      case SistemaVehiculo.transmision:
        return 'Caja Transmisión';
      case SistemaVehiculo.electrico:
        return 'Tablero Eléctrico';
      case SistemaVehiculo.suspension:
        return 'Eje Delantero';
      case SistemaVehiculo.neumaticos:
        return 'Ruedas';
      case SistemaVehiculo.carroceria:
        return 'Carrocería';
      case SistemaVehiculo.climatizacion:
        return 'Sistema A/C';
      case SistemaVehiculo.combustible:
        return 'Tanque Combustible';
      case SistemaVehiculo.refrigeracion:
        return 'Radiador';
    }
  }

  void _seleccionarFechaInstalacion() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaInstalacion ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Fecha de instalación',
    );

    if (fecha != null) {
      setState(() {
        _fechaInstalacion = fecha;
      });
    }
  }

  void _seleccionarFechaProximoCambio() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _proximoCambio ?? DateTime.now().add(Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 3)),
      helpText: 'Próximo cambio programado',
    );

    if (fecha != null) {
      setState(() {
        _proximoCambio = fecha;
      });
    }
  }

  void _asignarRepuesto() async {
    if (!_formKey.currentState!.validate()) return;
    if (_repuestoSeleccionado == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repuestoAsignado = RepuestoAsignado(
        id: '${widget.bus.id}_${_repuestoSeleccionado!.id}_${DateTime.now().millisecondsSinceEpoch}',
        repuestoCatalogoId: _repuestoSeleccionado!.id,
        busId: widget.bus.id,
        fechaAsignacion: DateTime.now(),
        cantidad: int.parse(_cantidadController.text),
        ubicacionBus: _ubicacionController.text.trim().isEmpty ? null : _ubicacionController.text.trim(),
        fechaInstalacion: _fechaInstalacion,
        proximoCambio: _proximoCambio,
        observaciones: _observacionesController.text.trim().isEmpty ? null : _observacionesController.text.trim(),
        instalado: _instalado,
        tecnicoResponsable: _tecnicoController.text.trim().isEmpty ? null : _tecnicoController.text.trim(),
      );

      await DataService.addRepuestoAsignado(repuestoAsignado);

      if (mounted) {
        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_repuestoSeleccionado!.nombre} asignado a ${widget.bus.patente}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        widget.onRepuestoAsignado?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar repuesto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
