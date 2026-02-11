import 'package:flutter/material.dart';
import '../../widgets/responsive/responsive_builder.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../models/repuesto.dart';
import '../../../services/data_service.dart';
import '../../../main.dart';
import '../../dialogs/repuesto_form/repuesto_form_dialog.dart';
import '../../widgets/repuestos/repuestos_widgets.dart';
import 'layouts/repuestos_desktop_layout.dart';
import 'layouts/repuestos_mobile_layout.dart';

// =====================================================================
// === REPUESTOS SCREEN - Punto de entrada responsive =================
// =====================================================================
// Maneja estado, filtros, datos async y delega renderizado al layout
// correspondiente según el tamaño de pantalla

class RepuestosScreen extends StatefulWidget {
  @override
  _RepuestosScreenState createState() => _RepuestosScreenState();
}

class _RepuestosScreenState extends State<RepuestosScreen> {
  // --- FILTROS ---
  String _filtroSistema = 'Todos';
  String _filtroTipo = 'Todos';
  String _filtroTexto = '';
  late TextEditingController _searchController;

  // --- DATOS CACHEADOS ---
  List<RepuestoCatalogo> _todosRepuestos = [];
  List<RepuestoCatalogo> _repuestosFiltrados = [];
  List<String> _sistemasDisponibles = ['Todos'];
  List<String> _tiposDisponibles = ['Todos'];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _cargarDatos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final repuestos = await DataService.getCatalogoRepuestos();

      // Obtener sistemas y tipos disponibles
      final sistemas = <String>{'Todos'};
      final tipos = <String>{'Todos'};
      for (final r in repuestos) {
        sistemas.add(r.sistemaLabel);
        tipos.add(r.tipoLabel);
      }

      if (mounted) {
        setState(() {
          _todosRepuestos = repuestos;
          _sistemasDisponibles = sistemas.toList()..sort();
          _tiposDisponibles = tipos.toList()..sort();
          _isLoading = false;
        });
        _aplicarFiltros();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _aplicarFiltros() {
    var resultado = List<RepuestoCatalogo>.from(_todosRepuestos);

    // Filtrar por sistema
    if (_filtroSistema != 'Todos') {
      resultado =
          resultado.where((r) => r.sistemaLabel == _filtroSistema).toList();
    }

    // Filtrar por tipo
    if (_filtroTipo != 'Todos') {
      resultado = resultado.where((r) => r.tipoLabel == _filtroTipo).toList();
    }

    // Filtrar por texto
    if (_filtroTexto.isNotEmpty) {
      final texto = _filtroTexto.toLowerCase();
      resultado = resultado
          .where((r) =>
              r.nombre.toLowerCase().contains(texto) ||
              r.codigo.toLowerCase().contains(texto) ||
              r.descripcion.toLowerCase().contains(texto) ||
              (r.fabricante?.toLowerCase().contains(texto) ?? false))
          .toList();
    }

    // Ordenar
    resultado.sort((a, b) {
      final cmp = a.sistemaLabel.compareTo(b.sistemaLabel);
      if (cmp != 0) return cmp;
      return a.nombre.compareTo(b.nombre);
    });

    setState(() => _repuestosFiltrados = resultado);
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroSistema = 'Todos';
      _filtroTipo = 'Todos';
      _filtroTexto = '';
      _searchController.clear();
    });
    _aplicarFiltros();
  }

  // --- BUILD ---
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }
    if (_error != null) {
      return _buildErrorState();
    }

    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: SurayColors.blancoHumo,
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _mostrarDialogoRepuesto(context),
              backgroundColor: Color(0xFF1565C0),
              foregroundColor: Colors.white,
              child: Icon(Icons.add),
            )
          : null,
      body: ResponsiveBuilder(
        mobile: (context) => RepuestosMobileLayout(
          repuestosFiltrados: _repuestosFiltrados,
          filtroTexto: _filtroTexto,
          filtroSistema: _filtroSistema,
          filtroTipo: _filtroTipo,
          searchController: _searchController,
          sistemasDisponibles: _sistemasDisponibles,
          tiposDisponibles: _tiposDisponibles,
          totalRepuestos: _todosRepuestos.length,
          onTextoChanged: (v) {
            setState(() => _filtroTexto = v);
            _aplicarFiltros();
          },
          onSistemaChanged: (v) {
            setState(() => _filtroSistema = v);
            _aplicarFiltros();
          },
          onTipoChanged: (v) {
            setState(() => _filtroTipo = v);
            _aplicarFiltros();
          },
          onLimpiar: _limpiarFiltros,
          onVerDetalles: (r) =>
              showRepuestoDetallesDialog(context, r),
          onEditar: (r) =>
              _mostrarDialogoRepuesto(context, repuesto: r),
          onEliminar: (r) => _eliminarRepuesto(r.id),
          onCardTap: (r) => _showMobileActions(r),
        ),
        desktop: (context) => RepuestosDesktopLayout(
          repuestosFiltrados: _repuestosFiltrados,
          filtroTexto: _filtroTexto,
          filtroSistema: _filtroSistema,
          filtroTipo: _filtroTipo,
          searchController: _searchController,
          sistemasDisponibles: _sistemasDisponibles,
          tiposDisponibles: _tiposDisponibles,
          totalRepuestos: _todosRepuestos.length,
          onTextoChanged: (v) {
            setState(() => _filtroTexto = v);
            _aplicarFiltros();
          },
          onSistemaChanged: (v) {
            setState(() => _filtroSistema = v);
            _aplicarFiltros();
          },
          onTipoChanged: (v) {
            setState(() => _filtroTipo = v);
            _aplicarFiltros();
          },
          onLimpiar: _limpiarFiltros,
          onNuevoRepuesto: () => _mostrarDialogoRepuesto(context),
          onVerDetalles: (r) =>
              showRepuestoDetallesDialog(context, r),
          onEditar: (r) =>
              _mostrarDialogoRepuesto(context, repuesto: r),
          onEliminar: (r) => _eliminarRepuesto(r.id),
        ),
      ),
    );
  }

  // --- Mobile: bottom sheet de acciones ---
  void _showMobileActions(RepuestoCatalogo repuesto) {
    showRepuestoActionsSheet(
      context: context,
      repuesto: repuesto,
      onVerDetalles: () =>
          showRepuestoDetallesDialog(context, repuesto),
      onEditar: () =>
          _mostrarDialogoRepuesto(context, repuesto: repuesto),
      onEliminar: () => _eliminarRepuesto(repuesto.id),
    );
  }

  // --- Estados de carga ---
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: SurayColors.azulMarinoProfundo,
            strokeWidth: 4,
          ),
          SizedBox(height: 24),
          Text(
            'Cargando repuestos...',
            style: TextStyle(
              color: SurayColors.grisAntracita,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(32),
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error al cargar repuestos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: SurayColors.azulMarinoProfundo,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: SurayColors.grisAntracita),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarDatos,
              icon: Icon(Icons.refresh),
              label: Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SurayColors.azulMarinoProfundo,
                foregroundColor: SurayColors.blancoHumo,
                padding:
                    EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Diálogos ---
  void _mostrarDialogoRepuesto(BuildContext context,
      {RepuestoCatalogo? repuesto}) {
    RepuestoFormDialog.show(context, repuesto: repuesto).then((_) => _cargarDatos());
  }

  void _eliminarRepuesto(String id) async {
    final repuesto = await DataService.getRepuestoCatalogoById(id);
    if (repuesto == null) return;

    // Obtener vinculaciones (buses que tienen este repuesto asignado)
    final vinculaciones = await DataService.getVinculacionesRepuesto(id);
    
    showDialog(
      context: context,
      barrierColor: SurayColors.azulMarinoProfundo.withOpacity(0.5),
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Expanded(child: Text('Confirmar eliminación')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que quieres eliminar ${repuesto.nombre} del catálogo?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (vinculaciones.isNotEmpty) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.link, size: 20, color: Colors.orange[700]),
                          SizedBox(width: 8),
                          Text(
                            'Vinculaciones (${vinculaciones.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Este repuesto está asignado a:',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 8),
                      ...vinculaciones.take(5).map((v) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.directions_bus, size: 14, color: Colors.grey[600]),
                            SizedBox(width: 6),
                            Text('${v['busPatente']} (${v['cantidad']} uds)',
                                style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      )),
                      if (vinculaciones.length > 5)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'y ${vinculaciones.length - 5} más...',
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ),
                      SizedBox(height: 8),
                      Text(
                        'Al eliminar este repuesto, se eliminarán también todas sus asignaciones.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Eliminar todas las asignaciones primero
                for (var vinculacion in vinculaciones) {
                  await DataService.deleteRepuestoAsignado(vinculacion['asignadoId']);
                }
                
                // Luego eliminar el repuesto del catálogo
                await DataService.deleteRepuestoCatalogo(id);
                Navigator.pop(ctx);
                _cargarDatos();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${repuesto.nombre} eliminado del catálogo${vinculaciones.isNotEmpty ? ' y ${vinculaciones.length} asignación(es)' : ''}'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
