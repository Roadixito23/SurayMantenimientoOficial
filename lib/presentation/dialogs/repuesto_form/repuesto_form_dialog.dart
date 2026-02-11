import 'package:flutter/material.dart';
import '../../../models/repuesto.dart';
import '../../../core/constants/breakpoints.dart';
import 'layouts/repuesto_form_desktop_layout.dart';
import 'layouts/repuesto_form_mobile_layout.dart';

/// Entry point para el diálogo de formulario de repuesto
/// En desktop: AlertDialog tradicional
/// En mobile: ModalBottomSheet fullscreen con scroll vertical
class RepuestoFormDialog extends StatelessWidget {
  final RepuestoCatalogo? repuesto;

  const RepuestoFormDialog({Key? key, this.repuesto}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Usar MediaQuery para obtener el tamaño real de la pantalla
    // Breakpoints.mobile = 600px, consistente con ResponsiveHelper.isMobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < Breakpoints.mobile;

    if (isMobile) {
      return RepuestoFormMobileLayout(repuesto: repuesto);
    } else {
      return RepuestoFormDesktopLayout(repuesto: repuesto);
    }
  }

  /// Método estático para mostrar el diálogo
  static Future<bool?> show(BuildContext context, {RepuestoCatalogo? repuesto}) {
    final isMobile = MediaQuery.of(context).size.width < Breakpoints.mobile;

    if (isMobile) {
      return showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => RepuestoFormDialog(repuesto: repuesto),
      );
    } else {
      return showDialog<bool>(
        context: context,
        builder: (context) => RepuestoFormDialog(repuesto: repuesto),
      );
    }
  }
}
