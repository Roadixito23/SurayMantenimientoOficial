import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/bus.dart';
import '../../../../models/repuesto.dart';
import '../../../../models/repuesto_asignado.dart';
import '../../../../services/data_service.dart';
import '../../../../services/chilean_utils.dart';

/// Layout mobile modernizado para gestión de repuestos
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
  State<AsignarRepuestoMobileLayout> createState() => _AsignarRepuestoMobileLayoutState();
}

class _AsignarRepuestoMobileLayoutState extends State<AsignarRepuestoMobileLayout> with SingleTickerProviderStateMixin {
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
          // Header con gradiente (nueva paleta)
          Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryDark, _primaryColor],
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
                      child: Icon(Icons.build_circle, color: Colors.white, size: 24),
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
                            widget.bus.patente,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2, color: _primaryColor, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '${_repuestosAsignados.length}',
                            style: TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
                // Tabs (3 tabs ahora)
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
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.list_alt, size: 16),
                            SizedBox(width: 4),
                            Text('Asignados', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 16),
                            SizedBox(width: 4),
                            Text('Buscar', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 4),
                            Text('Detalles', style: TextStyle(fontSize: 12)),
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
                _buildAsignadosTab(),
                _buildBuscarTab(),
                _buildDetallesTab(),
              ],
            ),
          ),

          // Botón de acción (solo visible en tab de detalles)
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              if (_tabController.index == 2) {
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
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading || _repuestoSeleccionado == null
                            ? null
                            : _asignarRepuesto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(
                                'Asignar Repuesto',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAsignadosTab() {
    return Column(
      children: [
        // Lista de repuestos asignados
        Expanded(
          child: _loadingAsignados
              ? Center(
                  child: CircularProgressIndicator(color: _primaryColor))
              : _repuestosAsignados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.build_circle_outlined,
                              size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text('Sin repuestos asignados',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 16)),
                          SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _tabController.animateTo(1),
                            icon: Icon(Icons.add, color: _primaryColor),
                            label: Text('Asignar primero',
                                style: TextStyle(color: _primaryColor)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _repuestosAsignados.length,
                      itemBuilder: (context, index) {
                        final item = _repuestosAsignados[index];
                        final asignado =
                            item['repuestoAsignado'] as RepuestoAsignado;
                        final catalogo =
                            item['repuestoCatalogo'] as RepuestoCatalogo;
                        final isSelected =
                            _asignadoSeleccionado?.id == asignado.id;

                        return _buildAsignadoListTile(
                            asignado, catalogo, isSelected);
                      },
                    ),
        ),
        // Panel de detalles del repuesto seleccionado
        if (_asignadoSeleccionado != null &&
            _catalogoAsignadoSeleccionado != null)
          Container(
            constraints: BoxConstraints(maxHeight: 300),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: _buildDetalleAsignadoCompacto(),
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

    return Card(
      margin: EdgeInsets.only(bottom: 12),
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('${catalogo.codigo} • ${asignado.cantidad} uds',
                style: TextStyle(fontSize: 12)),
            SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                if (asignado.ubicacionBus != null) ...[
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      asignado.ubicacionBus!,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: _primaryColor, size: 28)
            : Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () {
          setState(() {
            if (_asignadoSeleccionado?.id == asignado.id) {
              // Si ya está seleccionado, deseleccionar
              _asignadoSeleccionado = null;
              _catalogoAsignadoSeleccionado = null;
            } else {
              _asignadoSeleccionado = asignado;
              _catalogoAsignadoSeleccionado = catalogo;
            }
          });
        },
      ),
    );
  }

  Widget _buildDetalleAsignadoCompacto() {
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
          // Header
          Row(
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
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${catalogo.codigo} • ${catalogo.sistemaLabel}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _asignadoSeleccionado = null;
                    _catalogoAsignadoSeleccionado = null;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 16),
          // Info compacta
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip('${asignado.cantidad} uds', Icons.numbers),
              _buildInfoChip(
                asignado.instalado
                    ? (vencido ? 'Vencido' : 'Instalado')
                    : 'Pendiente',
                asignado.instalado ? Icons.check_circle : Icons.pending_actions,
                color: asignado.instalado
                    ? (vencido ? Colors.red : _accentColor)
                    : _primaryColor,
              ),
              if (asignado.ubicacionBus != null)
                _buildInfoChip(asignado.ubicacionBus!, Icons.location_on),
            ],
          ),
          if (asignado.observaciones != null &&
              asignado.observaciones!.isNotEmpty) ...[
            SizedBox(height: 12),
            Text('Observaciones:',
                style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(asignado.observaciones!,
                style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ],
          SizedBox(height: 12),
          // Botones de acción
          Row(
            children: [
              if (!asignado.instalado)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _marcarComoInstalado(asignado, catalogo),
                    icon: Icon(Icons.check_circle, size: 18),
                    label: Text('Instalar', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              if (!asignado.instalado) SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editarAsignado(asignado, catalogo),
                  icon: Icon(Icons.edit, size: 18),
                  label: Text('Editar', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: _primaryColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Botón de eliminar
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _eliminarAsignado(asignado, catalogo),
              icon: Icon(Icons.delete, size: 18),
              label: Text('Eliminar', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, {Color? color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? _primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (color ?? _primaryColor).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? _primaryColor),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                color: color ?? _primaryColor,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _marcarComoInstalado(
      RepuestoAsignado asignado, RepuestoCatalogo catalogo) async {
    final formKey = GlobalKey<FormState>();
    DateTime? fechaInstalacion = DateTime.now();
    DateTime? proximoCambio;
    String? tecnico = asignado.tecnicoResponsable;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Marcar como Instalado'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.calendar_today, color: _primaryColor),
                  title: Text('Fecha de instalación'),
                  subtitle: Text(ChileanUtils.formatDate(fechaInstalacion!)),
                  onTap: () async {
                    final fecha = await showDatePicker(
                      context: context,
                      initialDate: fechaInstalacion!,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (fecha != null) {
                      fechaInstalacion = fecha;
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.event, color: _primaryColor),
                  title: Text('Próximo cambio (opcional)'),
                  subtitle: Text(proximoCambio != null
                      ? ChileanUtils.formatDate(proximoCambio!)
                      : 'No programado'),
                  onTap: () async {
                    final fecha = await showDatePicker(
                      context: context,
                      initialDate: proximoCambio ??
                          DateTime.now().add(Duration(days: 90)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365 * 3)),
                    );
                    if (fecha != null) {
                      proximoCambio = fecha;
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  initialValue: tecnico,
                  decoration: InputDecoration(
                    labelText: 'Técnico responsable',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (value) => tecnico = value.trim(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
            child: Text('Confirmar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final updated = asignado.copyWith(
          instalado: true,
          fechaInstalacion: fechaInstalacion,
          proximoCambio: proximoCambio,
          tecnicoResponsable: tecnico?.isEmpty == true ? null : tecnico,
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
    final formKey = GlobalKey<FormState>();
    final cantidadController =
        TextEditingController(text: asignado.cantidad.toString());
    final ubicacionController =
        TextEditingController(text: asignado.ubicacionBus ?? '');
    final observacionesController =
        TextEditingController(text: asignado.observaciones ?? '');
    final tecnicoController =
        TextEditingController(text: asignado.tecnicoResponsable ?? '');
    DateTime? fechaInstalacion = asignado.fechaInstalacion;
    DateTime? proximoCambio = asignado.proximoCambio;
    bool instalado = asignado.instalado;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Editar Repuesto'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: cantidadController,
                    decoration: InputDecoration(
                      labelText: 'Cantidad',
                      prefixIcon: Icon(Icons.numbers),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requerido';
                      }
                      final cantidad = int.tryParse(value);
                      if (cantidad == null || cantidad <= 0) {
                        return 'Cantidad inválida';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: ubicacionController,
                    decoration: InputDecoration(
                      labelText: 'Ubicación',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: tecnicoController,
                    decoration: InputDecoration(
                      labelText: 'Técnico',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  SizedBox(height: 12),
                  CheckboxListTile(
                    title: Text('Instalado'),
                    value: instalado,
                    onChanged: (value) {
                      setDialogState(() {
                        instalado = value!;
                        if (!instalado) {
                          fechaInstalacion = null;
                          proximoCambio = null;
                        }
                      });
                    },
                  ),
                  if (instalado) ...[
                    ListTile(
                      leading: Icon(Icons.calendar_today),
                      title: Text('Fecha instalación'),
                      subtitle: Text(fechaInstalacion != null
                          ? ChileanUtils.formatDate(fechaInstalacion!)
                          : 'Seleccionar'),
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: fechaInstalacion ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (fecha != null) {
                          setDialogState(() => fechaInstalacion = fecha);
                        }
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.event),
                      title: Text('Próximo cambio'),
                      subtitle: Text(proximoCambio != null
                          ? ChileanUtils.formatDate(proximoCambio!)
                          : 'No programado'),
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: proximoCambio ??
                              DateTime.now().add(Duration(days: 90)),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(Duration(days: 365 * 3)),
                        );
                        if (fecha != null) {
                          setDialogState(() => proximoCambio = fecha);
                        }
                      },
                    ),
                  ],
                  SizedBox(height: 12),
                  TextFormField(
                    controller: observacionesController,
                    decoration: InputDecoration(
                      labelText: 'Observaciones',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
              child: Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final updated = asignado.copyWith(
          cantidad: int.parse(cantidadController.text),
          ubicacionBus: ubicacionController.text.trim().isEmpty
              ? null
              : ubicacionController.text.trim(),
          observaciones: observacionesController.text.trim().isEmpty
              ? null
              : observacionesController.text.trim(),
          tecnicoResponsable: tecnicoController.text.trim().isEmpty
              ? null
              : tecnicoController.text.trim(),
          instalado: instalado,
          fechaInstalacion: fechaInstalacion,
          proximoCambio: proximoCambio,
        );
        await DataService.updateRepuestoAsignado(updated);
        _cargarRepuestosAsignados();
        setState(() {
          _asignadoSeleccionado = updated;
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

    cantidadController.dispose();
    ubicacionController.dispose();
    observacionesController.dispose();
    tecnicoController.dispose();
  }

  void _eliminarAsignado(
      RepuestoAsignado asignado, RepuestoCatalogo catalogo) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Eliminar Asignación'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que quieres eliminar esta asignación?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getSistemaIcon(catalogo.sistema),
                          size: 20, color: _getSistemaColor(catalogo.sistema)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          catalogo.nombre,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text('Bus: ${widget.bus.patente}',
                      style: TextStyle(fontSize: 12)),
                  Text('Cantidad: ${asignado.cantidad} uds',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[700],
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      try {
        await DataService.deleteRepuestoAsignado(asignado.id);
        _cargarRepuestosAsignados();
        setState(() {
          _asignadoSeleccionado = null;
          _catalogoAsignadoSeleccionado = null;
        });
        widget.onRepuestoAsignado?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Asignación eliminada correctamente'),
            backgroundColor: _accentColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
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
                  prefixIcon: Icon(Icons.search, color: _primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: Icon(Icons.filter_list, color: _primaryColor),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryColor, width: 2),
                  ),
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
                    color: isSelected ? _primaryColor : Colors.transparent,
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
                          style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: _primaryColor, size: 32)
                      : Icon(Icons.radio_button_unchecked, color: Colors.grey),
                  onTap: () {
                    setState(() {
                      _repuestoSeleccionado = repuesto;
                      _ubicacionController.text = _getUbicacionSugerida(repuesto.sistema);
                    });
                    // Cambiar a la tab de detalles
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
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: Icon(Icons.search),
              label: Text('Ir a Buscar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
                  colors: [
                    _primaryColor.withOpacity(0.1),
                    _primaryColor.withOpacity(0.05)
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryColor.withOpacity(0.3)),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor),
            ),
            SizedBox(height: 16),

            // Formulario
            TextFormField(
              controller: _cantidadController,
              decoration: InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.numbers, color: _primaryColor),
                filled: true,
                fillColor: Colors.grey[50],
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
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
                prefixIcon: Icon(Icons.location_on, color: _primaryColor),
                hintText: 'Ej: Motor, Eje delantero, etc.',
                filled: true,
                fillColor: Colors.grey[50],
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
              ),
            ),
            SizedBox(height: 16),

            TextFormField(
              controller: _tecnicoController,
              decoration: InputDecoration(
                labelText: 'Técnico responsable',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.person, color: _primaryColor),
                filled: true,
                fillColor: Colors.grey[50],
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
              ),
            ),
            SizedBox(height: 16),

            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: CheckboxListTile(
                title: Text('Repuesto ya instalado'),
                subtitle: Text('Marcar si el repuesto ya está instalado'),
                value: _instalado,
                activeColor: _primaryColor,
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
                    prefixIcon: Icon(Icons.calendar_today, color: _primaryColor),
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
                    prefixIcon: Icon(Icons.schedule, color: _primaryColor),
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
                prefixIcon: Icon(Icons.note, color: _primaryColor),
                hintText: 'Notas adicionales...',
                filled: true,
                fillColor: Colors.grey[50],
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
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
            backgroundColor: _accentColor,
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
