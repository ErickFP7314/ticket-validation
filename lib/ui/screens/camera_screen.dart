import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/scanner_provider.dart';
import '../widgets/results_panel.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _flashOn = false;
  DateTime? _lastBackPress;

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final provider = Provider.of<ScannerProvider>(context, listen: false);
        
        // 1. Si hay resultados, cerramos el panel (como el botón Limpiar)
        if (provider.results.isNotEmpty || provider.hasProcessed) {
          provider.clearResults();
          return;
        }

        // 2. Lógica de doble toque para salir rápido
        final now = DateTime.now();
        if (_lastBackPress != null && now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
          return;
        }
        _lastBackPress = now;

        // 3. Si no es doble toque, confirmamos salida con modal
        final shouldExit = await _showExitConfirmation(context);
        if (shouldExit && mounted) {
           SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Consumer<ScannerProvider>(
          builder: (context, provider, child) {
            Color backgroundColor = Colors.transparent;
            if (provider.status == ScanStatus.invalid) {
              backgroundColor = Colors.red.withOpacity(0.4);
            } else if (provider.status == ScanStatus.valid) {
              backgroundColor = Colors.green.withOpacity(0.3);
            } else if (provider.status == ScanStatus.mixed) {
              backgroundColor = Colors.orange.withOpacity(0.3);
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

                if (provider.status == ScanStatus.scanning)
                  const Center(child: CircularProgressIndicator(color: Colors.white)),

                SafeArea(
                  child: Column(
                    children: [
                      _buildTopBar(provider),
                      const Spacer(),
                      _buildBottomControls(),
                    ],
                  ),
                ),

                // Usamos un Key basado en el estado de procesamiento para forzar 
                // que el widget se recree totalmente cuando empezamos un nuevo escaneo
                if (provider.status != ScanStatus.idle || provider.hasProcessed)
                  ResultsPanel(
                    key: ValueKey('results_${provider.hasProcessed}_${provider.results.length}_${provider.status}'),
                    provider: provider
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Salir de la aplicación?"),
        content: const Text("¿Estás seguro de que deseas cerrar el verificador?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("SALIR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
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
            onPressed: () => _showManualEntry(context),
            icon: const Icon(Icons.keyboard, color: Colors.white70),
            label: const Text("Introducir número manualmente", style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _showManualEntry(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ManualEntryDialog(),
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

class ManualEntryDialog extends StatefulWidget {
  const ManualEntryDialog({super.key});

  @override
  State<ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<ManualEntryDialog> {
  final _controller = TextEditingController();
  bool _isSeriesB = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final text = _controller.text.trim().toUpperCase();
      setState(() {
        // Asumimos Serie B si termina en B o si es puramente numérico
        _isSeriesB = text.endsWith('B') || (text.isNotEmpty && RegExp(r'^\d+$').hasMatch(text));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Validación Manual"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Ingresa el número de serie:"),
          const SizedBox(height: 4),
          const Text("(7-8 dígitos o con Serie A/B)", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              hintText: "Ej: 06736385",
              labelText: "Número de Serie",
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _isSeriesB ? Colors.blue : Colors.grey,
                  width: _isSeriesB ? 2 : 1,
                ),
              ),
              suffixIcon: _isSeriesB 
                ? const Icon(Icons.verified_user, color: Colors.blue) 
                : const Icon(Icons.keyboard),
              helperText: _isSeriesB 
                ? "Asumiendo Serie B (validando rangos)..." 
                : "Series A... son siempre válidas.",
              helperStyle: TextStyle(
                color: _isSeriesB ? Colors.blue : Colors.grey,
                fontWeight: _isSeriesB ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              final provider = Provider.of<ScannerProvider>(context, listen: false);
              provider.validateManual(_controller.text.trim());
              
              if (provider.errorMessage != null) {
                _showErrorDialog(context, provider.errorMessage!);
              } else {
                Navigator.pop(context);
              }
            }
          },
          child: const Text("VERIFICAR"),
        ),
      ],
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ingrese nuevamente", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar error
              final provider = Provider.of<ScannerProvider>(context, listen: false);
              provider.clearError();
            },
            child: const Text("REINTENTAR"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
