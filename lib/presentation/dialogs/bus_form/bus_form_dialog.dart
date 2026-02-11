import 'package:flutter/material.dart';
import '../../../models/bus.dart';
import '../../../core/constants/breakpoints.dart';
import 'layouts/bus_form_desktop_layout.dart';
import 'layouts/bus_form_mobile_layout.dart';

/// Entry point para el diálogo de formulario de bus
/// En desktop: AlertDialog con 3 tabs
/// En mobile: ModalBottomSheet fullscreen con scroll vertical
class BusFormDialog extends StatelessWidget {
  final Bus? bus;

  const BusFormDialog({Key? key, this.bus}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Usar MediaQuery para obtener el tamaño real de la pantalla
    // Breakpoints.mobile = 600px, consistente con ResponsiveHelper.isMobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < Breakpoints.mobile;

    if (isMobile) {
      return BusFormMobileLayout(bus: bus);
    } else {
      return BusFormDesktopLayout(bus: bus);
    }
  }

  /// Método estático para mostrar el diálogo
  static Future<Bus?> show(BuildContext context, {Bus? bus}) {
    final isMobile = MediaQuery.of(context).size.width < Breakpoints.mobile;

    if (isMobile) {
      return showModalBottomSheet<Bus>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => BusFormDialog(bus: bus),
      );
    } else {
      return showDialog<Bus>(
        context: context,
        builder: (context) => BusFormDialog(bus: bus),
      );
    }
  }
}
