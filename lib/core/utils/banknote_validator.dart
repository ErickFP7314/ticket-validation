import 'package:numero_serie_billetes_b/models/scan_result.dart';
import '../../constants/banknote_data.dart';
import '../../models/banknote_range.dart';

class BanknoteValidator {
  /// Extrae todos los números de serie válidos de un texto usando el patrón [8-9 dígitos] [Letra]
  static List<ScanResult> extractResults(int denomination, String text) {
    final List<ScanResult> results = [];
    final regex = RegExp(r'\b(\d{8,9})\s?([A-B])\b', caseSensitive: false);
    final matches = regex.allMatches(text);

    for (var match in matches) {
      final digits = match.group(1)!;
      final series = match.group(2)!.toUpperCase();
      
      // Filtro estricto: solo A y B
      if (series != 'A' && series != 'B') continue;

      final full = "$digits $series";

      final invalidRange = findInvalidRange(denomination, digits, series);
      
      results.add(ScanResult(
        serialFull: full,
        serialDigits: digits,
        seriesLetter: series,
        isValid: invalidRange == null,
        matchedRange: invalidRange,
      ));
    }

    return results;
  }

  /// Limpia un número de serie (solo dígitos) - Mantenido por compatibilidad
  static String? cleanSerial(String text) {
    // El nuevo flujo usa extractResults, pero dejamos esto para validaciones simples si se requiere
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length < 7 || clean.length > 10) return null;
    return clean;
  }

  /// Busca si el número está en un rango inválido, SOLO para Serie B
  static BanknoteRange? findInvalidRange(int denomination, String serialText, String series) {
    if (series != 'B') return null; // Solo la Serie B tiene restricciones

    final int? serialNum = int.tryParse(serialText);
    if (serialNum == null) return null;

    final ranges = banknoteData[denomination];
    if (ranges == null) return null;

    for (final range in ranges) {
      if (range.contains(serialNum)) {
        return range;
      }
    }

    return null;
  }
}
