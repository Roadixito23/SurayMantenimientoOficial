import 'package:flutter/material.dart';
import '../../../models/bus.dart';
import '../../../core/constants/breakpoints.dart';
import 'layouts/asignar_repuesto_desktop_layout.dart';
import 'layouts/asignar_repuesto_mobile_layout.dart';

/// Entry point para el diálogo de asignar repuesto
/// En desktop: AlertDialog tradicional con 2 paneles
/// En mobile: ModalBottomSheet fullscreen con tabs
class AsignarRepuestoDialog extends StatelessWidget {
  final Bus bus;
  final Function()? onRepuestoAsignado;

  const AsignarRepuestoDialog({
    Key? key,
    required this.bus,
    this.onRepuestoAsignado,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.tablet;

        if (isMobile) {
          // En móvil: ModalBottomSheet fullscreen
          return AsignarRepuestoMobileLayout(
            bus: bus,
            onRepuestoAsignado: onRepuestoAsignado,
          );
        } else {
          // En desktop: AlertDialog tradicional
          return AsignarRepuestoDesktopLayout(
            bus: bus,
            onRepuestoAsignado: onRepuestoAsignado,
          );
        }
      },
    );
  }

  /// Método estático para mostrar el diálogo
  static Future<bool?> show(
    BuildContext context, {
    required Bus bus,
    Function()? onRepuestoAsignado,
  }) {
    final isMobile = MediaQuery.of(context).size.width < Breakpoints.tablet;

    if (isMobile) {
      return showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AsignarRepuestoDialog(
          bus: bus,
          onRepuestoAsignado: onRepuestoAsignado,
        ),
      );
    } else {
      return showDialog<bool>(
        context: context,
        builder: (context) => AsignarRepuestoDialog(
          bus: bus,
          onRepuestoAsignado: onRepuestoAsignado,
        ),
      );
    }
  }
}
