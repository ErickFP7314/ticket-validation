import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../core/utils/banknote_validator.dart';
import '../models/scan_result.dart';

enum ScanStatus { idle, scanning, valid, invalid, mixed }

class ScannerProvider with ChangeNotifier {
  final TextRecognizer _textRecognizer = TextRecognizer();
  
  ScanStatus _status = ScanStatus.idle;
  int _selectedDenomination = 10;
  List<ScanResult> _results = [];
  bool _isProcessing = false;

  ScanStatus get status => _status;
  int get selectedDenomination => _selectedDenomination;
  List<ScanResult> get results => _results;
  bool get isProcessing => _isProcessing;

  void setDenomination(int den) {
    _selectedDenomination = den;
    notifyListeners();
  }

  void clearResults() {
    _results = [];
    _status = ScanStatus.idle;
    notifyListeners();
  }

  Future<void> scanFromImage(String path) async {
    _status = ScanStatus.scanning;
    _results = [];
    notifyListeners();

    final inputImage = InputImage.fromFilePath(path);
    await processImage(inputImage);
  }

  void validateManual(String serialText) {
    // Para entrada manual, extraemos resultados del texto ingresado
    _results = BanknoteValidator.extractResults(_selectedDenomination, serialText);
    
    _updateStatusFromResults();
    notifyListeners();
  }

  Future<void> processImage(InputImage inputImage) async {
    if (_isProcessing) return;

    _isProcessing = true;
    _status = ScanStatus.scanning;
    notifyListeners();
    
    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Extraemos todos los resultados posibles del texto completo
      _results = BanknoteValidator.extractResults(_selectedDenomination, recognizedText.text);
      
      _updateStatusFromResults();
    } catch (e) {
      debugPrint("Error processing image: $e");
      _status = ScanStatus.idle;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void _updateStatusFromResults() {
    if (_results.isEmpty) {
      _status = ScanStatus.idle;
      return;
    }

    final hasInvalid = _results.any((r) => !r.isValid);
    final hasValid = _results.any((r) => r.isValid);

    if (hasInvalid && hasValid) {
      _status = ScanStatus.mixed;
    } else if (hasInvalid) {
      _status = ScanStatus.invalid;
    } else {
      _status = ScanStatus.valid;
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }
}
