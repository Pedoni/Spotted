import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image/image.dart' as img;

/// Un PNG di un pixel trasparente.
final _transparentPixel = Uint8List.fromList(
  img.encodePng(img.Image(width: 1, height: 1, numChannels: 4)),
);

/// Un fornitore di riquadri che non scarica niente: nei test la mappa non deve
/// uscire in rete.
class EmptyTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_transparentPixel);
}
