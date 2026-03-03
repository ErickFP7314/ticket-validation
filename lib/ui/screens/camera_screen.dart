import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/scanner_provider.dart';
import '../widgets/camera_overlay.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      // No iniciamos stream constante para ahorrar CPU y por pedido del usuario de botón manual
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  void _toggleFlash() {
    setState(() {
      _flashOn = !_flashOn;
      _controller?.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    });
  }

  Future<void> _scanCurrentFrame() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final provider = Provider.of<ScannerProvider>(context, listen: false);
    
    try {
      final image = await _controller!.takePicture();
      await provider.scanFromImage(image.path);
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final provider = Provider.of<ScannerProvider>(context, listen: false);
    await provider.scanFromImage(image.path);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<ScannerProvider>(
        builder: (context, provider, child) {
          Color backgroundColor = Colors.transparent;
          if (provider.status == ScanStatus.invalid) {
            backgroundColor = Colors.red.withOpacity(0.6);
          } else if (provider.status == ScanStatus.valid) {
            backgroundColor = Colors.green.withOpacity(0.4);
          } else if (provider.status == ScanStatus.scanning) {
            backgroundColor = Colors.blue.withOpacity(0.2);
          }

          return Stack(
            children: [
              Center(child: CameraPreview(_controller!)),
              
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: backgroundColor,
              ),

              const CameraOverlay(),

              if (provider.status == ScanStatus.scanning)
                const Center(child: CircularProgressIndicator(color: Colors.white)),

              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(provider),
                    const Spacer(),
                    if (provider.status == ScanStatus.invalid)
                      _buildInvalidAlert(provider),
                    if (provider.status == ScanStatus.valid)
                      _buildValidAlert(provider),
                    const Spacer(),
                    _buildBottomControls(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(ScannerProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.black54,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [10, 20, 50].map((den) {
          bool isSelected = provider.selectedDenomination == den;
          return ChoiceChip(
            label: Text("Bs $den", style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
            selected: isSelected,
            onSelected: (_) => provider.setDenomination(den),
            selectedColor: _getColorForDenomination(den),
            backgroundColor: Colors.grey[800],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInvalidAlert(ScannerProvider provider) {
    HapticFeedback.vibrate();
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 64),
          const SizedBox(height: 10),
          const Text("¡BILLETE INVÁLIDO!", 
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text("Serie detectada: ${provider.lastDetectedSerial}",
            style: const TextStyle(color: Colors.white70, fontSize: 18)),
          Text("Rango: ${provider.matchedRange?.rangeString}",
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => provider.clearResults(),
            child: const Text("ENTENDIDO / ESCANEAR OTRO"),
          )
        ],
      ),
    );
  }

  Widget _buildValidAlert(ScannerProvider provider) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 48),
          const SizedBox(height: 10),
          const Text("BILLETE VÁLIDO", 
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text("Serie: ${provider.lastDetectedSerial}", style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => provider.clearResults(),
            child: const Text("CERRAR", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.black54,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white, size: 30),
                onPressed: _toggleFlash,
              ),
              ElevatedButton.icon(
                onPressed: _scanCurrentFrame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.camera_alt),
                label: const Text("ESCANEAR AHORA", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.photo_library, color: Colors.white, size: 30),
                onPressed: _pickFromGallery,
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _showManualEntry,
            icon: const Icon(Icons.keyboard, color: Colors.white70),
            label: const Text("Introducir número manualmente", style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _showManualEntry() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Validación Manual"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Ingresa los 7 u 8 dígitos del número de serie."),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: "Número de Serie",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final provider = Provider.of<ScannerProvider>(this.context, listen: false);
                provider.validateManual(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text("VERIFICAR"),
          ),
        ],
      ),
    );
  }

  Color _getColorForDenomination(int den) {
    switch (den) {
      case 10: return Colors.blue[700]!;
      case 20: return Colors.orange[800]!;
      case 50: return Colors.purple[700]!;
      default: return Colors.blue;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
