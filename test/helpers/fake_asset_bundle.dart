import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Un contenitore di risorse finto: restituisce i testi che gli si danno e
/// risponde subito, senza leggere dal disco (che nei test non avanza con il
/// tempo finto).
class FakeAssetBundle extends CachingAssetBundle {
  FakeAssetBundle(this.texts);

  final Map<String, String> texts;

  @override
  Future<ByteData> load(String key) async {
    final text = texts[key];
    if (text == null) throw FlutterError('Risorsa non trovata: $key');
    final bytes = Uint8List.fromList(utf8.encode(text));
    return ByteData.sublistView(bytes);
  }
}
