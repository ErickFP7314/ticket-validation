import 'package:flutter/material.dart';
import '../../providers/scanner_provider.dart';
import '../../models/scan_result.dart';

class ResultsPanel extends StatefulWidget {
  final ScannerProvider provider;

  const ResultsPanel({super.key, required this.provider});

  @override
  State<ResultsPanel> createState() => _ResultsPanelState();
}

class _ResultsPanelState extends State<ResultsPanel> {
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  bool _isClosing = false;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.provider.hasProcessed && widget.provider.status != ScanStatus.scanning) {
      return const SizedBox.shrink();
    }

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        // Lógica de "Snap to Close" (15% umbral)
        if (notification.extent < 0.15 && 
            !_isClosing && 
            _sheetController.isAttached && 
            widget.provider.status != ScanStatus.idle) {
          _isClosing = true;
          _sheetController.animateTo(
            0.0, 
            duration: const Duration(milliseconds: 300), 
            curve: Curves.easeOutCubic
          ).then((_) {
            widget.provider.clearResults();
            if (mounted) setState(() => _isClosing = false);
          });
        }
        return true;
      },
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: 0.9,
        minChildSize: 0.0,
        maxChildSize: 0.9,
        snap: true,
        snapSizes: const [0.0, 0.9],
        builder: (context, scrollController) {
          return AnimatedBuilder(
            animation: _sheetController,
            builder: (context, child) {
              // Si no está adjunto o el tamaño es muy pequeño al inicio, mostramos opacidad 1
              // para evitar que parpadee o se quede oculto.
              double opacity = 1.0;
              if (_sheetController.isAttached) {
                if (_isClosing) {
                  opacity = (_sheetController.size / 0.15).clamp(0.0, 1.0);
                }
              }
              
              return Container(
                decoration: BoxDecoration(
                  color: _getPanelColor(),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Opacity(
                  opacity: opacity,
                  child: CustomScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildHandle()),
                      SliverToBoxAdapter(child: _buildHeader()),
                      if (widget.provider.results.isEmpty && widget.provider.hasProcessed)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildNoResultsMessage(),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.only(bottom: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final result = widget.provider.results[index];
                                return _buildResultTile(result);
                              },
                              childCount: widget.provider.results.length,
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(child: _buildActionButtons()),
                      // Espacio extra al final para el teclado o scroll
                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNoResultsMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, color: Colors.white60, size: 80),
            const SizedBox(height: 20),
            const Text(
              "No se detectaron billetes",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "Verifica que el número de serie se vea con claridad, tenga buena luz y contenga su serie (A o B).",
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
    String prefix = "Se detectaron ";
    String statusLabel = "resultados";
    String suffix = " de billetes de ";
    IconData icon = Icons.info_outline;

    final hasResults = widget.provider.results.isNotEmpty;
    final int den = widget.provider.selectedDenomination;

    if (!hasResults && widget.provider.hasProcessed) {
      prefix = "No se detectó ";
      statusLabel = "ningún billete";
      icon = Icons.search_off;
    } else {
      switch (widget.provider.status) {
        case ScanStatus.valid:
          prefix = "Todos los billetes ";
          statusLabel = "son válidos";
          suffix = " de ";
          icon = Icons.check_circle;
          break;
        case ScanStatus.invalid:
          prefix = "Todos los billetes ";
          statusLabel = "son inválidos";
          suffix = " de ";
          icon = Icons.error;
          break;
        case ScanStatus.mixed:
          prefix = "Se detectaron ";
          statusLabel = "resultados mixtos";
          icon = Icons.warning;
          break;
        case ScanStatus.scanning:
          prefix = "Procesando ";
          statusLabel = "billetes";
          icon = Icons.refresh;
          break;
        default:
          break;
      }
    }

    final Color denColor = _getDenominationColor(den);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                children: [
                  TextSpan(text: prefix),
                  TextSpan(
                    text: statusLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: suffix),
                  TextSpan(
                    text: "$den BS",
                    style: TextStyle(
                      color: denColor, 
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      backgroundColor: Colors.black26
                    ),
                  ),
                  const TextSpan(text: "."),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDenominationColor(int den) {
    switch (den) {
      case 10: return Colors.blueAccent;
      case 20: return Colors.orangeAccent;
      case 50: return Colors.purpleAccent;
      default: return Colors.white;
    }
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
        onPressed: () => widget.provider.clearResults(),
        child: const Text("LIMPIAR / NUEVO ESCANEO"),
      ),
    );
  }

  Color _getPanelColor() {
    if (widget.provider.results.isEmpty && widget.provider.hasProcessed) {
      return Colors.blueGrey[900]!;
    }
    switch (widget.provider.status) {
      case ScanStatus.valid: return Colors.green[800]!;
      case ScanStatus.invalid: return Colors.red[800]!;
      case ScanStatus.mixed: return Colors.orange[800]!;
      case ScanStatus.scanning: return Colors.blueGrey[800]!;
      default: return Colors.grey[900]!;
    }
  }
}
