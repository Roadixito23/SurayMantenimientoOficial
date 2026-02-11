import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/bus.dart';
import '../../../../models/repuesto.dart';
import '../../../../models/repuesto_asignado.dart';
import '../../../../services/data_service.dart';
import '../../../../services/chilean_utils.dart';

/// Layout móvil modernizado para gestión de repuestos
/// Paleta de colores basada en el ícono build_circle (azul marino)
class AsignarRepuestoMobileLayout extends StatefulWidget {
  final Bus bus;
  final Function()? onRepuestoAsignado;

  const AsignarRepuestoMobileLayout({
    Key? key,
    required this.bus,
    this.onRepuestoAsignado,
  }) : super(key: key);

  @override
  State<AsignarRepuestoMobileLayout> createState() =>
      _AsignarRepuestoMobileLayoutState();
}

class _AsignarRepuestoMobileLayoutState
    extends State<AsignarRepuestoMobileLayout>
    with SingleTickerProviderStateMixin {
  
  // Paleta de colores basada en el ícono (azul marino profundo)
  static const Color _primaryColor = Color(0xFF2C5F8D);
  static const Color _primaryDark = Color(0xFF1A3B5C);
  static const Color _accentColor = Color(0xFF4CAF50);
  static const Color _accentLight = Color(0xFF81C784);

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
  
  // Para gestión de repuestos asignados
  List<Map<String, dynamic>> _repuestosAsignados = [];
  bool _loadingAsignados = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cantidadController = TextEditingController(text: '1');
    _ubicacionController = TextEditingController();
    _observacionesController = TextEditingController();
    _tecnicoController = TextEditingController();
    _busquedaController = TextEditingController();
    _cargarCatalogo();
    _cargarRepuestosAsignados();
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

  Future<void> _cargarRepuestosAsignados() async {
    setState(() => _loadingAsignados = true);
    try {
      final repuestos = await DataService.getRepuestosAsignadosConInfo(widget.bus.id);
      setState(() {
        _repuestosAsignados = repuestos;
        _loadingAsignados = false;
      });
    } catch (e) {
      setState(() => _loadingAsignados = false);
    }
  }

  void _aplicarFiltros() {
    var repuestos = List<RepuestoCatalogo>.from(_catalogoRepuestos);

    if (_filtroSistema != 'Todos') {
      repuestos =
          repuestos.where((r) => r.sistemaLabel == _filtroSistema).toList();
    }

    if (_filtroBusqueda.isNotEmpty) {
      final busquedaLower = _filtroBusqueda.toLowerCase();
      repuestos = repuestos
          .where((r) =>
              r.nombre.toLowerCase().contains(busquedaLower) ||
              r.codigo.toLowerCase().contains(busquedaLower) ||
              r.descripcion.toLowerCase().contains(busquedaLower))
          .toList();
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
          _buildModernHeader(),
          Expanded(
            child: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabAsignados(),
                  _buildTabBuscar(),
                  _buildTabDetalles(),
                ],
              ),
            ),
          ),
          _buildModernBottomActions(),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryDark, _primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.build_circle, color: Colors.white, size: 28),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestión de Repuestos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.bus.identificadorDisplay,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_repuestosAsignados.length}',
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Tabs modernizados con 3 pestañas
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: _primaryDark,
                unselectedLabelColor: Colors.white,
                labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                tabs: [
                  Tab(
                    icon: Icon(Icons.list_alt, size: 20),
                    text: 'Asignados',
                  ),
                  Tab(
                    icon: Icon(Icons.add_circle, size: 20),
                    text: 'Nuevo',
                  ),
                  Tab(
                    icon: Icon(Icons.assignment, size: 20),
                    text: 'Detalles',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabAsignados() {
    if (_loadingAsignados) {
      return Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    }

    if (_repuestosAsignados.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.build_circle_outlined,
                size: 64,
                color: _primaryColor.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Sin repuestos asignados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Ve a la pestaña "Nuevo" para asignar repuestos',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarRepuestosAsignados,
      color: _primaryColor,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _repuestosAsignados.length,
        itemBuilder: (context, index) {
          final item = _repuestosAsignados[index];
          final asignado = item['repuestoAsignado'] as RepuestoAsignado;
          final catalogo = item['repuestoCatalogo'] as RepuestoCatalogo;
          return _buildRepuestoAsignadoCard(asignado, catalogo);
        },
      ),
    );
  }

  Widget _buildRepuestoAsignadoCard(RepuestoAsignado asignado, RepuestoCatalogo catalogo) {
    final bool vencido = asignado.proximoCambio != null &&
        asignado.proximoCambio!.isBefore(DateTime.now());
    final bool proximoVencer = asignado.proximoCambio != null &&
        !vencido &&
        asignado.proximoCambio!.difference(DateTime.now()).inDays <= 30;

    Color statusColor = asignado.instalado
        ? (vencido ? Colors.red : (proximoVencer ? Colors.orange : _accentColor))
        : _primaryColor;

    String statusText = asignado.instalado
        ? (vencido ? 'Vencido' : (proximoVencer ? 'Próx. vencer' : 'Instalado'))
        : 'Pendiente';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          // Header del repuesto
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getSistemaColor(catalogo.sistema).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getSistemaIcon(catalogo.sistema),
                    color: _getSistemaColor(catalogo.sistema),
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        catalogo.nombre,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${catalogo.codigo} • Cant: ${asignado.cantidad}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Acciones
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _mostrarDetalleRepuesto(asignado, catalogo),
                    icon: Icon(Icons.visibility, size: 18),
                    label: Text('Ver', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: _primaryColor),
                  ),
                ),
                Container(width: 1, height: 24, color: Colors.grey[300]),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _editarRepuestoAsignado(asignado, catalogo),
                    icon: Icon(Icons.edit, size: 18),
                    label: Text('Editar', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange[700]),
                  ),
                ),
                Container(width: 1, height: 24, color: Colors.grey[300]),
                Expanded(
                  child: TextButton.icon(
                    onPressed: asignado.instalado
                        ? null
                        : () => _cambiarEstadoRepuesto(asignado, catalogo),
                    icon: Icon(
                      asignado.instalado ? Icons.check_circle : Icons.pending_actions,
                      size: 18,
                    ),
                    label: Text(
                      asignado.instalado ? 'OK' : 'Instalar',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: asignado.instalado ? Colors.grey : _accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalleRepuesto(RepuestoAsignado asignado, RepuestoCatalogo catalogo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetalleSheet(asignado, catalogo),
    );
  }

  Widget _buildDetalleSheet(RepuestoAsignado asignado, RepuestoCatalogo catalogo) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getSistemaColor(catalogo.sistema).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getSistemaIcon(catalogo.sistema),
                    color: _getSistemaColor(catalogo.sistema),
                    size: 28,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        catalogo.nombre,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Código: ${catalogo.codigo}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailSection('Información del Repuesto', [
                    _buildDetailRow('Sistema', catalogo.sistemaLabel),
                    _buildDetailRow('Tipo', _getTipoLabel(catalogo.tipo)),
                    if (catalogo.fabricante != null)
                      _buildDetailRow('Fabricante', catalogo.fabricante!),
                  ]),
                  SizedBox(height: 16),
                  _buildDetailSection('Asignación', [
                    _buildDetailRow('Cantidad', '${asignado.cantidad}'),
                    _buildDetailRow('Ubicación', asignado.ubicacionBus ?? 'No especificada'),
                    _buildDetailRow('Fecha asignación', ChileanUtils.formatDate(asignado.fechaAsignacion)),
                    _buildDetailRow('Estado', asignado.instalado ? 'Instalado' : 'Pendiente'),
                  ]),
                  if (asignado.instalado) ...[
                    SizedBox(height: 16),
                    _buildDetailSection('Instalación', [
                      if (asignado.fechaInstalacion != null)
                        _buildDetailRow('Fecha instalación', ChileanUtils.formatDate(asignado.fechaInstalacion!)),
                      if (asignado.proximoCambio != null)
                        _buildDetailRow('Próximo cambio', ChileanUtils.formatDate(asignado.proximoCambio!)),
                      if (asignado.tecnicoResponsable != null)
                        _buildDetailRow('Técnico', asignado.tecnicoResponsable!),
                    ]),
                  ],
                  if (asignado.observaciones != null && asignado.observaciones!.isNotEmpty) ...[
                    SizedBox(height: 16),
                    _buildDetailSection('Observaciones', [
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          asignado.observaciones!,
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _editarRepuestoAsignado(RepuestoAsignado asignado, RepuestoCatalogo catalogo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditarRepuestoSheet(
        asignado: asignado,
        catalogo: catalogo,
        primaryColor: _primaryColor,
        onSaved: () {
          Navigator.pop(context);
          _cargarRepuestosAsignados();
          widget.onRepuestoAsignado?.call();
        },
      ),
    );
  }

  void _cambiarEstadoRepuesto(RepuestoAsignado asignado, RepuestoCatalogo catalogo) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _InstalarRepuestoDialog(
        asignado: asignado,
        catalogo: catalogo,
        primaryColor: _primaryColor,
      ),
    );

    if (result != null) {
      try {
        final updated = asignado.copyWith(
          instalado: true,
          fechaInstalacion: result['fechaInstalacion'],
          proximoCambio: result['proximoCambio'],
          tecnicoResponsable: result['tecnico'],
        );
        await DataService.updateRepuestoAsignado(updated);
        _cargarRepuestosAsignados();
        widget.onRepuestoAsignado?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${catalogo.nombre} marcado como instalado'),
            backgroundColor: _accentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildTabBuscar() {
    return Column(
      children: [
        // Filtros modernizados
        Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _busquedaController,
                decoration: InputDecoration(
                  labelText: 'Buscar repuesto',
                  prefixIcon: Icon(Icons.search, color: _primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryColor, width: 2),
                  ),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: Icon(Icons.filter_list, color: _primaryColor),
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

        // Lista de repuestos modernizada
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
                      margin: EdgeInsets.only(bottom: 8),
                      elevation: isSelected ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? _primaryColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12),
                        leading: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getSistemaColor(repuesto.sistema).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getSistemaIcon(repuesto.sistema),
                            size: 24,
                            color: _getSistemaColor(repuesto.sistema),
                          ),
                        ),
                        title: Text(
                          repuesto.nombre,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(
                                '${repuesto.codigo} - ${repuesto.sistemaLabel}'),
                            if (repuesto.precioReferencial != null)
                              Text(
                                ChileanUtils.formatCurrency(
                                    repuesto.precioReferencial!),
                                style: TextStyle(
                                  color: _accentColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: _primaryColor, size: 28)
                            : Icon(Icons.circle_outlined,
                                color: Colors.grey[400]),
                        onTap: () {
                          setState(() {
                            _repuestoSeleccionado = repuesto;
                            _ubicacionController.text =
                                _getUbicacionSugerida(repuesto.sistema);
                          });
                          _tabController.animateTo(2);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTabDetalles() {
    if (_repuestoSeleccionado == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.touch_app, size: 64, color: _primaryColor.withOpacity(0.5)),
              ),
              SizedBox(height: 24),
              Text(
                'Selecciona un repuesto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Ve a la pestaña "Nuevo" y selecciona un repuesto para continuar',
                style: TextStyle(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: Icon(Icons.search),
                label: Text('Ir a Buscar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Repuesto seleccionado con diseño moderno
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor.withOpacity(0.1), _primaryColor.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getSistemaColor(_repuestoSeleccionado!.sistema),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getSistemaIcon(_repuestoSeleccionado!.sistema),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _repuestoSeleccionado!.nombre,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_repuestoSeleccionado!.codigo} • ${_repuestoSeleccionado!.sistemaLabel}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _repuestoSeleccionado = null;
                    });
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Formulario modernizado
          Text(
            'Datos de Asignación',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _primaryColor),
          ),
          SizedBox(height: 16),

          TextFormField(
            controller: _cantidadController,
            decoration: InputDecoration(
              labelText: 'Cantidad',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.numbers, color: _primaryColor),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'La cantidad es requerida';
              final cantidad = int.tryParse(value);
              if (cantidad == null || cantidad <= 0) return 'Cantidad inválida';
              return null;
            },
          ),
          SizedBox(height: 16),

          TextFormField(
            controller: _ubicacionController,
            decoration: InputDecoration(
              labelText: 'Ubicación en el vehículo',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.location_on, color: _primaryColor),
              hintText: 'Ej: Motor, Eje delantero, etc.',
            ),
          ),
          SizedBox(height: 16),

          TextFormField(
            controller: _tecnicoController,
            decoration: InputDecoration(
              labelText: 'Técnico responsable',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.person, color: _primaryColor),
            ),
          ),
          SizedBox(height: 16),

          // Checkbox modernizado
          Container(
            decoration: BoxDecoration(
              color: _instalado ? _accentColor.withOpacity(0.1) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _instalado ? _accentColor : Colors.grey[300]!,
              ),
            ),
            child: CheckboxListTile(
              title: Text('Repuesto ya instalado', style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text('Marcar si ya está instalado', style: TextStyle(fontSize: 12)),
              value: _instalado,
              activeColor: _accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: 'Fecha instalación',
                    value: _fechaInstalacion,
                    onTap: _seleccionarFechaInstalacion,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildDateField(
                    label: 'Próximo cambio',
                    value: _proximoCambio,
                    onTap: _seleccionarFechaProximoCambio,
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: 16),
          TextFormField(
            controller: _observacionesController,
            decoration: InputDecoration(
              labelText: 'Observaciones',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.notes, color: _primaryColor),
              hintText: 'Notas adicionales...',
            ),
            maxLines: 4,
          ),
          SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: _primaryColor),
                SizedBox(width: 8),
                Text(
                  value != null ? ChileanUtils.formatDate(value) : 'Seleccionar',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: value != null ? Colors.black87 : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernBottomActions() {
    final currentTab = _tabController.index;
    final bool canAsignar = currentTab == 2 && _repuestoSeleccionado != null;
    
    return Container(
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: _primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Cerrar'),
              ),
            ),
            if (canAsignar) ...[
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _asignarRepuesto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle, size: 20),
                            SizedBox(width: 8),
                            Text('Asignar'),
                          ],
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper methods
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
        return Colors.amber[700]!;
      case SistemaVehiculo.suspension:
        return Colors.green;
      case SistemaVehiculo.neumaticos:
        return Colors.grey[700]!;
      case SistemaVehiculo.carroceria:
        return Colors.blue;
      case SistemaVehiculo.climatizacion:
        return Colors.cyan;
      case SistemaVehiculo.combustible:
        return Colors.brown;
      case SistemaVehiculo.refrigeracion:
        return Colors.teal;
    }
  }

  IconData _getSistemaIcon(SistemaVehiculo sistema) {
    switch (sistema) {
      case SistemaVehiculo.motor:
        return Icons.settings;
      case SistemaVehiculo.frenos:
        return Icons.disc_full;
      case SistemaVehiculo.transmision:
        return Icons.sync;
      case SistemaVehiculo.electrico:
        return Icons.bolt;
      case SistemaVehiculo.suspension:
        return Icons.height;
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

  String _getTipoLabel(TipoRepuesto tipo) {
    switch (tipo) {
      case TipoRepuesto.original:
        return 'Original';
      case TipoRepuesto.alternativo:
        return 'Alternativo';
      case TipoRepuesto.generico:
        return 'Genérico';
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
        ubicacionBus: _ubicacionController.text.trim().isEmpty
            ? null
            : _ubicacionController.text.trim(),
        fechaInstalacion: _fechaInstalacion,
        proximoCambio: _proximoCambio,
        observaciones: _observacionesController.text.trim().isEmpty
            ? null
            : _observacionesController.text.trim(),
        instalado: _instalado,
        tecnicoResponsable: _tecnicoController.text.trim().isEmpty
            ? null
            : _tecnicoController.text.trim(),
      );

      await DataService.addRepuestoAsignado(repuestoAsignado);

      // Limpiar y recargar
      setState(() {
        _repuestoSeleccionado = null;
        _cantidadController.text = '1';
        _ubicacionController.clear();
        _observacionesController.clear();
        _tecnicoController.clear();
        _instalado = false;
        _fechaInstalacion = null;
        _proximoCambio = null;
      });

      _cargarRepuestosAsignados();
      _tabController.animateTo(0); // Volver a asignados

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${repuestoAsignado.repuestoCatalogoId} asignado correctamente',
          ),
          backgroundColor: _accentColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      widget.onRepuestoAsignado?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al asignar repuesto: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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

// Widget para editar repuesto asignado
class _EditarRepuestoSheet extends StatefulWidget {
  final RepuestoAsignado asignado;
  final RepuestoCatalogo catalogo;
  final Color primaryColor;
  final VoidCallback onSaved;

  const _EditarRepuestoSheet({
    required this.asignado,
    required this.catalogo,
    required this.primaryColor,
    required this.onSaved,
  });

  @override
  State<_EditarRepuestoSheet> createState() => _EditarRepuestoSheetState();
}

class _EditarRepuestoSheetState extends State<_EditarRepuestoSheet> {
  late TextEditingController _cantidadController;
  late TextEditingController _ubicacionController;
  late TextEditingController _observacionesController;
  late TextEditingController _tecnicoController;
  bool _instalado = false;
  DateTime? _fechaInstalacion;
  DateTime? _proximoCambio;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cantidadController = TextEditingController(text: '${widget.asignado.cantidad}');
    _ubicacionController = TextEditingController(text: widget.asignado.ubicacionBus ?? '');
    _observacionesController = TextEditingController(text: widget.asignado.observaciones ?? '');
    _tecnicoController = TextEditingController(text: widget.asignado.tecnicoResponsable ?? '');
    _instalado = widget.asignado.instalado;
    _fechaInstalacion = widget.asignado.fechaInstalacion;
    _proximoCambio = widget.asignado.proximoCambio;
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _ubicacionController.dispose();
    _observacionesController.dispose();
    _tecnicoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.primaryColor.withOpacity(0.1),
            ),
            child: Row(
              children: [
                Icon(Icons.edit, color: widget.primaryColor),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Editar Repuesto',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.catalogo.nombre,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _cantidadController,
                    decoration: InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _ubicacionController,
                    decoration: InputDecoration(
                      labelText: 'Ubicación',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _tecnicoController,
                    decoration: InputDecoration(
                      labelText: 'Técnico responsable',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: _instalado ? Colors.green.withOpacity(0.1) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _instalado ? Colors.green : Colors.grey[300]!),
                    ),
                    child: CheckboxListTile(
                      title: Text('Repuesto instalado'),
                      value: _instalado,
                      activeColor: Colors.green,
                      onChanged: (value) {
                        setState(() {
                          _instalado = value!;
                          if (_instalado && _fechaInstalacion == null) {
                            _fechaInstalacion = DateTime.now();
                          }
                        });
                      },
                    ),
                  ),
                  if (_instalado) ...[
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            'Fecha instalación',
                            _fechaInstalacion,
                            () async {
                              final fecha = await showDatePicker(
                                context: context,
                                initialDate: _fechaInstalacion ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (fecha != null) setState(() => _fechaInstalacion = fecha);
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildDateField(
                            'Próximo cambio',
                            _proximoCambio,
                            () async {
                              final fecha = await showDatePicker(
                                context: context,
                                initialDate: _proximoCambio ?? DateTime.now().add(Duration(days: 90)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(Duration(days: 365 * 3)),
                              );
                              if (fecha != null) setState(() => _proximoCambio = fecha);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _observacionesController,
                    decoration: InputDecoration(
                      labelText: 'Observaciones',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
                      child: Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _guardarCambios,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Guardar Cambios'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: widget.primaryColor),
                SizedBox(width: 8),
                Text(
                  value != null ? ChileanUtils.formatDate(value) : 'Seleccionar',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _guardarCambios() async {
    setState(() => _isLoading = true);
    try {
      final updated = widget.asignado.copyWith(
        cantidad: int.parse(_cantidadController.text),
        ubicacionBus: _ubicacionController.text.trim().isEmpty ? null : _ubicacionController.text.trim(),
        observaciones: _observacionesController.text.trim().isEmpty ? null : _observacionesController.text.trim(),
        tecnicoResponsable: _tecnicoController.text.trim().isEmpty ? null : _tecnicoController.text.trim(),
        instalado: _instalado,
        fechaInstalacion: _fechaInstalacion,
        proximoCambio: _proximoCambio,
      );
      await DataService.updateRepuestoAsignado(updated);
      widget.onSaved();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cambios guardados'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// Diálogo para instalar repuesto
class _InstalarRepuestoDialog extends StatefulWidget {
  final RepuestoAsignado asignado;
  final RepuestoCatalogo catalogo;
  final Color primaryColor;

  const _InstalarRepuestoDialog({
    required this.asignado,
    required this.catalogo,
    required this.primaryColor,
  });

  @override
  State<_InstalarRepuestoDialog> createState() => _InstalarRepuestoDialogState();
}

class _InstalarRepuestoDialogState extends State<_InstalarRepuestoDialog> {
  DateTime _fechaInstalacion = DateTime.now();
  DateTime? _proximoCambio;
  final _tecnicoController = TextEditingController();

  @override
  void dispose() {
    _tecnicoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.check_circle, color: Colors.green),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text('Marcar como Instalado', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.build_circle, color: widget.primaryColor, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.catalogo.nombre,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text('Fecha de instalación', style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: _fechaInstalacion,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (fecha != null) setState(() => _fechaInstalacion = fecha);
              },
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: widget.primaryColor),
                    SizedBox(width: 8),
                    Text(ChileanUtils.formatDate(_fechaInstalacion)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text('Próximo cambio (opcional)', style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: _proximoCambio ?? DateTime.now().add(Duration(days: 90)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365 * 3)),
                );
                if (fecha != null) setState(() => _proximoCambio = fecha);
              },
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, size: 18, color: widget.primaryColor),
                    SizedBox(width: 8),
                    Text(_proximoCambio != null ? ChileanUtils.formatDate(_proximoCambio!) : 'Seleccionar fecha'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _tecnicoController,
              decoration: InputDecoration(
                labelText: 'Técnico responsable',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'fechaInstalacion': _fechaInstalacion,
              'proximoCambio': _proximoCambio,
              'tecnico': _tecnicoController.text.trim().isEmpty ? null : _tecnicoController.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: Text('Confirmar'),
        ),
      ],
    );
  }
}
