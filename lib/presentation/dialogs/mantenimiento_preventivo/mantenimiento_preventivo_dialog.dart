import 'package:flutter/material.dart';
import '../../../models/bus.dart';
import '../../widgets/responsive/responsive_builder.dart';
import 'layouts/desktop_layout.dart';
import 'layouts/mobile_layout.dart';

/// Dialog responsive para registrar mantenimientos preventivos
/// Desktop: AlertDialog 700px con formulario completo
/// Mobile: BottomSheet con diseño vertical optimizado
class MantenimientoPreventivoDialog extends StatelessWidget {
  final Bus bus;
  final Function()? onMantenimientoRegistrado;

  const MantenimientoPreventivoDialog({
    Key? key,
    required this.bus,
    this.onMantenimientoRegistrado,
  }) : super(key: key);

  static Future<bool?> show(
    BuildContext context, {
    required Bus bus,
    Function()? onMantenimientoRegistrado,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MantenimientoPreventivoDialog(
        bus: bus,
        onMantenimientoRegistrado: onMantenimientoRegistrado,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => MantenimientoPreventivoMobileLayout(
        bus: bus,
        onMantenimientoRegistrado: onMantenimientoRegistrado,
      ),
      desktop: (_) => MantenimientoPreventivoDesktopLayout(
        bus: bus,
        onMantenimientoRegistrado: onMantenimientoRegistrado,
      ),
    );
  }
}
