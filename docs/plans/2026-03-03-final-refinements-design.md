# Design Doc: Final Polishing & Production Refinements

Finalize UX behavior, navigation, and visual feedback for the banknote validation application.

## Proposed Changes

### UI/UX Refinements

- **Explicit Color-Coded Headers**:
  - Update `ResultsPanel` header to show: `SE DETECTARON RESULTADOS [ESTADO] DE BILLETES DE [MONTO] BS`.
  - Highlight the amount with specific colors:
    - **10 BS**: Blue (`Colors.blueAccent`)
    - **20 BS**: Orange (`Colors.orangeAccent`)
    - **50 BS**: Purple (`Colors.purpleAccent`)
- **Eliminate Overflow & Ghost Panel**:
  - Improve the `NotificationListener` logic to ensure the panel widget is completely unmounted or hidden when height reaches `0.0`.
- **Navigation Handling (Back Button)**:
  - Wrapped `CameraScreen` in `PopScope`.
  - **First Level**: If `results` is not empty, the back button calls `provider.clearResults()`.
  - **Second Level**: If `results` is empty, show a confirmation `AlertDialog`.
  - **Double-Back**: Implement a timer/counter to allow immediate exit if the back button is pressed twice within 2 seconds.

### Optimization

- **Code Quality**: Remove unused imports, streamline logic in `ScannerProvider`, and ensure efficient OCR processing.
- **Memory**: Ensure MLKit's `TextRecognizer` and `CameraController` are properly disposed and not leaking during repeated scans.

## Verification Plan

### Manual Verification

1.  **Title Verification**: Scan a 50 Bs note -> Header should say "... BILLETES DE 50 BS" with "50 BS" in Purple.
2.  **Back Button (Panel Open)**: Open results -> Press Back -> Panel should close and clear.
3.  **Back Button (Panel Closed)**: Press Back -> Confirmation modal should appear.
4.  **Double Back**: Press Back twice rapidly -> App should exit immediately.
5.  **Overflow Check**: Swipe panel down rapidly -> Verify no "Bottom Overflowed" message appears.
