import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/bus.dart';
import '../../../../models/repuesto.dart';
import '../../../../models/repuesto_asignado.dart';
import '../../../../services/data_service.dart';
import '../../../../services/chilean_utils.dart';

/// Layout desktop modernizado para gestión de repuestos
/// Paleta de colores basada en el ícono build_circle (azul marino)
class AsignarRepuestoDesktopLayout extends StatefulWidget {
  final Bus bus;
  final Function()? onRepuestoAsignado;

  const AsignarRepuestoDesktopLayout({
    Key? key,
    required this.bus,
    this.onRepuestoAsignado,
  }) : super(key: key);

  @override
  State<AsignarRepuestoDesktopLayout> createState() =>
      _AsignarRepuestoDesktopLayoutState();
}

class _AsignarRepuestoDesktopLayoutState
    extends State<AsignarRepuestoDesktopLayout>
    with SingleTickerProviderStateMixin {
  // Paleta de colores basada en el ícono (azul marino)
  static const Color _primaryColor = Color(0xFF2C5F8D);
  static const Color _primaryDark = Color(0xFF1A3B5C);
  static const Color _accentColor = Color(0xFF4CAF50);

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
  RepuestoAsignado? _asignadoSeleccionado;
  RepuestoCatalogo? _catalogoAsignadoSeleccionado;

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
      final repuestos =
          await DataService.getRepuestosAsignadosConInfo(widget.bus.id);
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 950,
        height: 700,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAsignadosTab(),
                  _buildNuevoTab(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryDark, _primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.build_circle, color: Colors.white, size: 32),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestión de Repuestos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
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
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2, color: _primaryColor, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '${_repuestosAsignados.length} repuestos',
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 20),
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
              labelStyle: TextStyle(fontWeight: FontWeight.w600),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.list_alt, size: 20),
                      SizedBox(width: 8),
                      Text('Repuestos Asignados'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle, size: 20),
                      SizedBox(width: 8),
                      Text('Asignar Nuevo'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAsignadosTab() {
    return Row(
      children: [
        // Lista de repuestos asignados
        Expanded(
          flex: 2,
          child: Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.list_alt, color: _primaryColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Repuestos Asignados',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: _primaryColor),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loadingAsignados
                      ? Center(
                          child:
                              CircularProgressIndicator(color: _primaryColor))
                      : _repuestosAsignados.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.build_circle_outlined,
                                      size: 48, color: Colors.grey[400]),
                                  SizedBox(height: 12),
                                  Text('Sin repuestos asignados',
                                      style:
                                          TextStyle(color: Colors.grey[600])),
                                  SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () =>
                                        _tabController.animateTo(1),
                                    icon: Icon(Icons.add),
                                    label: Text('Asignar primero'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _repuestosAsignados.length,
                              itemBuilder: (context, index) {
                                final item = _repuestosAsignados[index];
                                final asignado = item['repuestoAsignado']
                                    as RepuestoAsignado;
                                final catalogo = item['repuestoCatalogo']
                                    as RepuestoCatalogo;
                                final isSelected =
                                    _asignadoSeleccionado?.id == asignado.id;

                                return _buildAsignadoListTile(
                                    asignado, catalogo, isSelected);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
        // Panel de detalles
        Expanded(
          flex: 3,
          child: Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: _asignadoSeleccionado == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app,
                            size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'Selecciona un repuesto',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        Text(
                          'Haz clic en un repuesto para ver sus detalles',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : _buildDetalleAsignado(),
          ),
        ),
      ],
    );
  }

  Widget _buildAsignadoListTile(
      RepuestoAsignado asignado, RepuestoCatalogo catalogo, bool isSelected) {
    final bool vencido = asignado.proximoCambio != null &&
        asignado.proximoCambio!.isBefore(DateTime.now());
    final bool proximoVencer = asignado.proximoCambio != null &&
        !vencido &&
        asignado.proximoCambio!.difference(DateTime.now()).inDays <= 30;

    Color statusColor = asignado.instalado
        ? (vencido
            ? Colors.red
            : (proximoVencer ? Colors.orange : _accentColor))
        : _primaryColor;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? _primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(8),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getSistemaColor(catalogo.sistema).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getSistemaIcon(catalogo.sistema),
            color: _getSistemaColor(catalogo.sistema),
            size: 20,
          ),
        ),
        title: Text(
          catalogo.nombre,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Row(
          children: [
            Text('${catalogo.codigo} • ${asignado.cantidad} uds',
                style: TextStyle(fontSize: 12)),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                asignado.instalado
                    ? (vencido ? 'Vencido' : 'Instalado')
                    : 'Pendiente',
                style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: _primaryColor)
            : Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () {
          setState(() {
            _asignadoSeleccionado = asignado;
            _catalogoAsignadoSeleccionado = catalogo;
          });
        },
      ),
    );
  }

  Widget _buildDetalleAsignado() {
    if (_asignadoSeleccionado == null ||
        _catalogoAsignadoSeleccionado == null) {
      return SizedBox.shrink();
    }

    final asignado = _asignadoSeleccionado!;
    final catalogo = _catalogoAsignadoSeleccionado!;

    final bool vencido = asignado.proximoCambio != null &&
        asignado.proximoCambio!.isBefore(DateTime.now());

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del repuesto
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(14),
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
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      catalogo.nombre,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${catalogo.codigo} • ${catalogo.sistemaLabel}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Información en grid
          Row(
            children: [
              Expanded(
                  child: _buildInfoCard(
                      'Cantidad', '${asignado.cantidad}', Icons.numbers)),
              SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Estado',
                  asignado.instalado
                      ? (vencido ? 'Vencido' : 'Instalado')
                      : 'Pendiente',
                  asignado.instalado
                      ? Icons.check_circle
                      : Icons.pending_actions,
                  color: asignado.instalado
                      ? (vencido ? Colors.red : _accentColor)
                      : _primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Asignación',
                  ChileanUtils.formatDate(asignado.fechaAsignacion),
                  Icons.calendar_today,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Ubicación',
                  asignado.ubicacionBus ?? 'No especificada',
                  Icons.location_on,
                ),
              ),
            ],
          ),
          if (asignado.instalado) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Instalación',
                    asignado.fechaInstalacion != null
                        ? ChileanUtils.formatDate(asignado.fechaInstalacion!)
                        : 'No especificada',
                    Icons.build,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    'Próx. Cambio',
                    asignado.proximoCambio != null
                        ? ChileanUtils.formatDate(asignado.proximoCambio!)
                        : 'No programado',
                    Icons.event,
                    color: vencido ? Colors.red : null,
                  ),
                ),
              ],
            ),
          ],
          if (asignado.tecnicoResponsable != null) ...[
            SizedBox(height: 12),
            _buildInfoCard(
                'Técnico', asignado.tecnicoResponsable!, Icons.person),
          ],
          if (asignado.observaciones != null &&
              asignado.observaciones!.isNotEmpty) ...[
            SizedBox(height: 16),
            Text('Observaciones',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: _primaryColor)),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(asignado.observaciones!,
                  style: TextStyle(color: Colors.grey[700])),
            ),
          ],
          SizedBox(height: 24),

          // Acciones
          Row(
            children: [
              if (!asignado.instalado)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _marcarComoInstalado(asignado, catalogo),
                    icon: Icon(Icons.check_circle, size: 20),
                    label: Text('Marcar Instalado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              if (!asignado.instalado) SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editarAsignado(asignado, catalogo),
                  icon: Icon(Icons.edit, size: 20),
                  label: Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: _primaryColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon,
      {Color? color}) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? _primaryColor),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.w600, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _marcarComoInstalado(
      RepuestoAsignado asignado, RepuestoCatalogo catalogo) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _InstalarDesktopDialog(
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
        setState(() {
          _asignadoSeleccionado = updated;
        });
        widget.onRepuestoAsignado?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${catalogo.nombre} marcado como instalado'),
            backgroundColor: _accentColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _editarAsignado(
      RepuestoAsignado asignado, RepuestoCatalogo catalogo) async {
    final result = await showDialog<RepuestoAsignado>(
      context: context,
      builder: (context) => _EditarDesktopDialog(
        asignado: asignado,
        catalogo: catalogo,
        primaryColor: _primaryColor,
      ),
    );

    if (result != null) {
      try {
        await DataService.updateRepuestoAsignado(result);
        _cargarRepuestosAsignados();
        setState(() {
          _asignadoSeleccionado = result;
        });
        widget.onRepuestoAsignado?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Repuesto actualizado'),
            backgroundColor: _accentColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildNuevoTab() {
    return Form(
      key: _formKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel izquierdo - Selección de repuesto
          Expanded(
            flex: 3,
            child: Container(
              margin: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtros modernizados
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _busquedaController,
                          decoration: InputDecoration(
                            labelText: 'Buscar repuesto',
                            prefixIcon:
                                Icon(Icons.search, color: _primaryColor),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: _primaryColor, width: 2),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _filtroBusqueda = value;
                              _aplicarFiltros();
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Container(
                        width: 160,
                        child: DropdownButtonFormField<String>(
                          value: _filtroSistema,
                          decoration: InputDecoration(
                            labelText: 'Sistema',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _getSistemasDisponibles()
                              .map((sistema) => DropdownMenuItem(
                                    value: sistema,
                                    child: Text(sistema,
                                        style: TextStyle(fontSize: 12)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _filtroSistema = value!;
                              _aplicarFiltros();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Lista de repuestos
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _repuestosFiltrados.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off,
                                      size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('No se encontraron repuestos'),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _repuestosFiltrados.length,
                              itemBuilder: (context, index) {
                                final repuesto = _repuestosFiltrados[index];
                                final isSelected =
                                    _repuestoSeleccionado?.id == repuesto.id;

                                return Container(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _primaryColor.withOpacity(0.1)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? _primaryColor
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.all(8),
                                    leading: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            _getSistemaColor(repuesto.sistema)
                                                .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _getSistemaIcon(repuesto.sistema),
                                        size: 18,
                                        color:
                                            _getSistemaColor(repuesto.sistema),
                                      ),
                                    ),
                                    title: Text(
                                      repuesto.nombre,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            '${repuesto.codigo} - ${repuesto.sistemaLabel}',
                                            style: TextStyle(fontSize: 12)),
                                        if (repuesto.precioReferencial != null)
                                          Text(
                                            ChileanUtils.formatCurrency(
                                                repuesto.precioReferencial!),
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: _accentColor,
                                                fontWeight: FontWeight.w500),
                                          ),
                                      ],
                                    ),
                                    trailing: isSelected
                                        ? Icon(Icons.check_circle,
                                            color: _primaryColor)
                                        : Icon(Icons.circle_outlined,
                                            color: Colors.grey[400]),
                                    onTap: () {
                                      setState(() {
                                        _repuestoSeleccionado = repuesto;
                                        _ubicacionController.text =
                                            _getUbicacionSugerida(
                                                repuesto.sistema);
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Panel derecho - Formulario
          Expanded(
            flex: 2,
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalles de Asignación',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_repuestoSeleccionado != null) ...[
                      // Info del repuesto seleccionado
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _primaryColor.withOpacity(0.1),
                              _primaryColor.withOpacity(0.05)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: _primaryColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getSistemaColor(
                                    _repuestoSeleccionado!.sistema),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getSistemaIcon(_repuestoSeleccionado!.sistema),
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_repuestoSeleccionado!.nombre,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text('${_repuestoSeleccionado!.codigo}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, size: 18),
                              onPressed: () =>
                                  setState(() => _repuestoSeleccionado = null),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      // Formulario
                      TextFormField(
                        controller: _cantidadController,
                        decoration: InputDecoration(
                          labelText: 'Cantidad',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          prefixIcon: Icon(Icons.numbers, color: _primaryColor),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Requerido';
                          final cantidad = int.tryParse(value);
                          if (cantidad == null || cantidad <= 0)
                            return 'Inválido';
                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      TextFormField(
                        controller: _ubicacionController,
                        decoration: InputDecoration(
                          labelText: 'Ubicación en el vehículo',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          prefixIcon:
                              Icon(Icons.location_on, color: _primaryColor),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12),

                      TextFormField(
                        controller: _tecnicoController,
                        decoration: InputDecoration(
                          labelText: 'Técnico responsable',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          prefixIcon: Icon(Icons.person, color: _primaryColor),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: _instalado
                              ? _accentColor.withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _instalado
                                  ? _accentColor
                                  : Colors.grey[300]!),
                        ),
                        child: CheckboxListTile(
                          title: Text('Ya instalado',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          value: _instalado,
                          activeColor: _accentColor,
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
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: _buildDateSelector(
                                    'Instalación',
                                    _fechaInstalacion,
                                    _seleccionarFechaInstalacion)),
                            SizedBox(width: 12),
                            Expanded(
                                child: _buildDateSelector(
                                    'Próx. cambio',
                                    _proximoCambio,
                                    _seleccionarFechaProximoCambio)),
                          ],
                        ),
                      ],

                      SizedBox(height: 12),
                      TextFormField(
                        controller: _observacionesController,
                        decoration: InputDecoration(
                          labelText: 'Observaciones',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          prefixIcon: Icon(Icons.notes, color: _primaryColor),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 3,
                      ),
                    ] else ...[
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 50),
                          child: Column(
                            children: [
                              Icon(Icons.touch_app,
                                  size: 64, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                'Selecciona un repuesto',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[600]),
                              ),
                              Text(
                                'de la lista para continuar',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: _primaryColor),
                SizedBox(width: 6),
                Text(
                  value != null
                      ? ChileanUtils.formatDate(value)
                      : 'Seleccionar',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final currentTab = _tabController.index;
    final bool canAsignar = currentTab == 1 && _repuestoSeleccionado != null;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
          if (canAsignar) ...[
            SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _asignarRepuesto,
              icon: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(Icons.add_circle, size: 20),
              label: Text('Asignar Repuesto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
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

  void _seleccionarFechaInstalacion() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaInstalacion ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fecha != null) setState(() => _fechaInstalacion = fecha);
  }

  void _seleccionarFechaProximoCambio() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _proximoCambio ?? DateTime.now().add(Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 3)),
    );
    if (fecha != null) setState(() => _proximoCambio = fecha);
  }

  void _asignarRepuesto() async {
    if (!_formKey.currentState!.validate()) return;
    if (_repuestoSeleccionado == null) return;

    setState(() => _isLoading = true);

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
      _tabController.animateTo(0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Repuesto asignado correctamente'),
          backgroundColor: _accentColor,
        ),
      );

      widget.onRepuestoAsignado?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// Diálogo para marcar como instalado
class _InstalarDesktopDialog extends StatefulWidget {
  final RepuestoAsignado asignado;
  final RepuestoCatalogo catalogo;
  final Color primaryColor;

  const _InstalarDesktopDialog({
    required this.asignado,
    required this.catalogo,
    required this.primaryColor,
  });

  @override
  State<_InstalarDesktopDialog> createState() => _InstalarDesktopDialogState();
}

class _InstalarDesktopDialogState extends State<_InstalarDesktopDialog> {
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
          Text('Marcar como Instalado', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: Container(
        width: 400,
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
                  Icon(Icons.build_circle, color: widget.primaryColor),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text(widget.catalogo.nombre,
                          style: TextStyle(fontWeight: FontWeight.w500))),
                ],
              ),
            ),
            SizedBox(height: 20),
            _buildDateField('Fecha de instalación', _fechaInstalacion,
                () async {
              final fecha = await showDatePicker(
                context: context,
                initialDate: _fechaInstalacion,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (fecha != null) setState(() => _fechaInstalacion = fecha);
            }),
            SizedBox(height: 16),
            _buildDateField('Próximo cambio (opcional)', _proximoCambio,
                () async {
              final fecha = await showDatePicker(
                context: context,
                initialDate:
                    _proximoCambio ?? DateTime.now().add(Duration(days: 90)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(Duration(days: 365 * 3)),
              );
              if (fecha != null) setState(() => _proximoCambio = fecha);
            }),
            SizedBox(height: 16),
            TextField(
              controller: _tecnicoController,
              decoration: InputDecoration(
                labelText: 'Técnico responsable',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'fechaInstalacion': _fechaInstalacion,
              'proximoCambio': _proximoCambio,
              'tecnico': _tecnicoController.text.trim().isEmpty
                  ? null
                  : _tecnicoController.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, foregroundColor: Colors.white),
          child: Text('Confirmar'),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: widget.primaryColor),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(
                  value != null
                      ? ChileanUtils.formatDate(value)
                      : 'Seleccionar',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Diálogo para editar repuesto
class _EditarDesktopDialog extends StatefulWidget {
  final RepuestoAsignado asignado;
  final RepuestoCatalogo catalogo;
  final Color primaryColor;

  const _EditarDesktopDialog({
    required this.asignado,
    required this.catalogo,
    required this.primaryColor,
  });

  @override
  State<_EditarDesktopDialog> createState() => _EditarDesktopDialogState();
}

class _EditarDesktopDialogState extends State<_EditarDesktopDialog> {
  late TextEditingController _cantidadController;
  late TextEditingController _ubicacionController;
  late TextEditingController _observacionesController;
  late TextEditingController _tecnicoController;
  bool _instalado = false;
  DateTime? _fechaInstalacion;
  DateTime? _proximoCambio;

  @override
  void initState() {
    super.initState();
    _cantidadController =
        TextEditingController(text: '${widget.asignado.cantidad}');
    _ubicacionController =
        TextEditingController(text: widget.asignado.ubicacionBus ?? '');
    _observacionesController =
        TextEditingController(text: widget.asignado.observaciones ?? '');
    _tecnicoController =
        TextEditingController(text: widget.asignado.tecnicoResponsable ?? '');
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.edit, color: widget.primaryColor),
          SizedBox(width: 12),
          Text('Editar Repuesto', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: Container(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.build_circle, color: widget.primaryColor),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text(widget.catalogo.nombre,
                            style: TextStyle(fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _cantidadController,
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12),
              TextField(
                controller: _ubicacionController,
                decoration: InputDecoration(
                  labelText: 'Ubicación',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _tecnicoController,
                decoration: InputDecoration(
                  labelText: 'Técnico responsable',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: _instalado
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _instalado ? Colors.green : Colors.grey[300]!),
                ),
                child: CheckboxListTile(
                  title: Text('Instalado'),
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
                      child: _buildDateField('Instalación', _fechaInstalacion,
                          () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: _fechaInstalacion ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (fecha != null)
                          setState(() => _fechaInstalacion = fecha);
                      }),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildDateField('Próx. cambio', _proximoCambio,
                          () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: _proximoCambio ??
                              DateTime.now().add(Duration(days: 90)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365 * 3)),
                        );
                        if (fecha != null)
                          setState(() => _proximoCambio = fecha);
                      }),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 12),
              TextField(
                controller: _observacionesController,
                decoration: InputDecoration(
                  labelText: 'Observaciones',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            final updated = widget.asignado.copyWith(
              cantidad: int.tryParse(_cantidadController.text) ??
                  widget.asignado.cantidad,
              ubicacionBus: _ubicacionController.text.trim().isEmpty
                  ? null
                  : _ubicacionController.text.trim(),
              observaciones: _observacionesController.text.trim().isEmpty
                  ? null
                  : _observacionesController.text.trim(),
              tecnicoResponsable: _tecnicoController.text.trim().isEmpty
                  ? null
                  : _tecnicoController.text.trim(),
              instalado: _instalado,
              fechaInstalacion: _fechaInstalacion,
              proximoCambio: _proximoCambio,
            );
            Navigator.pop(context, updated);
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
              foregroundColor: Colors.white),
          child: Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: widget.primaryColor),
                SizedBox(width: 6),
                Text(
                  value != null
                      ? ChileanUtils.formatDate(value)
                      : 'Seleccionar',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
