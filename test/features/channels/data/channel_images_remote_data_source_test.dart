import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/channels/data/datasources/channel_images_remote_data_source.dart';
import 'package:spotted/features/channels/data/repositories/channel_images_repository_impl.dart';
import 'package:spotted/features/channels/domain/entities/channel_image_kind.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  final bytes = Uint8List.fromList([0xFF, 0xD8, 1, 2, 3]);
  final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  /// Risponde per ogni richiesta con [override] (se dà una risposta); di
  /// default l'upload e la rimozione vanno bene e l'RPC restituisce [previous]
  /// (il percorso di prima).
  MockSupabase mockWith({
    Object? previous,
    http.Response? Function(http.Request request)? override,
  }) {
    return MockSupabase((request) async {
      final custom = override?.call(request);
      if (custom != null) return custom;
      if (request.url.path.contains('/rpc/set_channel_image')) {
        return jsonResponse(previous);
      }
      if (request.method == 'DELETE') return jsonResponse(<Object>[]);
      return jsonResponse({'Key': 'channel-images/x'});
    });
  }

  ChannelImagesRemoteDataSource dataSourceFor(MockSupabase supabase) {
    return ChannelImagesRemoteDataSource(supabase.client, now: () => now);
  }

  Iterable<http.Request> requestsTo(MockSupabase supabase, String part) =>
      supabase.requests.where((r) => r.url.path.contains(part));

  group('setImage', () {
    test(
      'carica il file in una cartella per canale, con il nome nuovo',
      () async {
        final supabase = mockWith();

        final path = await dataSourceFor(supabase).setImage(
          channelId: 'c1',
          kind: ChannelImageKind.avatar,
          bytes: bytes,
        );

        expect(path, 'c1/avatar-1700000000000.jpg');
        final upload = supabase.requests.first;
        expect(upload.method, 'POST');
        expect(
          upload.url.path,
          '/storage/v1/object/channel-images/c1/avatar-1700000000000.jpg',
        );
        // Il file viaggia dentro una richiesta multipart.
        expect(latin1.decode(upload.bodyBytes), contains(latin1.decode(bytes)));
      },
    );

    test(
      'il file è un JPEG, con la cache lunga e senza sovrascrivere',
      () async {
        final supabase = mockWith();

        await dataSourceFor(supabase).setImage(
          channelId: 'c1',
          kind: ChannelImageKind.cover,
          bytes: bytes,
        );

        final upload = supabase.requests.first;
        final body = latin1.decode(upload.bodyBytes);
        expect(body, contains('image/jpeg'));
        expect(body, contains('31536000'));
        expect(upload.headers['x-upsert'], 'false');
      },
    );

    test('poi collega il percorso al canale con l RPC', () async {
      final supabase = mockWith();

      await dataSourceFor(supabase).setImage(
        channelId: 'c1',
        kind: ChannelImageKind.cover,
        bytes: bytes,
      );

      final rpc = requestsTo(supabase, '/rpc/set_channel_image').single;
      expect(jsonDecode(rpc.body), {
        'p_channel_id': 'c1',
        'p_kind': 'cover',
        'p_path': 'c1/cover-1700000000000.jpg',
      });
    });

    test('toglie il file di prima, se c era', () async {
      final supabase = mockWith(previous: 'c1/avatar-1600000000000.jpg');

      await dataSourceFor(supabase).setImage(
        channelId: 'c1',
        kind: ChannelImageKind.avatar,
        bytes: bytes,
      );

      final remove = supabase.requests
          .where((r) => r.method == 'DELETE')
          .single;
      expect(jsonDecode(remove.body), {
        'prefixes': ['c1/avatar-1600000000000.jpg'],
      });
    });

    test('senza un file di prima non cancella niente', () async {
      final supabase = mockWith();

      await dataSourceFor(supabase).setImage(
        channelId: 'c1',
        kind: ChannelImageKind.avatar,
        bytes: bytes,
      );

      expect(supabase.requests.where((r) => r.method == 'DELETE'), isEmpty);
    });

    test(
      'se il collegamento fallisce cancella il file appena caricato',
      () async {
        final supabase = mockWith(
          override: (request) => request.url.path.contains('/rpc/')
              ? postgrestError('42501', 'not the channel owner', status: 403)
              : null,
        );

        await expectLater(
          dataSourceFor(supabase).setImage(
            channelId: 'c1',
            kind: ChannelImageKind.avatar,
            bytes: bytes,
          ),
          throwsA(isA<Object>()),
        );

        final remove = supabase.requests
            .where((r) => r.method == 'DELETE')
            .single;
        expect(jsonDecode(remove.body), {
          'prefixes': ['c1/avatar-1700000000000.jpg'],
        });
      },
    );

    test('se non riesce a cancellare il file di prima non fallisce', () async {
      final supabase = mockWith(
        previous: 'c1/avatar-1.jpg',
        override: (request) =>
            request.method == 'DELETE' ? http.Response('boom', 500) : null,
      );

      final path = await dataSourceFor(supabase).setImage(
        channelId: 'c1',
        kind: ChannelImageKind.avatar,
        bytes: bytes,
      );

      expect(path, 'c1/avatar-1700000000000.jpg');
    });
  });

  group('removeImage', () {
    test(
      'chiama l RPC con il percorso nullo e cancella il file di prima',
      () async {
        final supabase = mockWith(previous: 'c1/cover-5.jpg');

        await dataSourceFor(supabase).removeImage(
          channelId: 'c1',
          kind: ChannelImageKind.cover,
        );

        final rpc = requestsTo(supabase, '/rpc/set_channel_image').single;
        expect(jsonDecode(rpc.body), {
          'p_channel_id': 'c1',
          'p_kind': 'cover',
          'p_path': null,
        });
        final remove = supabase.requests
            .where((r) => r.method == 'DELETE')
            .single;
        expect(jsonDecode(remove.body), {
          'prefixes': ['c1/cover-5.jpg'],
        });
      },
    );

    test('senza un file non cancella niente', () async {
      final supabase = mockWith();

      await dataSourceFor(supabase).removeImage(
        channelId: 'c1',
        kind: ChannelImageKind.avatar,
      );

      expect(supabase.requests.where((r) => r.method == 'DELETE'), isEmpty);
    });
  });

  group('deleteFiles', () {
    test('cancella tutti i file in una richiesta', () async {
      final supabase = mockWith();

      await dataSourceFor(supabase).deleteFiles(['c1/a.jpg', 'c1/b.jpg']);

      final remove = supabase.requests.single;
      expect(remove.method, 'DELETE');
      expect(jsonDecode(remove.body), {
        'prefixes': ['c1/a.jpg', 'c1/b.jpg'],
      });
    });

    test('senza file non chiama niente', () async {
      final supabase = mockWith();

      await dataSourceFor(supabase).deleteFiles([]);

      expect(supabase.requests, isEmpty);
    });

    test('un errore non si propaga', () async {
      final supabase = mockWith(override: (_) => http.Response('boom', 500));

      await dataSourceFor(supabase).deleteFiles(['c1/a.jpg']);
    });
  });

  group('errori attraverso il repository', () {
    ChannelImagesRepositoryImpl repositoryFor(MockSupabase supabase) {
      return ChannelImagesRepositoryImpl(dataSourceFor(supabase));
    }

    Future<void> upload(ChannelImagesRepositoryImpl repository) {
      return repository.setImage(
        channelId: 'c1',
        kind: ChannelImageKind.avatar,
        bytes: bytes,
      );
    }

    test('file troppo grande (413): ImageFailure tooLarge', () async {
      final repository = repositoryFor(
        MockSupabase(
          (_) async => jsonResponse({
            'statusCode': '413',
            'error': 'Payload too large',
            'message': 'The object exceeded the maximum allowed size',
          }, status: 413),
        ),
      );

      await expectLater(
        upload(repository),
        throwsA(
          const ImageFailure(
            ImageFailureReason.tooLarge,
            'The object exceeded the maximum allowed size',
          ),
        ),
      );
    });

    test('tipo non ammesso (415): ImageFailure invalid', () async {
      final repository = repositoryFor(
        MockSupabase(
          (_) async => jsonResponse({
            'statusCode': '415',
            'error': 'invalid_mime_type',
            'message': 'mime type not supported',
          }, status: 415),
        ),
      );

      await expectLater(
        upload(repository),
        throwsA(
          isA<ImageFailure>().having(
            (f) => f.reason,
            'reason',
            ImageFailureReason.invalid,
          ),
        ),
      );
    });

    test('regole dello storage (403): PermissionFailure', () async {
      final repository = repositoryFor(
        MockSupabase(
          (_) async => jsonResponse({
            'statusCode': '403',
            'error': 'Unauthorized',
            'message': 'new row violates row-level security policy',
          }, status: 403),
        ),
      );

      await expectLater(upload(repository), throwsA(isA<PermissionFailure>()));
    });

    test('non proprietario (42501) nell RPC: PermissionFailure', () async {
      final repository = repositoryFor(
        mockWith(
          override: (request) => request.url.path.contains('/rpc/')
              ? postgrestError('42501', 'not the channel owner', status: 403)
              : null,
        ),
      );

      await expectLater(upload(repository), throwsA(isA<PermissionFailure>()));
    });

    test('percorso non valido (23514) nell RPC: ValidationFailure', () async {
      final repository = repositoryFor(
        mockWith(
          override: (request) => request.url.path.contains('/rpc/')
              ? postgrestError('23514', 'invalid image path')
              : null,
        ),
      );

      await expectLater(upload(repository), throwsA(isA<ValidationFailure>()));
    });

    test('senza rete: NetworkFailure', () async {
      final repository = repositoryFor(
        MockSupabase((_) async => throw http.ClientException('no network')),
      );

      await expectLater(
        upload(repository),
        throwsA(isA<Failure>()),
      );
    });
  });
}
