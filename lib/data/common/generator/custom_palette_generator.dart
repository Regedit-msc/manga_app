import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Custom palette generator to replace the discontinued palette_generator package
class PaletteColor {
  final Color color;
  final int population;

  const PaletteColor(this.color, this.population);
}

class PaletteGenerator {
  final PaletteColor? dominantColor;
  final PaletteColor? vibrantColor;
  final PaletteColor? mutedColor;
  final PaletteColor? lightVibrantColor;
  final PaletteColor? darkVibrantColor;
  final PaletteColor? lightMutedColor;
  final PaletteColor? darkMutedColor;
  final List<PaletteColor> colors;

  const PaletteGenerator._({
    this.dominantColor,
    this.vibrantColor,
    this.mutedColor,
    this.lightVibrantColor,
    this.darkVibrantColor,
    this.lightMutedColor,
    this.darkMutedColor,
    this.colors = const [],
  });

  /// Generate palette from image provider
  static Future<PaletteGenerator> fromImageProvider(
    ImageProvider imageProvider, {
    Size? size,
    Rect? region,
    int maximumColorCount = 16,
  }) async {
    final image = await _getImageFromProvider(imageProvider);
    final imageColors = await _extractColors(image, maximumColorCount);

    return _generatePalette(imageColors);
  }

  /// Generate palette from list of colors
  static PaletteGenerator fromColors(List<Color> colors) {
    final paletteColors =
        colors.map((color) => PaletteColor(color, 1)).toList();
    return _generatePalette(paletteColors);
  }

  /// Get image from provider
  static Future<ui.Image> _getImageFromProvider(
      ImageProvider imageProvider) async {
    final completer = Completer<ui.Image>();
    final imageStream = imageProvider.resolve(const ImageConfiguration());

    late ImageStreamListener listener;
    listener = ImageStreamListener((imageInfo, _) {
      imageStream.removeListener(listener);
      completer.complete(imageInfo.image);
    });

    imageStream.addListener(listener);
    return completer.future;
  }

  /// Extract colors from image
  static Future<List<PaletteColor>> _extractColors(
      ui.Image image, int maxColors) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) return [];

    // Sample colors from the image
    final colorMap = <int, int>{};
    final width = decodedImage.width;
    final height = decodedImage.height;

    // Sample every nth pixel to avoid processing too many pixels
    final sampleRate = math.max(1, (width * height) ~/ 10000);

    for (int y = 0; y < height; y += sampleRate) {
      for (int x = 0; x < width; x += sampleRate) {
        final pixel = decodedImage.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final a = pixel.a.toInt();

        if (a > 125) {
          // Only consider non-transparent pixels
          final color = Color.fromARGB(255, r, g, b).value;
          colorMap[color] = (colorMap[color] ?? 0) + 1;
        }
      }
    }

    // Sort colors by popularity and return top colors
    final sortedColors = colorMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedColors
        .take(maxColors)
        .map((entry) => PaletteColor(Color(entry.key), entry.value))
        .toList();
  }

  /// Generate palette with different color types
  static PaletteGenerator _generatePalette(List<PaletteColor> colors) {
    if (colors.isEmpty) {
      return const PaletteGenerator._();
    }

    PaletteColor? dominantColor = colors.isNotEmpty ? colors.first : null;
    PaletteColor? vibrantColor;
    PaletteColor? mutedColor;
    PaletteColor? lightVibrantColor;
    PaletteColor? darkVibrantColor;
    PaletteColor? lightMutedColor;
    PaletteColor? darkMutedColor;

    for (final paletteColor in colors) {
      final hsl = HSLColor.fromColor(paletteColor.color);

      // Classify colors based on saturation and lightness
      if (hsl.saturation > 0.5) {
        // Vibrant colors
        if (hsl.lightness > 0.6) {
          lightVibrantColor ??= paletteColor;
        } else if (hsl.lightness < 0.4) {
          darkVibrantColor ??= paletteColor;
        } else {
          vibrantColor ??= paletteColor;
        }
      } else {
        // Muted colors
        if (hsl.lightness > 0.6) {
          lightMutedColor ??= paletteColor;
        } else if (hsl.lightness < 0.4) {
          darkMutedColor ??= paletteColor;
        } else {
          mutedColor ??= paletteColor;
        }
      }
    }

    return PaletteGenerator._(
      dominantColor: dominantColor,
      vibrantColor: vibrantColor,
      mutedColor: mutedColor,
      lightVibrantColor: lightVibrantColor,
      darkVibrantColor: darkVibrantColor,
      lightMutedColor: lightMutedColor,
      darkMutedColor: darkMutedColor,
      colors: colors,
    );
  }
}
