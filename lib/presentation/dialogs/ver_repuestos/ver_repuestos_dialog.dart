import 'package:flutter/material.dart';
import '../../../models/bus.dart';
import '../../../core/constants/breakpoints.dart';
import 'layouts/ver_repuestos_desktop_layout.dart';
import 'layouts/ver_repuestos_mobile_layout.dart';

/// Entry point para el diálogo de visualizar repuestos asignados
/// En desktop: AlertDialog con lista detallada y panel de detalles
/// En mobile: ModalBottomSheet fullscreen con scroll
class VerRepuestosDialog extends StatelessWidget {
  final Bus bus;
  final Function()? onRepuestoModificado;

  const VerRepuestosDialog({
    Key? key,
    required this.bus,
    this.onRepuestoModificado,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.tablet;

        if (isMobile) {
          return VerRepuestosMobileLayout(
            bus: bus,
            onRepuestoModificado: onRepuestoModificado,
          );
        } else {
          return VerRepuestosDesktopLayout(
            bus: bus,
            onRepuestoModificado: onRepuestoModificado,
          );
        }
      },
    );
  }

  /// Método estático para mostrar el diálogo
  static Future<bool?> show(
    BuildContext context, {
    required Bus bus,
    Function()? onRepuestoModificado,
  }) {
    final isMobile = MediaQuery.of(context).size.width < Breakpoints.tablet;

    if (isMobile) {
      return showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => VerRepuestosDialog(
          bus: bus,
          onRepuestoModificado: onRepuestoModificado,
        ),
      );
    } else {
      return showDialog<bool>(
        context: context,
        builder: (context) => VerRepuestosDialog(
          bus: bus,
          onRepuestoModificado: onRepuestoModificado,
        ),
      );
    }
  }
}
