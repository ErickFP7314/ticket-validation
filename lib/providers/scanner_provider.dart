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
    
    // Quitamos espacios y limpiamos para la verificación de longitud
    final clean = serialText.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toUpperCase();
    
    // Primero intentamos validar con la lógica inteligente
    final result = BanknoteValidator.validateSingle(_selectedDenomination, clean);
    
    if (result != null) {
      _results = [result];
      _hasProcessed = true;
      _updateStatusFromResults();
    } else {
      // Si no es un patrón válido, damos un mensaje descriptivo
      if (clean.length < 7 || clean.length > 10) {
        _errorMessage = "El código debe contener entre 7 y 8 dígitos (se asumirá Serie B) "
            "o el formato completo (ej: 12345678 B).";
      } else {
        _errorMessage = "El formato del código no es válido. Asegúrate de ingresar 7-8 dígitos "
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
