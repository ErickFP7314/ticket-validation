import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/utils/banknote_validator.dart';

void main() {
  group('BanknoteValidator - Serie B Bolivia', () {
    test('Should detect invalid 10 Bs serial (within range)', () {
      final result = BanknoteValidator.findInvalidRange(10, '77100005 B');
      expect(result, isNotNull);
      expect(result!.from, 77100001);
    });

    test('Should detect valid 10 Bs serial (outside ranges)', () {
      final result = BanknoteValidator.findInvalidRange(10, '00000001 B');
      expect(result, isNull);
    });

    test('Should detect invalid 20 Bs serial (within range)', () {
      final result = BanknoteValidator.findInvalidRange(20, '87280150');
      expect(result, isNotNull);
      expect(result!.from, 87280145);
    });

    test('Should detect invalid 50 Bs serial (within range)', () {
      final result = BanknoteValidator.findInvalidRange(50, 'SERIE 76310020B');
      expect(result, isNotNull);
      expect(result!.from, 76310012);
    });

    test('Should clean text correctly', () {
      expect(BanknoteValidator.cleanSerial('00784500 B'), '00784500');
      expect(BanknoteValidator.cleanSerial('SERIE 123456789'), '123456789');
      expect(BanknoteValidator.cleanSerial('a1b2c3d4e5f6g7'), '1234567');
    });

    test('Should return null for invalid length', () {
      expect(BanknoteValidator.cleanSerial('123'), isNull);
      expect(BanknoteValidator.cleanSerial('12345678901'), isNull);
    });
  });
}
