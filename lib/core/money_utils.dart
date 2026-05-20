class MoneyUtils {
  static double parse(String value) {
    var texto = value.replaceAll('R\$', '').replaceAll(' ', '').trim();

    if (texto.isEmpty) return 0;

    if (texto.contains(',')) {
      texto = texto.replaceAll('.', '');
      texto = texto.replaceAll(',', '.');
    }

    return double.tryParse(texto) ?? 0;
  }

  static String format(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  static String formatCurrency(double value) {
    return 'R\$ ${format(value)}';
  }
}
