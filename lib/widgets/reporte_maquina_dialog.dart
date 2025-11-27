import 'dart:core';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import '../models/bus.dart';
import '../services/data_service.dart';
import '../main.dart';

class ReporteMaquinaDialog extends StatefulWidget {
  const ReporteMaquinaDialog({Key? key}) : super(key: key);

  @override
  _ReporteMaquinaDialogState createState() => _ReporteMaquinaDialogState();
}

class _ReporteMaquinaDialogState extends State<ReporteMaquinaDialog> {
  final _searchController = TextEditingController();
  List<Bus> _busesEncontrados = [];
  Bus? _busSeleccionado;
  String _tipoReporte = 'Diario';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _buscarMaquina() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final buses = await DataService.getBuses();

      // Buscar por patente o número de máquina (identificador)
      final resultados = buses.where((bus) {
        final patente = bus.patente.toLowerCase();
        final identificador = bus.identificador?.toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();

        return patente.contains(searchQuery) ||
               identificador.contains(searchQuery);
      }).toList();

      setState(() {
        _busesEncontrados = resultados;
        _isSearching = false;
      });

      if (resultados.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('No se encontraron máquinas con ese criterio'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Error al buscar: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _generarReportePDF() {
    if (_busSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_outlined, color: Colors.white),
              SizedBox(width: 12),
              Text('Por favor selecciona una máquina'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    final bus = _busSeleccionado!;
    final fechaActual = DateTime.now();

    // Calcular fechas según el tipo de reporte
    DateTime fechaInicio;
    String periodoTexto;

    switch (_tipoReporte) {
      case 'Diario':
        fechaInicio = DateTime(fechaActual.year, fechaActual.month, fechaActual.day);
        periodoTexto = 'Diario - ${DateFormat('dd/MM/yyyy').format(fechaActual)}';
        break;
      case 'Semanal':
        fechaInicio = fechaActual.subtract(Duration(days: 7));
        periodoTexto = 'Semanal - ${DateFormat('dd/MM/yyyy').format(fechaInicio)} a ${DateFormat('dd/MM/yyyy').format(fechaActual)}';
        break;
      case 'Quincenal':
        fechaInicio = fechaActual.subtract(Duration(days: 15));
        periodoTexto = 'Quincenal - ${DateFormat('dd/MM/yyyy').format(fechaInicio)} a ${DateFormat('dd/MM/yyyy').format(fechaActual)}';
        break;
      case 'Mensual':
        fechaInicio = DateTime(fechaActual.year, fechaActual.month - 1, fechaActual.day);
        periodoTexto = 'Mensual - ${DateFormat('MMMM yyyy', 'es').format(fechaActual)}';
        break;
      default:
        fechaInicio = fechaActual;
        periodoTexto = 'Reporte';
    }

    // Generar HTML del reporte
    final htmlContent = _generarHTMLReporte(bus, periodoTexto, fechaInicio, fechaActual);

    // Crear y descargar el PDF (usando impresión del navegador)
    final blob = html.Blob([htmlContent], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..target = 'blank'
      ..download = 'reporte_${bus.patente}_${_tipoReporte.toLowerCase()}_${DateFormat('yyyyMMdd').format(fechaActual)}.html';

    anchor.click();
    html.Url.revokeObjectUrl(url);

    // Abrir ventana de impresión
    _abrirVentanaImpresion(htmlContent);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('Reporte generado. Se abrirá la ventana de impresión.'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _abrirVentanaImpresion(String htmlContent) {
    final printWindow = html.window.open('', '_blank', 'width=800,height=600');
    if (printWindow != null) {
      printWindow.document?.write(htmlContent);
      printWindow.document?.close();

      // Esperar a que cargue y luego imprimir
      Future.delayed(Duration(milliseconds: 500), () {
        printWindow.print();
      });
    }
  }

  String _generarHTMLReporte(Bus bus, String periodoTexto, DateTime fechaInicio, DateTime fechaFin) {
    final fechaActual = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final revisionTecnicaFecha = bus.fechaRevisionTecnica != null
        ? DateFormat('dd/MM/yyyy').format(bus.fechaRevisionTecnica!)
        : 'No registrada';

    final diasVencer = bus.diasParaVencimientoRevision;
    final estadoRevision = bus.revisionTecnicaVencida
        ? '<span style="color: red; font-weight: bold;">VENCIDA</span>'
        : bus.revisionTecnicaProximaAVencer
            ? '<span style="color: orange; font-weight: bold;">Próxima a vencer ($diasVencer días)</span>'
            : '<span style="color: green;">Vigente ($diasVencer días)</span>';

    final kmActual = bus.kilometraje?.toStringAsFixed(0) ?? 'No registrado';
    final kmIdeal = bus.kilometrajeIdeal?.toStringAsFixed(0) ?? 'No configurado';

    // Calcular kilometraje desde última mantención
    String kmDesdeUltimaMant = 'No disponible';
    if (bus.mantenimientoPreventivo?.historialMantenimientos.isNotEmpty ?? false) {
      final ultimaMant = bus.mantenimientoPreventivo!.historialMantenimientos.first;
      if (bus.kilometraje != null && ultimaMant.kilometrajeUltimoCambio != null) {
        final diff = bus.kilometraje! - ultimaMant.kilometrajeUltimoCambio!;
        kmDesdeUltimaMant = '${diff.toStringAsFixed(0)} km';
      }
    }

    // Generar historial de mantenciones
    String historialHTML = '';
    if (bus.mantenimientoPreventivo?.historialMantenimientos.isNotEmpty ?? false) {
      final mantenciones = bus.mantenimientoPreventivo!.historialMantenimientos;

      // Filtrar por fecha según el tipo de reporte
      final mantencionesEnPeriodo = mantenciones.where((m) {
        return m.fechaUltimoCambio.isAfter(fechaInicio) &&
               m.fechaUltimoCambio.isBefore(fechaFin.add(Duration(days: 1)));
      }).toList();

      if (mantencionesEnPeriodo.isNotEmpty) {
        historialHTML = '<h3 style="color: #1976D2; margin-top: 20px;">Mantenciones en el Periodo</h3>';
        historialHTML += '<table style="width: 100%; border-collapse: collapse; margin-top: 10px;">';
        historialHTML += '<tr style="background-color: #E3F2FD;">';
        historialHTML += '<th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Fecha</th>';
        historialHTML += '<th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Tipo</th>';
        historialHTML += '<th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Kilometraje</th>';
        historialHTML += '<th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Técnico</th>';
        historialHTML += '<th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Observaciones</th>';
        historialHTML += '</tr>';

        for (var mant in mantencionesEnPeriodo) {
          historialHTML += '<tr>';
          historialHTML += '<td style="border: 1px solid #ddd; padding: 8px;">${DateFormat('dd/MM/yyyy').format(mant.fechaUltimoCambio)}</td>';
          historialHTML += '<td style="border: 1px solid #ddd; padding: 8px;">${mant.descripcionTipo}</td>';
          historialHTML += '<td style="border: 1px solid #ddd; padding: 8px;">${mant.kilometrajeUltimoCambio?.toStringAsFixed(0) ?? 'N/A'} km</td>';
          historialHTML += '<td style="border: 1px solid #ddd; padding: 8px;">${mant.tecnicoResponsable ?? 'No especificado'}</td>';
          historialHTML += '<td style="border: 1px solid #ddd; padding: 8px;">${mant.observaciones ?? '-'}</td>';
          historialHTML += '</tr>';
        }
        historialHTML += '</table>';
      } else {
        historialHTML = '<p style="color: #666; margin-top: 20px;"><em>No se registraron mantenciones en este periodo.</em></p>';
      }

      // Agregar historial completo (últimas 10)
      historialHTML += '<h3 style="color: #1976D2; margin-top: 30px;">Historial Completo (Últimas 10)</h3>';
      historialHTML += '<table style="width: 100%; border-collapse: collapse; margin-top: 10px;">';
      historialHTML += '<tr style="background-color: #E3F2FD;">';
      historialHTML += '<th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Fecha</th>';
      historialHTML += '<th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Tipo</th>';
      historialHTML += '<th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Kilometraje</th>';
      historialHTML += '<th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Técnico</th>';
      historialHTML += '</tr>';

      for (var mant in mantenciones.take(10)) {
        historialHTML += '<tr>';
        historialHTML += '<td style="border: 1px solid #ddd; padding: 8px;">${DateFormat('dd/MM/yyyy').format(mant.fechaUltimoCambio)}</td>';
        historialHTML += '<td style="border: 1px solid #ddd; padding: 8px;">${mant.descripcionTipo}</td>';
        historialHTML += '<td style="border: 1px solid #ddd; padding: 8px;">${mant.kilometrajeUltimoCambio?.toStringAsFixed(0) ?? 'N/A'} km</td>';
        historialHTML += '<td style="border: 1px solid #ddd; padding: 8px;">${mant.tecnicoResponsable ?? 'No especificado'}</td>';
        historialHTML += '</tr>';
      }
      historialHTML += '</table>';
    } else {
      historialHTML = '<p style="color: #666; margin-top: 20px;"><em>No hay historial de mantenciones registrado.</em></p>';
    }

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Reporte de Máquina - ${bus.patente}</title>
  <style>
    @page {
      margin: 2cm;
    }
    body {
      font-family: Arial, sans-serif;
      line-height: 1.6;
      color: #333;
    }
    .header {
      text-align: center;
      border-bottom: 3px solid #1976D2;
      padding-bottom: 20px;
      margin-bottom: 30px;
    }
    .header h1 {
      color: #1976D2;
      margin: 0;
      font-size: 28px;
    }
    .header p {
      color: #666;
      margin: 5px 0;
    }
    .info-section {
      background-color: #f5f5f5;
      padding: 15px;
      border-radius: 8px;
      margin-bottom: 20px;
    }
    .info-row {
      display: flex;
      justify-content: space-between;
      padding: 8px 0;
      border-bottom: 1px solid #ddd;
    }
    .info-row:last-child {
      border-bottom: none;
    }
    .info-label {
      font-weight: bold;
      color: #1976D2;
    }
    .info-value {
      color: #333;
    }
    .alert-section {
      background-color: #FFF3E0;
      border-left: 4px solid #FF9800;
      padding: 15px;
      margin: 20px 0;
    }
    .footer {
      margin-top: 40px;
      text-align: center;
      color: #666;
      font-size: 12px;
      border-top: 1px solid #ddd;
      padding-top: 20px;
    }
    @media print {
      body {
        print-color-adjust: exact;
        -webkit-print-color-adjust: exact;
      }
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>🚌 Reporte de Máquina</h1>
    <p><strong>Sistema de Gestión de Buses - Suray</strong></p>
    <p>Periodo: $periodoTexto</p>
    <p>Generado: $fechaActual</p>
  </div>

  <h2 style="color: #1976D2;">Información de la Máquina</h2>
  <div class="info-section">
    <div class="info-row">
      <span class="info-label">Patente:</span>
      <span class="info-value">${bus.patente}</span>
    </div>
    <div class="info-row">
      <span class="info-label">N° de Máquina:</span>
      <span class="info-value">${bus.identificador ?? 'No asignado'}</span>
    </div>
    <div class="info-row">
      <span class="info-label">Marca/Modelo:</span>
      <span class="info-value">${bus.marca} ${bus.modelo} (${bus.anio})</span>
    </div>
    <div class="info-row">
      <span class="info-label">Estado:</span>
      <span class="info-value">${bus.estado.toString().split('.').last}</span>
    </div>
    <div class="info-row">
      <span class="info-label">Capacidad:</span>
      <span class="info-value">${bus.capacidadPasajeros} pasajeros</span>
    </div>
  </div>

  <h2 style="color: #1976D2;">Revisión Técnica</h2>
  <div class="info-section">
    <div class="info-row">
      <span class="info-label">Fecha de Vencimiento:</span>
      <span class="info-value">$revisionTecnicaFecha</span>
    </div>
    <div class="info-row">
      <span class="info-label">Estado:</span>
      <span class="info-value">$estadoRevision</span>
    </div>
  </div>

  <h2 style="color: #1976D2;">Kilometraje</h2>
  <div class="info-section">
    <div class="info-row">
      <span class="info-label">Kilometraje Actual:</span>
      <span class="info-value">$kmActual km</span>
    </div>
    <div class="info-row">
      <span class="info-label">Kilometraje desde Última Mantención:</span>
      <span class="info-value">$kmDesdeUltimaMant</span>
    </div>
    <div class="info-row">
      <span class="info-label">Kilometraje Ideal para Mantención:</span>
      <span class="info-value">$kmIdeal km</span>
    </div>
  </div>

  $historialHTML

  <div class="footer">
    <p><strong>Sistema de Gestión de Buses - Suray</strong></p>
    <p>Este reporte fue generado automáticamente. Para más información, contacte al administrador del sistema.</p>
  </div>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              SurayColors.azulMarinoProfundo,
              SurayColors.azulMarinoClaro,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SurayColors.naranjaQuemado,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.picture_as_pdf, color: Colors.white, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generar Reporte PDF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Busca una máquina y genera su reporte',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      content: Container(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Búsqueda
              Text(
                'Buscar Máquina',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: SurayColors.grisAntracita,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar por patente o N° de máquina (ej: 43, LSBT28)',
                        prefixIcon: Icon(Icons.search, color: SurayColors.azulMarinoProfundo),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: SurayColors.grisAntracitaClaro,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: SurayColors.azulMarinoProfundo,
                            width: 2,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _buscarMaquina(),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSearching ? null : _buscarMaquina,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SurayColors.azulMarinoProfundo,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSearching
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.search),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Resultados de búsqueda
              if (_busesEncontrados.isNotEmpty) ...[
                Text(
                  'Resultados (${_busesEncontrados.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SurayColors.grisAntracita,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  constraints: BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: SurayColors.grisAntracitaClaro),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _busesEncontrados.length,
                    itemBuilder: (context, index) {
                      final bus = _busesEncontrados[index];
                      final isSelected = _busSeleccionado?.id == bus.id;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: SurayColors.azulMarinoProfundo.withOpacity(0.1),
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? SurayColors.azulMarinoProfundo
                                : SurayColors.grisAntracita.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.directions_bus,
                            color: isSelected ? Colors.white : SurayColors.grisAntracita,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          bus.patente,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? SurayColors.azulMarinoProfundo : null,
                          ),
                        ),
                        subtitle: Text(
                          '${bus.identificador ?? 'Sin N°'} • ${bus.marca} ${bus.modelo}',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: SurayColors.azulMarinoProfundo)
                            : null,
                        onTap: () => setState(() => _busSeleccionado = bus),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
              ],

              // Tipo de reporte
              if (_busSeleccionado != null) ...[
                Text(
                  'Tipo de Reporte',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SurayColors.grisAntracita,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Diario', 'Semanal', 'Quincenal', 'Mensual'].map((tipo) {
                    final isSelected = _tipoReporte == tipo;
                    return ChoiceChip(
                      label: Text(tipo),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _tipoReporte = tipo);
                      },
                      selectedColor: SurayColors.azulMarinoProfundo,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : SurayColors.grisAntracita,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),

                // Información de la máquina seleccionada
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SurayColors.azulMarinoProfundo.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: SurayColors.azulMarinoProfundo.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                            color: SurayColors.azulMarinoProfundo,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Máquina seleccionada',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: SurayColors.azulMarinoProfundo,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${_busSeleccionado!.patente} • ${_busSeleccionado!.identificador ?? 'Sin N°'}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: SurayColors.grisAntracita,
                        ),
                      ),
                      Text(
                        '${_busSeleccionado!.marca} ${_busSeleccionado!.modelo} (${_busSeleccionado!.anio})',
                        style: TextStyle(
                          fontSize: 12,
                          color: SurayColors.grisAntracitaClaro,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(color: SurayColors.grisAntracita),
          ),
        ),
        ElevatedButton(
          onPressed: _busSeleccionado == null ? null : _generarReportePDF,
          style: ElevatedButton.styleFrom(
            backgroundColor: SurayColors.azulMarinoProfundo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.picture_as_pdf, size: 18),
              SizedBox(width: 8),
              Text('Generar PDF'),
            ],
          ),
        ),
      ],
    );
  }
}
