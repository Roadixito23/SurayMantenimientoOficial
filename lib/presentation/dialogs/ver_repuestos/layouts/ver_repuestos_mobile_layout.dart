import 'package:flutter/material.dart';
import '../../../../models/bus.dart';
import '../../../../models/repuesto.dart';
import '../../../../models/repuesto_asignado.dart';
import '../../../../services/data_service.dart';
import '../../../../services/chilean_utils.dart';

class VerRepuestosMobileLayout extends StatefulWidget {
  final Bus bus;
  final Function()? onRepuestoModificado;

  const VerRepuestosMobileLayout({
    Key? key,
    required this.bus,
    this.onRepuestoModificado,
  }) : super(key: key);

  @override
  State<VerRepuestosMobileLayout> createState() => _VerRepuestosMobileLayoutState();
}

class _VerRepuestosMobileLayoutState extends State<VerRepuestosMobileLayout> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _repuestosConInfo = [];
  String _filtroEstado = 'Todos'; // Todos, Instalados, Pendientes

  @override
  void initState() {
    super.initState();
    _cargarRepuestos();
  }

  Future<void> _cargarRepuestos() async {
    setState(() => _isLoading = true);
    try {
      final repuestos = await DataService.getRepuestosAsignadosConInfo(widget.bus.id);
      setState(() {
        _repuestosConInfo = repuestos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar repuestos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _repuestosFiltrados {
    if (_filtroEstado == 'Todos') return _repuestosConInfo;
    if (_filtroEstado == 'Instalados') {
      return _repuestosConInfo.where((r) => 
        (r['repuestoAsignado'] as RepuestoAsignado).instalado
      ).toList();
    }
    return _repuestosConInfo.where((r) => 
      !(r['repuestoAsignado'] as RepuestoAsignado).instalado
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header con gradiente llamativo
          _buildHeader(),
          // Filtros
          _buildFilters(),
          // Lista de repuestos
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF8E24AA),
                    ),
                  )
                : _repuestosFiltrados.isEmpty
                    ? _buildEmptyState()
                    : _buildRepuestosList(),
          ),
          // Footer con resumen
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8E24AA), Color(0xFFAB47BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8E24AA).withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.build_circle,
                color: Colors.white,
                size: 28,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Repuestos Asignados',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    widget.bus.identificadorDisplay,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
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
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_repuestosConInfo.length}',
                style: TextStyle(
                  color: Color(0xFF8E24AA),
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
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Todos', Icons.list_alt),
            SizedBox(width: 8),
            _buildFilterChip('Instalados', Icons.check_circle),
            SizedBox(width: 8),
            _buildFilterChip('Pendientes', Icons.pending_actions),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _filtroEstado == label;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Color(0xFF8E24AA),
          ),
          SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filtroEstado = label);
      },
      selectedColor: Color(0xFF8E24AA),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Color(0xFF8E24AA),
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? Color(0xFF8E24AA) : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFF8E24AA).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Color(0xFF8E24AA).withOpacity(0.5),
              ),
            ),
            SizedBox(height: 24),
            Text(
              _filtroEstado == 'Todos'
                  ? 'Sin repuestos asignados'
                  : 'No hay repuestos ${_filtroEstado.toLowerCase()}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              _filtroEstado == 'Todos'
                  ? 'Asigna repuestos a este vehículo para llevar control de su mantenimiento'
                  : 'Prueba con otro filtro',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepuestosList() {
    return RefreshIndicator(
      onRefresh: _cargarRepuestos,
      color: Color(0xFF8E24AA),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _repuestosFiltrados.length,
        itemBuilder: (context, index) {
          final item = _repuestosFiltrados[index];
          final repuestoAsignado = item['repuestoAsignado'] as RepuestoAsignado;
          final repuestoCatalogo = item['repuestoCatalogo'] as RepuestoCatalogo;
          
          return _buildRepuestoCard(repuestoAsignado, repuestoCatalogo);
        },
      ),
    );
  }

  Widget _buildRepuestoCard(RepuestoAsignado asignado, RepuestoCatalogo catalogo) {
    final bool proximoVencer = asignado.proximoCambio != null &&
        asignado.proximoCambio!.difference(DateTime.now()).inDays <= 30 &&
        asignado.proximoCambio!.difference(DateTime.now()).inDays >= 0;
    
    final bool vencido = asignado.proximoCambio != null &&
        asignado.proximoCambio!.isBefore(DateTime.now());

    Color statusColor = asignado.instalado 
        ? (vencido ? Colors.red : (proximoVencer ? Colors.orange : Colors.green))
        : Colors.blue;
    
    String statusText = asignado.instalado 
        ? (vencido ? 'Vencido' : (proximoVencer ? 'Próximo a vencer' : 'Instalado'))
        : 'Pendiente';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => _mostrarDetalleRepuesto(asignado, catalogo),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del repuesto
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
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          catalogo.codigo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
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
              SizedBox(height: 12),
              Divider(height: 1),
              SizedBox(height: 12),
              // Información adicional
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.numbers,
                      'Cantidad',
                      '${asignado.cantidad}',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.location_on,
                      'Ubicación',
                      asignado.ubicacionBus ?? 'No especificada',
                    ),
                  ),
                ],
              ),
              if (asignado.proximoCambio != null) ...[
                SizedBox(height: 8),
                _buildInfoItem(
                  Icons.event,
                  'Próximo cambio',
                  ChileanUtils.formatDate(asignado.proximoCambio!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _mostrarDetalleRepuesto(RepuestoAsignado asignado, RepuestoCatalogo catalogo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Código: ${catalogo.codigo}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(),
            // Detalles
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
                      if (catalogo.descripcion.isNotEmpty)
                        _buildDetailRow('Descripción', catalogo.descripcion),
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
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
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
            color: Color(0xFF8E24AA),
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
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final instalados = _repuestosConInfo.where((r) => 
      (r['repuestoAsignado'] as RepuestoAsignado).instalado
    ).length;
    final pendientes = _repuestosConInfo.length - instalados;

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
              child: _buildFooterStat(
                Icons.check_circle,
                'Instalados',
                '$instalados',
                Colors.green,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[300],
            ),
            Expanded(
              child: _buildFooterStat(
                Icons.pending_actions,
                'Pendientes',
                '$pendientes',
                Colors.orange,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[300],
            ),
            Expanded(
              child: _buildFooterStat(
                Icons.inventory_2,
                'Total',
                '${_repuestosConInfo.length}',
                Color(0xFF8E24AA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterStat(IconData icon, String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
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
}
