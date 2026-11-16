import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/channels/domain/channel_image_processor.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/domain/entities/channel_image_kind.dart';
import 'package:spotted/features/channels/domain/repositories/channel_images_repository.dart';
import 'package:spotted/features/channels/presentation/services/channel_image_cropper.dart';
import 'package:spotted/features/channels/presentation/services/channel_image_picker.dart';

import 'fake_repositories.dart';

/// Immagini dei canali in memoria. Come il database, collega il percorso al
/// canale dei [channels] finti.
class FakeChannelImagesRepository implements ChannelImagesRepository {
  FakeChannelImagesRepository([this.channels]);

  final FakeChannelsRepository? channels;

  Failure? setError;
  Failure? removeError;

  /// Se è impostato, il caricamento aspetta che si completi.
  Completer<void>? gate;

  final setCalls =
      <({String channelId, ChannelImageKind kind, Uint8List bytes})>[];
  final removeCalls = <({String channelId, ChannelImageKind kind})>[];
  final deleteCalls = <List<String>>[];

  @override
  Future<String> setImage({
    required String channelId,
    required ChannelImageKind kind,
    required Uint8List bytes,
  }) async {
    setCalls.add((channelId: channelId, kind: kind, bytes: bytes));
    if (gate != null) await gate!.future;
    if (setError != null) throw setError!;
    final path = '$channelId/${kind.name}-${setCalls.length}.jpg';
    _setPath(channelId, kind, path);
    return path;
  }

  @override
  Future<void> removeImage({
    required String channelId,
    required ChannelImageKind kind,
  }) async {
    removeCalls.add((channelId: channelId, kind: kind));
    if (removeError != null) throw removeError!;
    _setPath(channelId, kind, null);
  }

  @override
  Future<void> deleteFiles(List<String> paths) async {
    deleteCalls.add(paths);
  }

  void _setPath(String channelId, ChannelImageKind kind, String? path) {
    final repo = channels;
    if (repo == null) return;
    Channel update(Channel c) => c.id != channelId
        ? c
        : Channel(
            id: c.id,
            name: c.name,
            slug: c.slug,
            description: c.description,
            place: c.place,
            municipalityId: c.municipalityId,
            provinceCode: c.provinceCode,
            regionName: c.regionName,
            topicId: c.topicId,
            avatarPath: kind == ChannelImageKind.avatar ? path : c.avatarPath,
            coverPath: kind == ChannelImageKind.cover ? path : c.coverPath,
            createdAt: c.createdAt,
          );
    repo
      ..channels = repo.channels.map(update).toList()
      ..mine = repo.mine.map(update).toList();
  }
}

/// Un selettore di foto finto: restituisce [bytes] (o `null`, o lancia
/// [error]).
class FakeChannelImagePicker implements ChannelImagePicker {
  FakeChannelImagePicker({this.bytes, this.error});

  Uint8List? bytes;
  Exception? error;
  final sources = <ChannelImageSource>[];

  @override
  Future<Uint8List?> pick(ChannelImageSource source) async {
    sources.add(source);
    if (error != null) throw error!;
    return bytes;
  }
}

/// Un ritaglio finto: restituisce [result] (o `null` se si rinuncia) senza
/// aprire nessuna pagina.
class FakeChannelImageCropper implements ChannelImageCropper {
  FakeChannelImageCropper({this.result});

  Uint8List? result;
  final calls = <({Uint8List source, ChannelImageKind kind})>[];

  @override
  Future<Uint8List?> crop(
    BuildContext context,
    Uint8List source,
    ChannelImageKind kind,
  ) async {
    calls.add((source: source, kind: kind));
    return result;
  }
}

/// Un processore finto: restituisce i byte uguali, o lancia [error].
class FakeChannelImageProcessor implements ChannelImageProcessor {
  Failure? error;
  final calls = <({Uint8List source, ChannelImageKind kind})>[];

  @override
  Future<Uint8List> prepare(Uint8List source, ChannelImageKind kind) async {
    calls.add((source: source, kind: kind));
    if (error != null) throw error!;
    return source;
  }
}
