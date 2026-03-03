import '../../constants/banknote_data.dart';
import '../../models/banknote_range.dart';

class BanknoteValidator {
  /// Limpia el texto detectado y devuelve solo los números.
  /// Ejemplos: 
  /// "00784500 B" -> "00784500"
  /// "SERIE 78450001B" -> "78450001"
  static String? cleanSerial(String text) {
    // Eliminar todo lo que no sea dígito
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Validar longitud mínima razonable (7 a 10 dígitos para Bolivia)
    if (clean.length < 7 || clean.length > 10) {
      return null;
    }
    return clean;
  }

  /// Verifica si un número de serie es inválido para una denominación dada.
  /// Devuelve el rango con el que coincide si es inválido, o null si es válido.
  static BanknoteRange? findInvalidRange(int denomination, String serialText) {
    final clean = cleanSerial(serialText);
    if (clean == null) return null;

    final serialNumber = int.tryParse(clean);
    if (serialNumber == null) return null;

    final ranges = banknoteData[denomination];
    if (ranges == null) return null;

    for (final range in ranges) {
      if (range.contains(serialNumber)) {
        return range;
      }
    }

    return null;
  }
}
