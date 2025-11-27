import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/bus.dart';
import '../services/data_service.dart';
import '../main.dart';

class ActualizarKilometrajeDialog extends StatefulWidget {
  final Bus bus;
  final VoidCallback onKilometrajeActualizado;

  const ActualizarKilometrajeDialog({
    Key? key,
    required this.bus,
    required this.onKilometrajeActualizado,
  }) : super(key: key);

  @override
  _ActualizarKilometrajeDialogState createState() => _ActualizarKilometrajeDialogState();
}

class _ActualizarKilometrajeDialogState extends State<ActualizarKilometrajeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _kilometrajeController = TextEditingController();
  final _observacionesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inicializar con el kilometraje actual del bus
    if (widget.bus.kilometraje != null) {
      _kilometrajeController.text = widget.bus.kilometraje!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _kilometrajeController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _actualizarKilometraje() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nuevoKilometraje = double.parse(_kilometrajeController.text);

      // Actualizar solo el kilometraje del bus
      final busActualizado = widget.bus.copyWith(
        kilometraje: nuevoKilometraje,
        ultimaActualizacionKm: DateTime.now(),
      );

      await DataService.updateBus(busActualizado);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kilometraje actualizado exitosamente a ${nuevoKilometraje.toStringAsFixed(0)} km',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: Duration(seconds: 3),
          ),
        );

        widget.onKilometrajeActualizado();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error al actualizar kilometraje: ${e.toString()}',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
              child: Icon(Icons.speed, color: Colors.white, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actualizar Kilometraje',
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
          ],
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información actual
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SurayColors.azulMarinoProfundo.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: SurayColors.azulMarinoProfundo.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                      color: SurayColors.azulMarinoProfundo,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kilometraje actual',
                            style: TextStyle(
                              fontSize: 12,
                              color: SurayColors.grisAntracitaClaro,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${widget.bus.kilometraje?.toStringAsFixed(0) ?? "No registrado"} km',
                            style: TextStyle(
                              fontSize: 16,
                              color: SurayColors.azulMarinoProfundo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.bus.ultimaActualizacionKm != null)
                            Text(
                              'Última actualización: ${widget.bus.ultimaActualizacionKm!.toString().substring(0, 16)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: SurayColors.grisAntracitaClaro,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Campo de nuevo kilometraje
              Text(
                'Nuevo Kilometraje',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: SurayColors.grisAntracita,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _kilometrajeController,
                decoration: InputDecoration(
                  hintText: 'Ejemplo: 125000',
                  suffixText: 'km',
                  prefixIcon: Icon(Icons.speed, color: SurayColors.azulMarinoProfundo),
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
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el kilometraje';
                  }
                  final km = double.tryParse(value);
                  if (km == null) {
                    return 'Ingrese un valor numérico válido';
                  }
                  if (km < 0) {
                    return 'El kilometraje no puede ser negativo';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Campo de observaciones (opcional)
              Text(
                'Observaciones (opcional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: SurayColors.grisAntracita,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _observacionesController,
                decoration: InputDecoration(
                  hintText: 'Notas adicionales sobre la actualización...',
                  prefixIcon: Icon(Icons.notes, color: SurayColors.azulMarinoProfundo),
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
                maxLines: 2,
              ),

              SizedBox(height: 16),

              // Nota importante
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SurayColors.naranjaQuemado.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: SurayColors.naranjaQuemado.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline,
                      color: SurayColors.naranjaQuemado,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta acción solo actualiza el kilometraje del bus. Para registrar una mantención, usa el botón "Registrar Mantenimiento".',
                        style: TextStyle(
                          fontSize: 12,
                          color: SurayColors.naranjaQuemado,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: SurayColors.grisAntracita,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _actualizarKilometraje,
          style: ElevatedButton.styleFrom(
            backgroundColor: SurayColors.azulMarinoProfundo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 18),
                    SizedBox(width: 8),
                    Text('Actualizar'),
                  ],
                ),
        ),
      ],
    );
  }
}
