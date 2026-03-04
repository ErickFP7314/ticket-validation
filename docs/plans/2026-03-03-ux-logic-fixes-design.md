# Design Doc: UX and Logic Fixes

Address scanning feedback issues, ResultsPanel sizing and dismissal behavior, and OCR misreads for unsupported series.

## Proposed Changes

### Logic & Extraction

- **Strict Series Filtering**: Modify `BanknoteValidator.extractResults` to only include results with Series **A** or **B**. Any other letters from OCR misreads (e.g., 'T', 'G') will be ignored.
- **Enhanced Feedback**: Update `ScannerProvider` to differentiate between:
  - Scanning in progress.
  - Results found.
  - No results found (new `empty` status or empty results list with processed flag).

### UI/UX Improvements

- **ResultsPanel Sizing**: Set `initialChildSize` to `0.9` for a fixed, almost full-screen opening.
- **Dismissal Behavior (Snap-to-Close)**:
  - Implement a `15%` height threshold for automatic dismissal.
  - Use `DraggableScrollableController` to animate the closure when the threshold is reached.
  - Integrate `provider.clearResults()` into the closing animation callback to reset the UI only after the panel is hidden.
- **Overflow Fix**: Ensure vertical margins and scroll views prevent the "Bottom Overflowed" error during panel manipulation.
- **"No Results" State**:
  - If `results` is empty after a scan, show an informative message in the panel instead of just closing it or doing nothing.
  - Message: "No se detectaron billetes. Verifica que el número de serie se vea con claridad y tenga su serie (A o B)."

## Verification Plan

### Automated Tests

- Update `test/core/banknote_validator_test.dart` to verify that only Series A and B are extracted.

### Manual Verification

- **Panel Opening**: Scan an image and verify it covers 90% of the screen.
- **Panel Closing**: Drag the panel down below 15% and verify it slides down and clears the status.
- **Series Filter**: Scan (or enter manually) a number ending in 'T' and verify it is ignored.
- **No Results**: Scan a blank surface and verify the panel opens with the help message.
