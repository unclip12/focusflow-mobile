// =============================================================
// TextSanitizer — fixes double-encoded UTF-8 characters
// that got stored as Windows-1252 byte sequences.
// Cause: UTF-8 bytes (e.g. E2 80 A2 for •) were read as
// Windows-1252 and stored as those codepoints (â€¢).
// Usage: TextSanitizer.clean(yourString)
// =============================================================

class TextSanitizer {
  TextSanitizer._();

  /// Fixes common Windows-1252-over-UTF-8 garbled character sequences.
  /// Call this on any text coming from stored KB content/JSON.
  static String clean(String text) {
    if (text.isEmpty) return text;
    return text
        // Bullet: U+2022 • (UTF-8 E2 80 A2 → W1252 â€¢)
        .replaceAll('\u00e2\u20ac\u00a2', '\u2022')
        // Em dash: U+2014 — (UTF-8 E2 80 94 → W1252 â€")
        .replaceAll('\u00e2\u20ac\u201d', '\u2014')
        // En dash: U+2013 – (UTF-8 E2 80 93 → W1252 â€")
        .replaceAll('\u00e2\u20ac\u201c', '\u2013')
        // Right single quote: U+2019 ' (UTF-8 E2 80 99 → W1252 â€™)
        .replaceAll('\u00e2\u20ac\u2122', '\u2019')
        // Left single quote: U+2018 ' (UTF-8 E2 80 98 → W1252 â€˜)
        .replaceAll('\u00e2\u20ac\u02dc', '\u2018')
        // Left double quote: U+201C " (UTF-8 E2 80 9C → W1252 â€œ)
        .replaceAll('\u00e2\u20ac\u0153', '\u201c')
        // Ellipsis: U+2026 … (UTF-8 E2 80 A6 → W1252 â€¦)
        .replaceAll('\u00e2\u20ac\u00a6', '\u2026')
        // Check mark: U+2713 ✓ (UTF-8 E2 9C 93 → W1252 âœ")
        .replaceAll('\u00e2\u009c\u0093', '\u2713')
        // Non-breaking space: U+00A0 (UTF-8 C2 A0 → W1252 Â·)
        .replaceAll('\u00c2\u00a0', ' ')
        // Copyright: U+00A9 © (UTF-8 C2 A9)
        .replaceAll('\u00c3\u00a9', '\u00e9') // é
        .replaceAll('\u00c3\u00a8', '\u00e8') // è
        .replaceAll('\u00c3\u00a0', '\u00e0'); // à
  }
}
