import 'package:flutter/material.dart';
import '../../providers/scanner_provider.dart';
import '../../models/scan_result.dart';

class ResultsPanel extends StatelessWidget {
  final ScannerProvider provider;

  const ResultsPanel({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.results.isEmpty && provider.status != ScanStatus.scanning) {
      return const SizedBox.shrink();
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.15,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: _getPanelColor(),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: provider.results.length,
                  itemBuilder: (context, index) {
                    final result = provider.results[index];
                    return _buildResultTile(result);
                  },
                ),
              ),
              _buildActionButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white38,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title = "RESULTADOS";
    IconData icon = Icons.info_outline;

    switch (provider.status) {
      case ScanStatus.valid:
        title = "TODOS VÁLIDOS";
        icon = Icons.check_circle;
        break;
      case ScanStatus.invalid:
        title = "TODOS INVÁLIDOS";
        icon = Icons.error;
        break;
      case ScanStatus.mixed:
        title = "RESULTADOS MIXTOS";
        icon = Icons.warning;
        break;
      case ScanStatus.scanning:
        title = "PROCESANDO...";
        icon = Icons.refresh;
        break;
      default:
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Text(title, 
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildResultTile(ScanResult result) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          result.isValid ? Icons.check_circle : Icons.cancel,
          color: result.isValid ? Colors.greenAccent : Colors.redAccent,
        ),
        title: Text(result.serialFull, 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(
          result.isValid 
            ? "Válido (Serie ${result.seriesLetter})" 
            : "INVÁLIDO: ${result.matchedRange?.rangeString}",
          style: TextStyle(color: result.isValid ? Colors.white70 : Colors.red[200]),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.2),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: () => provider.clearResults(),
        child: const Text("LIMPIAR / NUEVO ESCANEO"),
      ),
    );
  }

  Color _getPanelColor() {
    switch (provider.status) {
      case ScanStatus.valid: return Colors.green[800]!;
      case ScanStatus.invalid: return Colors.red[800]!;
      case ScanStatus.mixed: return Colors.orange[800]!;
      case ScanStatus.scanning: return Colors.blueGrey[800]!;
      default: return Colors.grey[900]!;
    }
  }
}
