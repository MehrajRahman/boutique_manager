import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class VisualSearchService {
  static final VisualSearchService instance = VisualSearchService._();
  VisualSearchService._();

  /// Generate an enhanced visual fingerprint from an image file.
  /// 128-dimensional: color histogram (24) + spatial color (48) +
  /// HSL histogram (24) + edge density (16) + texture (16).
  Future<List<double>> generateFingerprint(String imagePath) async {
    final file = File(imagePath);
    if (!file.existsSync()) return [];
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return [];

    // Work on 64x64 for speed
    final resized = img.copyResize(image, width: 64, height: 64);
    final fingerprint = <double>[];

    // ── 1. RGB Color histogram (24 values) ──
    final rHist = Float64List(8);
    final gHist = Float64List(8);
    final bHist = Float64List(8);
    final totalPixels = resized.width * resized.height;

    for (int y = 0; y < resized.height; y++) {
      for (int x = 0; x < resized.width; x++) {
        final pixel = resized.getPixel(x, y);
        rHist[pixel.r.toInt() >> 5] += 1;
        gHist[pixel.g.toInt() >> 5] += 1;
        bHist[pixel.b.toInt() >> 5] += 1;
      }
    }
    for (int i = 0; i < 8; i++) {
      fingerprint.add(rHist[i] / totalPixels);
      fingerprint.add(gHist[i] / totalPixels);
      fingerprint.add(bHist[i] / totalPixels);
    }

    // ── 2. Spatial color averages (4x4 grid × 3 channels = 48 values) ──
    final cellW = resized.width ~/ 4;
    final cellH = resized.height ~/ 4;
    for (int cy = 0; cy < 4; cy++) {
      for (int cx = 0; cx < 4; cx++) {
        double rSum = 0, gSum = 0, bSum = 0;
        int count = 0;
        for (int y = cy * cellH; y < (cy + 1) * cellH; y++) {
          for (int x = cx * cellW; x < (cx + 1) * cellW; x++) {
            final pixel = resized.getPixel(x, y);
            rSum += pixel.r.toInt();
            gSum += pixel.g.toInt();
            bSum += pixel.b.toInt();
            count++;
          }
        }
        fingerprint.add(rSum / count / 255.0);
        fingerprint.add(gSum / count / 255.0);
        fingerprint.add(bSum / count / 255.0);
      }
    }

    // ── 3. HSL histogram for better color perception (24 values: 12H + 6S + 6L) ──
    final hHist = Float64List(12);
    final sHist = Float64List(6);
    final lHist = Float64List(6);

    for (int y = 0; y < resized.height; y++) {
      for (int x = 0; x < resized.width; x++) {
        final pixel = resized.getPixel(x, y);
        final r = pixel.r.toInt() / 255.0;
        final g = pixel.g.toInt() / 255.0;
        final b = pixel.b.toInt() / 255.0;

        final maxC = [r, g, b].reduce(max);
        final minC = [r, g, b].reduce(min);
        final l = (maxC + minC) / 2;
        double s = 0;
        double h = 0;

        if (maxC != minC) {
          s = l > 0.5
              ? (maxC - minC) / (2 - maxC - minC)
              : (maxC - minC) / (maxC + minC);
          if (maxC == r) {
            h = ((g - b) / (maxC - minC)) % 6;
          } else if (maxC == g) {
            h = (b - r) / (maxC - minC) + 2;
          } else {
            h = (r - g) / (maxC - minC) + 4;
          }
          h = h / 6;
          if (h < 0) h += 1;
        }

        hHist[(h * 11.99).floor().clamp(0, 11)] += 1;
        sHist[(s * 5.99).floor().clamp(0, 5)] += 1;
        lHist[(l * 5.99).floor().clamp(0, 5)] += 1;
      }
    }
    for (int i = 0; i < 12; i++) {
      fingerprint.add(hHist[i] / totalPixels);
    }
    for (int i = 0; i < 6; i++) {
      fingerprint.add(sHist[i] / totalPixels);
    }
    for (int i = 0; i < 6; i++) {
      fingerprint.add(lHist[i] / totalPixels);
    }

    // ── 4. Edge density per 4x4 grid (16 values) ──
    // Convert to grayscale, compute simple gradient magnitude
    final gray = img.grayscale(img.Image.from(resized));

    for (int cy = 0; cy < 4; cy++) {
      for (int cx = 0; cx < 4; cx++) {
        double edgeSum = 0;
        int count = 0;
        for (int y = cy * cellH + 1; y < (cy + 1) * cellH - 1; y++) {
          for (int x = cx * cellW + 1; x < (cx + 1) * cellW - 1; x++) {
            final gx = gray.getPixel(x + 1, y).r.toInt() -
                gray.getPixel(x - 1, y).r.toInt();
            final gy = gray.getPixel(x, y + 1).r.toInt() -
                gray.getPixel(x, y - 1).r.toInt();
            edgeSum += sqrt(gx * gx + gy * gy) / 360.0; // normalize
            count++;
          }
        }
        fingerprint.add(count > 0 ? edgeSum / count : 0);
      }
    }

    // ── 5. Texture features: local contrast variance per 4x4 grid (16 values) ──
    for (int cy = 0; cy < 4; cy++) {
      for (int cx = 0; cx < 4; cx++) {
        final values = <double>[];
        for (int y = cy * cellH; y < (cy + 1) * cellH; y++) {
          for (int x = cx * cellW; x < (cx + 1) * cellW; x++) {
            values.add(gray.getPixel(x, y).r.toDouble());
          }
        }
        if (values.isEmpty) {
          fingerprint.add(0);
          continue;
        }
        final mean = values.reduce((a, b) => a + b) / values.length;
        final variance =
            values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
                values.length;
        fingerprint.add(sqrt(variance) / 128.0); // normalized std dev
      }
    }

    return fingerprint;
  }

  /// Compare two fingerprints using weighted cosine similarity.
  /// Different feature groups get different weights for better matching.
  double compareFingerprints(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;

    // If lengths differ (old 72-dim vs new 128-dim), use basic cosine
    if (a.length != b.length) {
      final minLen = min(a.length, b.length);
      return _cosineSimilarity(a.sublist(0, minLen), b.sublist(0, minLen));
    }

    if (a.length >= 128) {
      // Weighted similarity across feature groups
      final rgbSim = _cosineSimilarity(a.sublist(0, 24), b.sublist(0, 24));
      final spatialSim = _cosineSimilarity(a.sublist(24, 72), b.sublist(24, 72));
      final hslSim = _cosineSimilarity(a.sublist(72, 96), b.sublist(72, 96));
      final edgeSim = _cosineSimilarity(a.sublist(96, 112), b.sublist(96, 112));
      final textureSim = _cosineSimilarity(a.sublist(112, 128), b.sublist(112, 128));

      // HSL and spatial are most discriminative for product photos
      return rgbSim * 0.15 +
          spatialSim * 0.25 +
          hslSim * 0.30 +
          edgeSim * 0.15 +
          textureSim * 0.15;
    }

    return _cosineSimilarity(a, b);
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// Backward-compatible alias
  double compareFingerprintsCosine(List<double> a, List<double> b) =>
      compareFingerprints(a, b);

  /// Find similar products from a list of fingerprints.
  List<MapEntry<String, double>> findSimilar(
    List<double> queryFingerprint,
    Map<String, List<double>> productFingerprints, {
    double threshold = 0.6,
    int maxResults = 20,
  }) {
    final results = <MapEntry<String, double>>[];

    for (final entry in productFingerprints.entries) {
      final similarity = compareFingerprints(queryFingerprint, entry.value);
      if (similarity >= threshold) {
        results.add(MapEntry(entry.key, similarity));
      }
    }

    results.sort((a, b) => b.value.compareTo(a.value));
    return results.take(maxResults).toList();
  }
}
