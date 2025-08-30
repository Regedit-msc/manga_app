// @github.com jelenalecic Thanks!
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as imageLib;
import 'package:webcomic/data/common/generator/custom_palette_generator.dart';

const String keyPalette = 'palette';
const String keyNoOfItems = 'noIfItems';

int noOfPixelsPerAxis = 12;

Color getAverageColor(List<Color> colors) {
  int r = 0, g = 0, b = 0;

  for (int i = 0; i < colors.length; i++) {
    r += colors[i].red;
    g += colors[i].green;
    b += colors[i].blue;
  }

  r = r ~/ colors.length;
  g = g ~/ colors.length;
  b = b ~/ colors.length;

  return Color.fromRGBO(r, g, b, 1);
}

Color abgrToColor(int argbColor) {
  int r = (argbColor >> 16) & 0xFF;
  int b = argbColor & 0xFF;
  int hex = (argbColor & 0xFF00FF00) | (b << 16) | r;
  return Color(hex);
}

List<Color> sortColors(List<Color> colors) {
  List<Color> sorted = [];

  sorted.addAll(colors);
  sorted.sort((a, b) => b.computeLuminance().compareTo(a.computeLuminance()));

  return sorted;
}

List<Color> generatePalette(Map<String, dynamic> params) {
  List<Color> colors = [];
  List<Color> palette = [];

  colors.addAll(sortColors(params[keyPalette]));

  int noOfItems = params[keyNoOfItems];

  if (noOfItems <= colors.length) {
    int chunkSize = colors.length ~/ noOfItems;

    for (int i = 0; i < noOfItems; i++) {
      palette.add(
          getAverageColor(colors.sublist(i * chunkSize, (i + 1) * chunkSize)));
    }
  }

  return palette;
}

List<Color> extractPixelsColors(Uint8List? bytes) {
  List<Color> colors = [];

  Uint8List values = bytes!.buffer.asUint8List();
  imageLib.Image? image = imageLib.decodeImage(values);

  List<imageLib.Pixel?> pixels = [];

  int? width = image?.width;
  int? height = image?.height;

  int xChunk = width! ~/ (noOfPixelsPerAxis + 1);
  int yChunk = height! ~/ (noOfPixelsPerAxis + 1);

  for (int j = 1; j < noOfPixelsPerAxis + 1; j++) {
    for (int i = 1; i < noOfPixelsPerAxis + 1; i++) {
      imageLib.Pixel? pixel = image?.getPixel(xChunk * i, yChunk * j);
      pixels.add(pixel);
      colors.add(abgrToColor(pixel! as int));
    }
  }

  return colors;
}

Future<List<Color>> extractColors(String photo) async {
  List<Color> colors = [];
  List<Color> palette = [];

  Color primary = Colors.blueGrey;
  Color primaryText = Colors.black;
  Color background = Colors.white;
  Random random = Random();
  Uint8List? imageBytes;
  int noOfPaletteColors = 4;
  noOfPaletteColors = random.nextInt(4) + 2;

  imageBytes = (await NetworkAssetBundle(Uri.parse(photo)).load(photo))
      .buffer
      .asUint8List();

  colors = await compute(extractPixelsColors, imageBytes);
  // sortedColors = await compute(sortColors, colors);
  palette = await compute(
      generatePalette, {keyPalette: colors, keyNoOfItems: noOfPaletteColors});
  primary = palette.last;
  primaryText = palette.first;
  background = palette.first.withOpacity(0.5);
  return [primaryText, primary, background];
}

/// Flutter pallette
// Simple in-memory cache to avoid recomputing palettes on rebuilds
final Map<String, PaletteGenerator> _paletteCache = {};
Future<PaletteGenerator> getPalette(String imageUrl) async {
  if (_paletteCache.containsKey(imageUrl)) {
    return _paletteCache[imageUrl]!;
  }
  final paletteGenerator = await PaletteGenerator.fromImageProvider(
    Image.network(imageUrl).image,
  );
  _paletteCache[imageUrl] = paletteGenerator;
  return paletteGenerator;
}

/// Generate colors for info
class GeneratedImageBytesAndColor {
  final PaletteGenerator palette;
  final ImageProvider image;
  final Uint8List imageBytes;
  GeneratedImageBytesAndColor(
      {required this.palette, required this.imageBytes, required this.image});
}

Future<GeneratedImageBytesAndColor> getImageAndColors(String imageUrl) async {
  Uint8List imageBytes =
      (await NetworkAssetBundle(Uri.parse(imageUrl)).load(imageUrl))
          .buffer
          .asUint8List();
  ImageProvider image = Image.memory(imageBytes).image;
  final paletteGenerator = await PaletteGenerator.fromImageProvider(
    image,
  );
  _paletteCache[imageUrl] = paletteGenerator;
  return GeneratedImageBytesAndColor(
      palette: paletteGenerator, imageBytes: imageBytes, image: image);
}

class ImageProviderWithImageBytes {
  ImageProvider? imageProvider;
  Uint8List? imageBytes;
  ImageProviderWithImageBytes({this.imageBytes, this.imageProvider});
}

// Simple image bytes cache to reduce repeat decodes during fast rebuilds
final Map<String, ImageProviderWithImageBytes> _imageDataCache = {};
Future<ImageProviderWithImageBytes> getImageData({required String url}) async {
  if (_imageDataCache.containsKey(url)) {
    return _imageDataCache[url]!;
  }
  try {
    Uint8List imageBytes = (await NetworkAssetBundle(Uri.parse(url)).load(url))
        .buffer
        .asUint8List();
    ImageProvider image = Image.memory(imageBytes).image;
    final data = ImageProviderWithImageBytes(
        imageBytes: imageBytes, imageProvider: image);
    _imageDataCache[url] = data;
    return data;
  } catch (e) {
    return ImageProviderWithImageBytes();
  }
}
