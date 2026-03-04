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
  bool _hasProcessed = false;
  String? _errorMessage;

  ScanStatus get status => _status;
  int get selectedDenomination => _selectedDenomination;
  List<ScanResult> get results => _results;
  bool get isProcessing => _isProcessing;
  bool get hasProcessed => _hasProcessed;
  String? get errorMessage => _errorMessage;

  void setDenomination(int den) {
    _selectedDenomination = den;
    notifyListeners();
  }

  void clearResults() {
    _results = [];
    _status = ScanStatus.idle;
    _hasProcessed = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> scanFromImage(String path) async {
    _status = ScanStatus.scanning;
    _results = [];
    _hasProcessed = false;
    _errorMessage = null;
    notifyListeners();

    final inputImage = InputImage.fromFilePath(path);
    await processImage(inputImage);
  }

  void validateManual(String serialText) {
    _errorMessage = null;
    final trimmed = serialText.trim();
    
    // Intentamos validar con la lógica inteligente del validador
    final result = BanknoteValidator.validateSingle(_selectedDenomination, trimmed);
    
    if (result != null) {
      _results = [result];
      _hasProcessed = true;
      _updateStatusFromResults();
    } else {
      // Falló la validación, determinamos el motivo para el mensaje de error
      final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (digitsOnly.length < 7) {
        _errorMessage = "El código es demasiado corto. Debe tener al menos 7 dígitos.";
      } else if (digitsOnly.length > 9) {
        _errorMessage = "El código es demasiado largo. No debe exceder los 9 dígitos.";
      } else {
        _errorMessage = "Formato no reconocido. Ingrese solo los dígitos (se asumirá Serie B) "
            "o el número seguido de la serie (A o B).";
      }
      
      _results = [];
      _hasProcessed = false;
      _status = ScanStatus.idle;
    }
    
    notifyListeners();
  }

  Future<void> processImage(InputImage inputImage) async {
    if (_isProcessing) return;

    _isProcessing = true;
    _status = ScanStatus.scanning;
    _hasProcessed = false;
    notifyListeners();
    
    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Extraemos todos los resultados posibles del texto completo
      _results = BanknoteValidator.extractResults(_selectedDenomination, recognizedText.text);
      _hasProcessed = true;
      
      _updateStatusFromResults();
    } catch (e) {
      debugPrint("Error processing image: $e");
      _status = ScanStatus.idle;
      _hasProcessed = true;
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
