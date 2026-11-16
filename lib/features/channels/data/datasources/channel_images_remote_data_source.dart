import 'dart:typed_data';

import 'package:spotted/features/channels/domain/entities/channel_image_kind.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Il bucket pubblico con le immagini dei canali.
const channelImagesBucket = 'channel-images';

/// Carica e toglie le immagini dei canali nello storage di Supabase. I file
/// stanno in una cartella per canale (`<id>/avatar-<ms>.jpg`) e cambiano nome a
/// ogni caricamento, così la CDN non serve mai una versione vecchia.
class ChannelImagesRemoteDataSource {
  ChannelImagesRemoteDataSource(this._client, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final SupabaseClient _client;
  final DateTime Function() _now;

  StorageFileApi get _files => _client.storage.from(channelImagesBucket);

  /// Carica [bytes], collega il file al canale con l'RPC `set_channel_image` e
  /// toglie quello di prima. Se il collegamento fallisce cancella il file
  /// appena caricato, così non restano file orfani.
  Future<String> setImage({
    required String channelId,
    required ChannelImageKind kind,
    required Uint8List bytes,
  }) async {
    final path = '$channelId/${kind.name}-${_now().millisecondsSinceEpoch}.jpg';
    await _files.uploadBinary(
      path,
      bytes,
      // Il nome è unico: la copia in cache non diventa mai vecchia.
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        cacheControl: '31536000',
      ),
    );

    final Object? previous;
    try {
      previous = await _setPath(channelId, kind, path);
    } on Object {
      await _tryRemove([path]);
      rethrow;
    }
    if (previous is String) await _tryRemove([previous]);
    return path;
  }

  /// Toglie l'immagine dal canale (RPC `set_channel_image` con percorso nullo)
  /// e cancella il file.
  Future<void> removeImage({
    required String channelId,
    required ChannelImageKind kind,
  }) async {
    final previous = await _setPath(channelId, kind, null);
    if (previous is String) await _tryRemove([previous]);
  }

  /// Cancella dei file (quando si elimina un canale). Un errore non ferma
  /// niente: al peggio resta un file inutile.
  Future<void> deleteFiles(List<String> paths) => _tryRemove(paths);

  /// L'RPC restituisce il percorso precedente, o null.
  Future<Object?> _setPath(
    String channelId,
    ChannelImageKind kind,
    String? path,
  ) {
    return _client.rpc<Object?>(
      'set_channel_image',
      params: {
        'p_channel_id': channelId,
        'p_kind': kind.name,
        'p_path': path,
      },
    );
  }

  Future<void> _tryRemove(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _files.remove(paths);
    } on Object {
      // Non è grave: resta un file che nessuno vede.
    }
  }
}
