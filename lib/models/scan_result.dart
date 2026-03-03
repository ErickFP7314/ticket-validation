import 'banknote_range.dart';

class ScanResult {
  final String serialFull;
  final String serialDigits;
  final String seriesLetter;
  final bool isValid;
  final BanknoteRange? matchedRange;

  ScanResult({
    required this.serialFull,
    required this.serialDigits,
    required this.seriesLetter,
    required this.isValid,
    this.matchedRange,
  });

  @override
  String toString() {
    return 'ScanResult(serial: $serialFull, valid: $isValid)';
  }
}
