import 'package:intl/intl.dart';

class ChileanUtils {
  static final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  static final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'es_CL',
    symbol: '\$',
    decimalDigits: 0,
  );

  static String formatDate(DateTime date) => dateFormat.format(date);
  static String formatCurrency(int amount) => currencyFormat.format(amount);

  static bool isValidChileanPatente(String patente) {
    // Formato chileno: XX-YY-99 (2 letras, 2 letras, 2 números)
    final regex = RegExp(r'^[A-Z]{2}-[A-Z]{2}-\d{2}$');
    return regex.hasMatch(patente.toUpperCase());
  }

  static String formatPatente(String input) {
    String cleaned = input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (cleaned.length >= 6) {
      return '${cleaned.substring(0, 2)}-${cleaned.substring(2, 4)}-${cleaned.substring(4, 6)}';
    }
    return cleaned;
  }

  static String getEstadoBusLabel(String estado) {
    switch (estado) {
      case 'EstadoBus.disponible':
        return 'Disponible';
      case 'EstadoBus.enReparacion':
        return 'En Reparación';
      case 'EstadoBus.fueraDeServicio':
        return 'Fuera de Servicio';
      default:
        return 'Desconocido';
    }
  }
}