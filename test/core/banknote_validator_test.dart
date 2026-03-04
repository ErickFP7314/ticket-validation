import 'package:flutter_test/flutter_test.dart';
import 'package:numero_serie_billetes_b/core/utils/banknote_validator.dart';
import 'package:numero_serie_billetes_b/models/scan_result.dart';

void main() {
  group('BanknoteValidator V2 Tests', () {
    test('Should extract multiple valid serials and letters', () {
      const text = "Detected: 77100005B and also 12345678A";
      final results = BanknoteValidator.extractResults(10, text);

      expect(results.length, 2);
      
      // First is Serie B (Invalid for 10Bs in that range)
      expect(results[0].serialDigits, "77100005");
      expect(results[0].seriesLetter, "B");
      expect(results[0].isValid, false);

      // Second is Serie A (Always valid)
      expect(results[1].serialDigits, "12345678");
      expect(results[1].seriesLetter, "A");
      expect(results[1].isValid, true);
    });

    test('Should handle optional space between digits and letter', () {
      const text = "77100005 B";
      final results = BanknoteValidator.extractResults(10, text);

      expect(results.length, 1);
      expect(results[0].seriesLetter, "B");
      expect(results[0].isValid, false);
    });

    test('Should ignore numbers without letters (anti-false positive)', () {
      const text = "Calendar 2024 or year 12345678";
      final results = BanknoteValidator.extractResults(10, text);

      expect(results.isEmpty, true);
    });

    test('Should handle 9 digits serials', () {
      const text = "104900005 B"; // Invalid range for 10Bs (104900001 - 105350000)
      final results = BanknoteValidator.extractResults(10, text);

      expect(results.length, 1);
      expect(results[0].serialDigits, "104900005");
      expect(results[0].isValid, false);
    });

    test('Should ignore any series other than A or B (strict filtering)', () {
      // Numbers with series other than A or B should be IGNORED
      const text = "77100005 C 12345678 T 06736385 G"; 
      final results = BanknoteValidator.extractResults(10, text);

      expect(results.length, 0); // Must be ignored now
    });

    test('Should still accept Serie A as valid even with strict filtering', () {
      const text = "12345678 A"; 
      final results = BanknoteValidator.extractResults(10, text);

      expect(results.length, 1);
      expect(results[0].seriesLetter, "A");
      expect(results[0].isValid, true);
    });
  });
}
