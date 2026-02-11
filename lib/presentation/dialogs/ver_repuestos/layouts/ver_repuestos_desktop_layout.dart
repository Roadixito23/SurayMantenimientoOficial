import 'package:flutter/material.dart';
import '../../../../models/bus.dart';
import '../../../../models/repuesto.dart';
import '../../../../models/repuesto_asignado.dart';
import '../../../../services/data_service.dart';
import '../../../../services/chilean_utils.dart';

class VerRepuestosDesktopLayout extends StatefulWidget {
  final Bus bus;
  final Function()? onRepuestoModificado;

  const VerRepuestosDesktopLayout({
    Key? key,
    required this.bus,
    this.onRepuestoModificado,
  }) : super(key: key);

  @override
  State<VerRepuestosDesktopLayout> createState() => _VerRepuestosDesktopLayoutState();
}

class _VerRepuestosDesktopLayoutState extends State<VerRepuestosDesktopLayout> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _repuestosConInfo = [];
  String _filtroEstado = 'Todos';
  String _filtroSistema = 'Todos';
  Map<String, dynamic>? _repuestoSeleccionado;

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
        if (repuestos.isNotEmpty) {
          _repuestoSeleccionado = repuestos.first;
        }
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
    return _repuestosConInfo.where((r) {
      final asignado = r['repuestoAsignado'] as RepuestoAsignado;
      final catalogo = r['repuestoCatalogo'] as RepuestoCatalogo;
      
      bool pasaFiltroEstado = _filtroEstado == 'Todos' ||
          (_filtroEstado == 'Instalados' && asignado.instalado) ||
          (_filtroEstado == 'Pendientes' && !asignado.instalado);
      
      bool pasaFiltroSistema = _filtroSistema == 'Todos' ||
          catalogo.sistemaLabel == _filtroSistema;
      
      return pasaFiltroEstado && pasaFiltroSistema;
    }).toList();
  }

  List<String> get _sistemasDisponibles {
    final sistemas = <String>{'Todos'};
    for (final r in _repuestosConInfo) {
      final catalogo = r['repuestoCatalogo'] as RepuestoCatalogo;
      sistemas.add(catalogo.sistemaLabel);
    }
    return sistemas.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Container(
        width: 950,
        height: 650,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: Color(0xFF8E24AA)),
                    )
                  : _repuestosConInfo.isEmpty
                      ? _buildEmptyState()
                      : Row(
                          children: [
                            // Panel izquierdo - Lista
                            Expanded(
                              flex: 2,
                              child: _buildListPanel(),
                            ),
                            // Divisor vertical
                            Container(
                              width: 1,
                              color: Colors.grey[200],
                            ),
                            // Panel derecho - Detalle
                            Expanded(
                              flex: 3,
                              child: _buildDetailPanel(),
                            ),
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
          colors: [Color(0xFF8E24AA), Color(0xFFAB47BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
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
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Repuestos Asignados',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${widget.bus.identificadorDisplay} • ${widget.bus.marca} ${widget.bus.modelo}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory, size: 18, color: Color(0xFF8E24AA)),
                SizedBox(width: 8),
                Text(
                  '${_repuestosConInfo.length} repuestos',
                  style: TextStyle(
                    color: Color(0xFF8E24AA),
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
    );
  }

  Widget _buildListPanel() {
    return Column(
      children: [
        // Filtros
        Container(
          padding: EdgeInsets.all(12),
          color: Colors.grey[50],
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _filtroEstado,
                      decoration: InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      items: ['Todos', 'Instalados', 'Pendientes']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (value) => setState(() => _filtroEstado = value!),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _filtroSistema,
                      decoration: InputDecoration(
                        labelText: 'Sistema',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      items: _sistemasDisponibles
                          .map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (value) => setState(() => _filtroSistema = value!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Lista
        Expanded(
          child: _repuestosFiltrados.isEmpty
              ? Center(
                  child: Text(
                    'No hay repuestos con estos filtros',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(8),
                  itemCount: _repuestosFiltrados.length,
                  itemBuilder: (context, index) {
                    final item = _repuestosFiltrados[index];
                    final asignado = item['repuestoAsignado'] as RepuestoAsignado;
                    final catalogo = item['repuestoCatalogo'] as RepuestoCatalogo;
                    final isSelected = _repuestoSeleccionado == item;

                    return _buildRepuestoListItem(item, asignado, catalogo, isSelected);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRepuestoListItem(
    Map<String, dynamic> item,
    RepuestoAsignado asignado,
    RepuestoCatalogo catalogo,
    bool isSelected,
  ) {
    final bool vencido = asignado.proximoCambio != null &&
        asignado.proximoCambio!.isBefore(DateTime.now());
    final bool proximoVencer = asignado.proximoCambio != null &&
        !vencido &&
        asignado.proximoCambio!.difference(DateTime.now()).inDays <= 30;

    Color statusColor = asignado.instalado 
        ? (vencido ? Colors.red : (proximoVencer ? Colors.orange : Colors.green))
        : Colors.blue;

    return Card(
      margin: EdgeInsets.only(bottom: 6),
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? Color(0xFF8E24AA) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _repuestoSeleccionado = item),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
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
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      catalogo.nombre,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      catalogo.codigo,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPanel() {
    if (_repuestoSeleccionado == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Selecciona un repuesto para ver detalles',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final asignado = _repuestoSeleccionado!['repuestoAsignado'] as RepuestoAsignado;
    final catalogo = _repuestoSeleccionado!['repuestoCatalogo'] as RepuestoCatalogo;

    final bool vencido = asignado.proximoCambio != null &&
        asignado.proximoCambio!.isBefore(DateTime.now());
    final bool proximoVencer = asignado.proximoCambio != null &&
        !vencido &&
        asignado.proximoCambio!.difference(DateTime.now()).inDays <= 30;

    Color statusColor = asignado.instalado 
        ? (vencido ? Colors.red : (proximoVencer ? Colors.orange : Colors.green))
        : Colors.blue;
    
    String statusText = asignado.instalado 
        ? (vencido ? 'Vencido' : (proximoVencer ? 'Próximo a vencer' : 'Instalado'))
        : 'Pendiente de instalación';

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del detalle
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getSistemaColor(catalogo.sistema).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getSistemaIcon(catalogo.sistema),
                  color: _getSistemaColor(catalogo.sistema),
                  size: 36,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      catalogo.nombre,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            catalogo.codigo,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Información del repuesto
          _buildDetailSection(
            'Información del Repuesto',
            Icons.info_outline,
            [
              _buildDetailRow('Sistema', catalogo.sistemaLabel),
              _buildDetailRow('Tipo', _getTipoLabel(catalogo.tipo)),
              if (catalogo.fabricante != null)
                _buildDetailRow('Fabricante', catalogo.fabricante!),
              if (catalogo.numeroOEM != null)
                _buildDetailRow('Número OEM', catalogo.numeroOEM!),
              if (catalogo.descripcion.isNotEmpty)
                _buildDetailRow('Descripción', catalogo.descripcion),
            ],
          ),
          SizedBox(height: 16),

          // Información de asignación
          _buildDetailSection(
            'Asignación',
            Icons.assignment,
            [
              _buildDetailRow('Cantidad', '${asignado.cantidad} unidades'),
              _buildDetailRow('Ubicación en vehículo', asignado.ubicacionBus ?? 'No especificada'),
              _buildDetailRow('Fecha de asignación', ChileanUtils.formatDate(asignado.fechaAsignacion)),
            ],
          ),

          if (asignado.instalado) ...[
            SizedBox(height: 16),
            _buildDetailSection(
              'Instalación',
              Icons.build,
              [
                if (asignado.fechaInstalacion != null)
                  _buildDetailRow('Fecha de instalación', ChileanUtils.formatDate(asignado.fechaInstalacion!)),
                if (asignado.proximoCambio != null)
                  _buildDetailRow('Próximo cambio', ChileanUtils.formatDate(asignado.proximoCambio!)),
                if (asignado.tecnicoResponsable != null)
                  _buildDetailRow('Técnico responsable', asignado.tecnicoResponsable!),
              ],
            ),
          ],

          if (asignado.observaciones != null && asignado.observaciones!.isNotEmpty) ...[
            SizedBox(height: 16),
            _buildDetailSection(
              'Observaciones',
              Icons.notes,
              [
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    asignado.observaciones!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Color(0xFF8E24AA)),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E24AA),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Color(0xFF8E24AA).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Color(0xFF8E24AA).withOpacity(0.5),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Sin repuestos asignados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Este vehículo no tiene repuestos vinculados.\nAsigna repuestos para llevar control de su mantenimiento.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
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
    final vencidos = _repuestosConInfo.where((r) {
      final asignado = r['repuestoAsignado'] as RepuestoAsignado;
      return asignado.proximoCambio != null && 
             asignado.proximoCambio!.isBefore(DateTime.now());
    }).length;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          _buildFooterStat(Icons.inventory_2, 'Total', '${_repuestosConInfo.length}', Color(0xFF8E24AA)),
          SizedBox(width: 24),
          _buildFooterStat(Icons.check_circle, 'Instalados', '$instalados', Colors.green),
          SizedBox(width: 24),
          _buildFooterStat(Icons.pending_actions, 'Pendientes', '$pendientes', Colors.blue),
          if (vencidos > 0) ...[
            SizedBox(width: 24),
            _buildFooterStat(Icons.warning, 'Vencidos', '$vencidos', Colors.red),
          ],
          Spacer(),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close),
            label: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterStat(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
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
