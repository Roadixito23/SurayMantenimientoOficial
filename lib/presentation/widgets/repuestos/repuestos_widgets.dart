import 'package:flutter/material.dart';
import '../../../models/repuesto.dart';
import '../../../services/chilean_utils.dart';
import '../../../main.dart';

// =====================================================================
// === WIDGETS COMPARTIDOS - Pantalla de Repuestos =====================
// =====================================================================
// Widgets reutilizados en layouts mobile y desktop

// ---------------------------------------------------------------------
// Ícono por sistema de vehículo
// ---------------------------------------------------------------------
class SistemaVehiculoIcon extends StatelessWidget {
  final SistemaVehiculo sistema;
  final double size;

  const SistemaVehiculoIcon({
    Key? key,
    required this.sistema,
    this.size = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color color;

    switch (sistema) {
      case SistemaVehiculo.motor:
        iconData = Icons.settings;
        color = Colors.red;
        break;
      case SistemaVehiculo.frenos:
        iconData = Icons.disc_full;
        color = Colors.orange;
        break;
      case SistemaVehiculo.transmision:
        iconData = Icons.settings_applications;
        color = Colors.purple;
        break;
      case SistemaVehiculo.electrico:
        iconData = Icons.electrical_services;
        color = Colors.yellow[700]!;
        break;
      case SistemaVehiculo.suspension:
        iconData = Icons.compare_arrows;
        color = Colors.green;
        break;
      case SistemaVehiculo.neumaticos:
        iconData = Icons.tire_repair;
        color = Colors.black;
        break;
      case SistemaVehiculo.carroceria:
        iconData = Icons.directions_bus;
        color = Colors.blue;
        break;
      case SistemaVehiculo.climatizacion:
        iconData = Icons.ac_unit;
        color = Colors.cyan;
        break;
      case SistemaVehiculo.combustible:
        iconData = Icons.local_gas_station;
        color = Colors.brown;
        break;
      case SistemaVehiculo.refrigeracion:
        iconData = Icons.thermostat;
        color = Colors.lightBlue;
        break;
    }

    return Icon(iconData, color: color, size: size);
  }
}

// ---------------------------------------------------------------------
// Color según tipo de repuesto
// ---------------------------------------------------------------------
Color getTipoRepuestoColor(TipoRepuesto tipo) {
  switch (tipo) {
    case TipoRepuesto.original:
      return Colors.green[100]!;
    case TipoRepuesto.alternativo:
      return Colors.blue[100]!;
    case TipoRepuesto.generico:
      return Colors.grey[200]!;
  }
}

// ---------------------------------------------------------------------
// Chip de información (fabricante, OEM, precio)
// ---------------------------------------------------------------------
class RepuestoInfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const RepuestoInfoChip({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text('$label: $value', style: TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey[100],
    );
  }
}

// ---------------------------------------------------------------------
// Card de repuesto completa (usada en desktop)
// ---------------------------------------------------------------------
class RepuestoCardFull extends StatelessWidget {
  final RepuestoCatalogo repuesto;
  final VoidCallback onVerDetalles;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const RepuestoCardFull({
    Key? key,
    required this.repuesto,
    required this.onVerDetalles,
    required this.onEditar,
    required this.onEliminar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      repuesto.nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(repuesto.tipoLabel),
                    backgroundColor: getTipoRepuestoColor(repuesto.tipo),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Código: ${repuesto.codigo}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(repuesto.descripcion),
              SizedBox(height: 12),
              // Información básica
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (repuesto.fabricante != null)
                    RepuestoInfoChip(
                      label: 'Fabricante',
                      value: repuesto.fabricante!,
                      icon: Icons.factory,
                    ),
                  if (repuesto.numeroOEM != null)
                    RepuestoInfoChip(
                      label: 'OEM',
                      value: repuesto.numeroOEM!,
                      icon: Icons.tag,
                    ),
                  if (repuesto.precioReferencial != null)
                    RepuestoInfoChip(
                      label: 'Precio',
                      value: ChileanUtils.formatCurrency(
                          repuesto.precioReferencial!),
                      icon: Icons.attach_money,
                    ),
                ],
              ),
              if (repuesto.observaciones != null) ...[
                SizedBox(height: 8),
                Text(
                  'Observaciones: ${repuesto.observaciones}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
              // Acciones
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onVerDetalles,
                    icon: Icon(Icons.info),
                    label: Text('Detalles'),
                  ),
                  SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onEditar,
                    icon: Icon(Icons.edit),
                    label: Text('Editar'),
                  ),
                  SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onEliminar,
                    icon: Icon(Icons.delete, color: Colors.red),
                    label: Text('Eliminar',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Card de repuesto compacta (usada en mobile)
// ---------------------------------------------------------------------
class RepuestoCardCompact extends StatelessWidget {
  final RepuestoCatalogo repuesto;
  final VoidCallback onTap;

  const RepuestoCardCompact({
    Key? key,
    required this.repuesto,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // Ícono del sistema
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SurayColors.azulMarinoProfundo.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SistemaVehiculoIcon(
                  sistema: repuesto.sistema,
                  size: 22,
                ),
              ),
              SizedBox(width: 12),
              // Info principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repuesto.nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: SurayColors.azulMarinoProfundo,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      repuesto.codigo,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: SurayColors.grisAntracita,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: getTipoRepuestoColor(repuesto.tipo),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            repuesto.tipoLabel,
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                        if (repuesto.precioReferencial != null) ...[
                          SizedBox(width: 8),
                          Text(
                            ChileanUtils.formatCurrency(
                                repuesto.precioReferencial!),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Flecha
              Icon(
                Icons.chevron_right,
                color: SurayColors.grisAntracitaClaro,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Filtros adaptivos
// ---------------------------------------------------------------------
class RepuestoFilters extends StatelessWidget {
  final String filtroTexto;
  final String filtroSistema;
  final String filtroTipo;
  final TextEditingController searchController;
  final List<String> sistemasDisponibles;
  final List<String> tiposDisponibles;
  final bool compact;
  final ValueChanged<String> onTextoChanged;
  final ValueChanged<String> onSistemaChanged;
  final ValueChanged<String> onTipoChanged;
  final VoidCallback onLimpiar;

  const RepuestoFilters({
    Key? key,
    required this.filtroTexto,
    required this.filtroSistema,
    required this.filtroTipo,
    required this.searchController,
    required this.sistemasDisponibles,
    required this.tiposDisponibles,
    this.compact = false,
    required this.onTextoChanged,
    required this.onSistemaChanged,
    required this.onTipoChanged,
    required this.onLimpiar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactFilters();
    }
    return _buildFullFilters();
  }

  /// Filtros desktop: todo en una fila
  Widget _buildFullFilters() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Búsqueda
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar repuesto, código o descripción',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: onTextoChanged,
                  ),
                ),
                SizedBox(width: 16),
                // Filtro sistema
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: sistemasDisponibles.contains(filtroSistema)
                        ? filtroSistema
                        : 'Todos',
                    decoration: InputDecoration(
                      labelText: 'Sistema',
                      border: OutlineInputBorder(),
                    ),
                    items: sistemasDisponibles
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => onSistemaChanged(v ?? 'Todos'),
                  ),
                ),
                SizedBox(width: 16),
                // Filtro tipo
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: tiposDisponibles.contains(filtroTipo)
                        ? filtroTipo
                        : 'Todos',
                    decoration: InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: tiposDisponibles
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => onTipoChanged(v ?? 'Todos'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: onLimpiar,
                  icon: Icon(Icons.clear, size: 18),
                  label: Text('Limpiar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Filtros mobile: búsqueda + dropdowns apilados
  Widget _buildCompactFilters() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            // Búsqueda
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar repuesto...',
                prefixIcon: Icon(Icons.search, size: 20),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
              onChanged: onTextoChanged,
            ),
            SizedBox(height: 8),
            // Dropdowns en fila
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: sistemasDisponibles.contains(filtroSistema)
                        ? filtroSistema
                        : 'Todos',
                    decoration: InputDecoration(
                      labelText: 'Sistema',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true,
                    ),
                    isExpanded: true,
                    items: sistemasDisponibles
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s,
                                style: TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => onSistemaChanged(v ?? 'Todos'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: tiposDisponibles.contains(filtroTipo)
                        ? filtroTipo
                        : 'Todos',
                    decoration: InputDecoration(
                      labelText: 'Tipo',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true,
                    ),
                    isExpanded: true,
                    items: tiposDisponibles
                        .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t,
                                style: TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => onTipoChanged(v ?? 'Todos'),
                  ),
                ),
                SizedBox(width: 8),
                // Botón limpiar compacto
                IconButton(
                  onPressed: onLimpiar,
                  icon: Icon(Icons.clear, size: 20),
                  tooltip: 'Limpiar filtros',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Diálogo de detalles del repuesto
// ---------------------------------------------------------------------
void showRepuestoDetallesDialog(
    BuildContext context, RepuestoCatalogo repuesto) {
  final isSmall = MediaQuery.of(context).size.width < 600;

  showDialog(
    context: context,
    barrierColor: SurayColors.azulMarinoProfundo.withOpacity(0.5),
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              SurayColors.azulMarinoProfundo,
              SurayColors.azulMarinoClaro,
            ],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            SistemaVehiculoIcon(
                sistema: repuesto.sistema, size: isSmall ? 20 : 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                repuesto.nombre,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmall ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      content: Container(
        width: isSmall ? double.maxFinite : 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Código', repuesto.codigo, true),
              _buildDetailRow('Sistema', repuesto.sistemaLabel, false),
              _buildDetailRow('Tipo', repuesto.tipoLabel, false),
              SizedBox(height: 8),
              Text(
                repuesto.descripcion,
                style: TextStyle(color: SurayColors.grisAntracita),
              ),
              SizedBox(height: 12),
              if (repuesto.fabricante != null)
                _buildDetailRow('Fabricante', repuesto.fabricante!, false),
              if (repuesto.numeroOEM != null)
                _buildDetailRow('OEM', repuesto.numeroOEM!, false),
              if (repuesto.precioReferencial != null)
                _buildDetailRow(
                  'Precio referencial',
                  ChileanUtils.formatCurrency(repuesto.precioReferencial!),
                  false,
                ),
              if (repuesto.observaciones != null) ...[
                SizedBox(height: 8),
                Text(
                  'Observaciones:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  repuesto.observaciones!,
                  style: TextStyle(
                      fontSize: 13, color: SurayColors.grisAntracita),
                ),
              ],
              SizedBox(height: 12),
              Text(
                'Actualizado: ${ChileanUtils.formatDate(repuesto.fechaActualizacion)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cerrar'),
        ),
      ],
    ),
  );
}

Widget _buildDetailRow(String label, String value, bool bold) {
  return Padding(
    padding: EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: SurayColors.grisAntracita,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
              fontFamily: bold ? 'monospace' : null,
            ),
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------
// Bottom sheet de acciones para mobile
// ---------------------------------------------------------------------
void showRepuestoActionsSheet({
  required BuildContext context,
  required RepuestoCatalogo repuesto,
  required VoidCallback onVerDetalles,
  required VoidCallback onEditar,
  required VoidCallback onEliminar,
}) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle visual
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Título
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  SistemaVehiculoIcon(sistema: repuesto.sistema, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          repuesto.nombre,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          repuesto.codigo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(),
            ListTile(
              leading:
                  Icon(Icons.info, color: SurayColors.azulMarinoProfundo),
              title: Text('Ver detalles'),
              onTap: () {
                Navigator.pop(ctx);
                onVerDetalles();
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.edit, color: SurayColors.naranjaQuemado),
              title: Text('Editar repuesto'),
              onTap: () {
                Navigator.pop(ctx);
                onEditar();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Eliminar', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                onEliminar();
              },
            ),
          ],
        ),
      ),
    ),
  );
}
