import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../core/utils/banknote_validator.dart';
import '../models/banknote_range.dart';

enum ScanStatus { idle, scanning, valid, invalid }

class ScannerProvider with ChangeNotifier {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  
  ScanStatus _status = ScanStatus.idle;
  ScanStatus get status => _status;

  String? _lastDetectedSerial;
  String? get lastDetectedSerial => _lastDetectedSerial;

  BanknoteRange? _matchedRange;
  BanknoteRange? get matchedRange => _matchedRange;

  int _selectedDenomination = 10;
  int get selectedDenomination => _selectedDenomination;

  // Buffer de confianza: Mapa de <Serial, Cantidad de detecciones>
  final Map<String, int> _confidenceBuffer = {};
  static const int _requiredConfidence = 3;

  bool _isProcessing = false;

  void setDenomination(int value) {
    _selectedDenomination = value;
    clearResults();
    notifyListeners();
  }

  void clearResults() {
    _status = ScanStatus.idle;
    _lastDetectedSerial = null;
    _matchedRange = null;
    _confidenceBuffer.clear();
    notifyListeners();
  }

  Future<void> scanFromImage(String path) async {
    _status = ScanStatus.scanning;
    notifyListeners();

    final inputImage = InputImage.fromFilePath(path);
    await processImage(inputImage, isManualTrigger: true);
  }

  void validateManual(String serialText) {
    _lastDetectedSerial = serialText;
    _matchedRange = BanknoteValidator.findInvalidRange(_selectedDenomination, serialText);
    
    if (_matchedRange != null) {
      _status = ScanStatus.invalid;
    } else {
      _status = ScanStatus.valid;
    }
    notifyListeners();
  }

  Future<void> processImage(InputImage inputImage, {bool isManualTrigger = false}) async {
    if (_isProcessing || (_status == ScanStatus.invalid && !isManualTrigger)) return;

    _isProcessing = true;
    if (isManualTrigger) {
      _status = ScanStatus.scanning;
      notifyListeners();
    }
    
    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      String? foundSerial;
      
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final clean = BanknoteValidator.cleanSerial(line.text);
          if (clean != null) {
            foundSerial = clean;
            break;
          }
        }
        if (foundSerial != null) break;
      }

      if (foundSerial != null) {
        if (isManualTrigger) {
          // Si es manual, no requiere buffer de 3 frames
          validateManual(foundSerial);
        } else {
          _handleDetection(foundSerial);
        }
      } else if (isManualTrigger) {
        _status = ScanStatus.idle;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error processing image: $e");
      if (isManualTrigger) _status = ScanStatus.idle;
    } finally {
      _isProcessing = false;
    }
  }

  void _handleDetection(String serial) {
    _confidenceBuffer[serial] = (_confidenceBuffer[serial] ?? 0) + 1;

    if (_confidenceBuffer[serial]! >= _requiredConfidence) {
      validateManual(serial);
      _confidenceBuffer.clear();
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }
}
