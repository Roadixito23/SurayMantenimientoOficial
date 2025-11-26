import 'package:flutter/material.dart';
import '../models/tipo_mantenimiento_personalizado.dart';
import '../services/data_service.dart';

/// Widget selector de tipos de mantenimiento personalizado con autocompletado
class TipoMantenimientoSelector extends StatefulWidget {
  final TipoMantenimiento? tipoMantenimientoInicial;
  final String? tituloInicial;
  final String? descripcionInicial;
  final Function(TipoMantenimiento tipoBase, String titulo, String? descripcion)? onChanged;
  final bool requerido;
  final String? labelTipo;
  final String? labelTitulo;
  final String? labelDescripcion;

  const TipoMantenimientoSelector({
    Key? key,
    this.tipoMantenimientoInicial,
    this.tituloInicial,
    this.descripcionInicial,
    this.onChanged,
    this.requerido = true,
    this.labelTipo = 'Tipo de Mantenimiento',
    this.labelTitulo = 'Título del Mantenimiento',
    this.labelDescripcion = 'Descripción (opcional)',
  }) : super(key: key);

  @override
  _TipoMantenimientoSelectorState createState() => _TipoMantenimientoSelectorState();
}

class _TipoMantenimientoSelectorState extends State<TipoMantenimientoSelector> {
  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;

  TipoMantenimiento _tipoSeleccionado = TipoMantenimiento.preventivo;
  List<TipoMantenimientoPersonalizado> _tiposDisponibles = [];
  List<TipoMantenimientoPersonalizado> _sugerencias = [];
  bool _mostrandoSugerencias = false;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.tituloInicial ?? '');
    _descripcionController = TextEditingController(text: widget.descripcionInicial ?? '');
    _tipoSeleccionado = widget.tipoMantenimientoInicial ?? TipoMantenimiento.preventivo;

    _cargarTiposDisponibles();
    _tituloController.addListener(_onTituloChanged);
  }

  @override
  void dispose() {
    _tituloController.removeListener(_onTituloChanged);
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _cargarTiposDisponibles() async {
    final tipos = await DataService.getTiposMantenimientoActivos();
    setState(() {
      _tiposDisponibles = tipos;
    });
  }

  void _onTituloChanged() {
    final query = _tituloController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _sugerencias = [];
        _mostrandoSugerencias = false;
      });
      _notificarCambio();
      return;
    }

    // Filtrar sugerencias por tipo seleccionado
    final sugerenciasFiltradas = _tiposDisponibles
        .where((tipo) =>
    tipo.tipoBase == _tipoSeleccionado &&
        tipo.titulo.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();

    setState(() {
      _sugerencias = sugerenciasFiltradas;
      _mostrandoSugerencias = sugerenciasFiltradas.isNotEmpty;
    });

    _notificarCambio();
  }

  void _notificarCambio() {
    if (widget.onChanged != null) {
      widget.onChanged!(
        _tipoSeleccionado,
        _tituloController.text.trim(),
        _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
      );
    }
  }

  void _seleccionarSugerencia(TipoMantenimientoPersonalizado tipo) {
    setState(() {
      _tituloController.text = tipo.titulo;
      _descripcionController.text = tipo.descripcion ?? '';
      _mostrandoSugerencias = false;
    });
    _notificarCambio();
  }

  // ✅ NUEVO: Método para seleccionar filtro crítico rápidamente
  void _seleccionarFiltroCritico(String titulo) {
    setState(() {
      _tipoSeleccionado = TipoMantenimiento.preventivo;
      _tituloController.text = titulo;
      _descripcionController.text = 'Cambio preventivo del ${titulo.toLowerCase()}. Crítico para alertas de kilometraje.';
      _mostrandoSugerencias = false;
    });
    _notificarCambio();
  }

  void _onTipoChanged(TipoMantenimiento? nuevoTipo) {
    if (nuevoTipo != null) {
      setState(() {
        _tipoSeleccionado = nuevoTipo;
        _mostrandoSugerencias = false;
      });
      _onTituloChanged(); // Refiltrar sugerencias
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ NUEVO: Panel de filtros críticos destacados
        _buildFiltrosCriticosPanel(),
        SizedBox(height: 16),

        // Selector de tipo base
        DropdownButtonFormField<TipoMantenimiento>(
          value: _tipoSeleccionado,
          decoration: InputDecoration(
            labelText: widget.labelTipo,
            border: OutlineInputBorder(),
            prefixIcon: Icon(_getIconoTipo(_tipoSeleccionado)),
          ),
          items: TipoMantenimiento.values.map((tipo) {
            return DropdownMenuItem(
              value: tipo,
              child: Row(
                children: [
                  Icon(_getIconoTipo(tipo), size: 20, color: _getColorTipo(tipo)),
                  SizedBox(width: 8),
                  Text(_getLabelTipo(tipo)),
                ],
              ),
            );
          }).toList(),
          onChanged: _onTipoChanged,
          validator: widget.requerido ? (value) {
            if (value == null) return 'Selecciona un tipo de mantenimiento';
            return null;
          } : null,
        ),

        SizedBox(height: 16),

        // Campo de título con autocompletado
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _tituloController,
              decoration: InputDecoration(
                labelText: widget.labelTitulo,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
                suffixIcon: _mostrandoSugerencias
                    ? Icon(Icons.keyboard_arrow_down)
                    : Icon(Icons.edit),
                helperText: 'Escribe o selecciona de trabajos anteriores',
              ),
              validator: widget.requerido ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El título del mantenimiento es requerido';
                }
                if (value.trim().length < 3) {
                  return 'El título debe tener al menos 3 caracteres';
                }
                return null;
              } : null,
            ),

            // Panel de sugerencias
            if (_mostrandoSugerencias) ...[
              SizedBox(height: 4),
              Container(
                constraints: BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _sugerencias.length,
                  itemBuilder: (context, index) {
                    final tipo = _sugerencias[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        tipo.esFiltroCritico ? tipo.iconoEspecifico : _getIconoTipo(tipo.tipoBase),
                        size: 20,
                        color: tipo.esFiltroCritico ? tipo.colorEspecifico : _getColorTipo(tipo.tipoBase),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              tipo.titulo,
                              style: TextStyle(
                                fontWeight: tipo.esFiltroCritico ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (tipo.esFiltroCritico) ...[
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'CRÍTICO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: tipo.descripcion != null
                          ? Text(
                        tipo.descripcion!,
                        style: TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                          : null,
                      trailing: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${tipo.vecesUsado}x',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () => _seleccionarSugerencia(tipo),
                    );
                  },
                ),
              ),
            ],
          ],
        ),

        SizedBox(height: 16),

        // Campo de descripción
        TextFormField(
          controller: _descripcionController,
          decoration: InputDecoration(
            labelText: widget.labelDescripcion,
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            hintText: 'Detalles adicionales del mantenimiento...',
          ),
          maxLines: 2,
          onChanged: (_) => _notificarCambio(),
        ),

        SizedBox(height: 12),

        // Información del tipo seleccionado
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getColorTipo(_tipoSeleccionado).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getColorTipo(_tipoSeleccionado).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(_getIconoTipo(_tipoSeleccionado), color: _getColorTipo(_tipoSeleccionado)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getLabelTipo(_tipoSeleccionado),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getColorTipo(_tipoSeleccionado),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getDescripcionTipo(_tipoSeleccionado),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Estadística de tipos usados
        if (_tiposDisponibles.isNotEmpty) ...[
          SizedBox(height: 12),
          _buildEstadisticasTipos(),
        ],
      ],
    );
  }

  // ✅ NUEVO: Panel destacado para filtros críticos
  Widget _buildFiltrosCriticosPanel() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange[50]!,
            Colors.red[50]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700], size: 20),
              SizedBox(width: 8),
              Text(
                'Filtros con Alertas de Kilometraje',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Estos filtros activan alertas automáticas cuando superan 5000 km/mes:',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBotonFiltroCritico(
                  'Filtro de Aceite',
                  Icons.opacity,
                  Color(0xFFFF9800),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildBotonFiltroCritico(
                  'Filtro de Aire',
                  Icons.air,
                  Color(0xFF9E9E9E),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildBotonFiltroCritico(
                  'Filtro de Combustible',
                  Icons.local_gas_station,
                  Color(0xFF795548),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotonFiltroCritico(String titulo, IconData icono, Color color) {
    final esSeleccionado = _tituloController.text == titulo;

    return InkWell(
      onTap: () => _seleccionarFiltroCritico(titulo),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: esSeleccionado ? color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color,
            width: esSeleccionado ? 2 : 1,
          ),
          boxShadow: esSeleccionado ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            Icon(
              icono,
              color: esSeleccionado ? Colors.white : color,
              size: 20,
            ),
            SizedBox(height: 4),
            Text(
              titulo.replaceAll('Filtro de ', ''),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: esSeleccionado ? Colors.white : color,
              ),
              textAlign: TextAlign.center,
            ),
            if (esSeleccionado) ...[
              SizedBox(height: 2),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SELECCIONADO',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticasTipos() {
    final tiposPorCategoria = <TipoMantenimiento, List<TipoMantenimientoPersonalizado>>{};

    for (final tipo in _tiposDisponibles) {
      tiposPorCategoria.putIfAbsent(tipo.tipoBase, () => []).add(tipo);
    }

    final filtrosCriticos = _tiposDisponibles.where((t) => t.esFiltroCritico).length;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipos disponibles en el sistema:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              ...TipoMantenimiento.values.map((tipo) {
                final count = tiposPorCategoria[tipo]?.length ?? 0;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getIconoTipo(tipo), size: 14, color: _getColorTipo(tipo)),
                    SizedBox(width: 4),
                    Text(
                      '${_getLabelTipo(tipo)}: $count',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                );
              }),
              // ✅ NUEVO: Mostrar contador de filtros críticos
              if (filtrosCriticos > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, size: 14, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      'Críticos: $filtrosCriticos',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Métodos de utilidad para iconos, colores y labels
  IconData _getIconoTipo(TipoMantenimiento tipo) {
    switch (tipo) {
      case TipoMantenimiento.correctivo:
        return Icons.handyman;
      case TipoMantenimiento.rutinario:
        return Icons.schedule;
      case TipoMantenimiento.preventivo:
        return Icons.build_circle;
    }
  }

  Color _getColorTipo(TipoMantenimiento tipo) {
    switch (tipo) {
      case TipoMantenimiento.correctivo:
        return Color(0xFFE53E3E); // Rojo
      case TipoMantenimiento.rutinario:
        return Color(0xFF3182CE); // Azul
      case TipoMantenimiento.preventivo:
        return Color(0xFF38A169); // Verde
    }
  }

  String _getLabelTipo(TipoMantenimiento tipo) {
    switch (tipo) {
      case TipoMantenimiento.correctivo:
        return 'Correctivo';
      case TipoMantenimiento.rutinario:
        return 'Rutinario';
      case TipoMantenimiento.preventivo:
        return 'Preventivo';
    }
  }

  String _getDescripcionTipo(TipoMantenimiento tipo) {
    switch (tipo) {
      case TipoMantenimiento.correctivo:
        return 'Reparación de fallos o averías detectadas';
      case TipoMantenimiento.rutinario:
        return 'Mantenimiento programado y regular';
      case TipoMantenimiento.preventivo:
        return 'Prevención de fallos futuros';
    }
  }
}

/// Widget simplificado para selección rápida de tipo
class TipoMantenimientoSelectorCompacto extends StatelessWidget {
  final TipoMantenimiento? valor;
  final Function(TipoMantenimiento?)? onChanged;
  final String? labelText;

  const TipoMantenimientoSelectorCompacto({
    Key? key,
    this.valor,
    this.onChanged,
    this.labelText = 'Tipo',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TipoMantenimiento>(
      value: valor,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: TipoMantenimiento.values.map((tipo) {
        Color color;
        IconData icon;
        String label;

        switch (tipo) {
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

        return DropdownMenuItem(
          value: tipo,
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 14)),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}