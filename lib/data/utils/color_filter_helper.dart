import 'package:flutter/material.dart';

class ColorFilterHelper {
  static ColorFilter getAdjustmentFilter({
    required double brightness,
    required double contrast,
    required double saturation,
  }) {
    final bMatrix = _brightnessMatrix(brightness);
    final cMatrix = _contrastMatrix(contrast);
    final sMatrix = _saturationMatrix(saturation);

    // Combine matrices: first contrast, then saturation, then brightness
    final combined = _multiply(bMatrix, _multiply(sMatrix, cMatrix));
    return ColorFilter.matrix(combined);
  }

  static List<double> _brightnessMatrix(double brightness) {
    // brightness range is -1.0 to 1.0. Offset is from -255 to 255.
    final double offset = brightness * 255.0;
    return [
      1, 0, 0, 0, offset,
      0, 1, 0, 0, offset,
      0, 0, 1, 0, offset,
      0, 0, 0, 1, 0,
    ];
  }

  static List<double> _contrastMatrix(double contrast) {
    // contrast range is typically 0.5 to 2.0. Midpoint is 128.
    final double t = 128.0 * (1.0 - contrast);
    return [
      contrast, 0, 0, 0, t,
      0, contrast, 0, 0, t,
      0, 0, contrast, 0, t,
      0, 0, 0, 1, 0,
    ];
  }

  static List<double> _saturationMatrix(double saturation) {
    // saturation range is typicaly 0.0 to 2.0. 
    // Standard RGB luminance weights
    final double invSat = 1.0 - saturation;
    final double r = 0.2126 * invSat;
    final double g = 0.7152 * invSat;
    final double b = 0.0722 * invSat;
    return [
      r + saturation, g, b, 0, 0,
      r, g + saturation, b, 0, 0,
      r, g, b + saturation, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  static List<double> _multiply(List<double> a, List<double> b) {
    // Convert 20-element 4x5 matrices to 5x5 homogeneous matrices
    final m1 = List.generate(5, (_) => List.filled(5, 0.0));
    final m2 = List.generate(5, (_) => List.filled(5, 0.0));

    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 5; c++) {
        m1[r][c] = a[r * 5 + c];
        m2[r][c] = b[r * 5 + c];
      }
    }
    m1[4][4] = 1.0;
    m2[4][4] = 1.0;

    final result = List.generate(5, (_) => List.filled(5, 0.0));
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        double sum = 0.0;
        for (int k = 0; k < 5; k++) {
          sum += m1[r][k] * m2[k][c];
        }
        result[r][c] = sum;
      }
    }

    final List<double> finalMatrix = List.filled(20, 0.0);
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 5; c++) {
        finalMatrix[r * 5 + c] = result[r][c];
      }
    }
    return finalMatrix;
  }
}
