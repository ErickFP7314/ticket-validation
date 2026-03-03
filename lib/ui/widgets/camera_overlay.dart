import 'package:flutter/material.dart';

class CameraOverlay extends StatelessWidget {
  const CameraOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        
        // El rectángulo de recorte estará al centro
        final double rectWidth = width * 0.85;
        final double rectHeight = 120;
        final double left = (width - rectWidth) / 2;
        final double top = (height - rectHeight) / 2.5; // Un poco más arriba del centro

        return Stack(
          children: [
            // Oscurecer el resto de la pantalla
            ColorFiltered(
              colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      width: rectWidth,
                      height: rectHeight,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Borde del rectángulo
            Positioned(
              left: left,
              top: top,
              child: Container(
                width: rectWidth,
                height: rectHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // Texto de instrucción
            Positioned(
              top: top - 40,
              width: width,
              child: const Center(
                child: Text(
                  "ALINEA EL NÚMERO DE SERIE AQUÍ",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Guía de ejemplo de billete (opcional)
            Positioned(
              top: top + rectHeight + 20,
              width: width,
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "Identificando billetes de la Serie B que han sido retirados.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
