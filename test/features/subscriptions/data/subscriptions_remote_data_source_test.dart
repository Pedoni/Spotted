import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/subscriptions/data/datasources/subscriptions_remote_data_source.dart';
import 'package:spotted/features/subscriptions/data/repositories/subscriptions_repository_impl.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  group('getInfo', () {
    test(
      'chiama l RPC con l id del canale e legge conteggio e stato',
      () async {
        final supabase = MockSupabase(
          (_) async => jsonResponse([
            {'subscriber_count': 12, 'is_subscribed': true},
          ]),
        );

        final info = await SubscriptionsRemoteDataSource(
          supabase.client,
        ).getInfo('c1');

        expect(info.subscriberCount, 12);
        expect(info.isSubscribed, isTrue);
        expect(supabase.lastRequest.method, 'POST');
        expect(
          supabase.lastRequest.url.path,
          '/rest/v1/rpc/channel_subscription_info',
        );
        expect(jsonDecode(supabase.lastRequest.body), {'p_channel_id': 'c1'});
      },
    );

    test('riga con tipi inattesi: UnknownFailure', () async {
      final supabase = MockSupabase(
        (_) async => jsonResponse([
          {'subscriber_count': 'molti', 'is_subscribed': true},
        ]),
      );
      final repository = SubscriptionsRepositoryImpl(
        SubscriptionsRemoteDataSource(supabase.client),
      );

      await expectLater(
        repository.getInfo('c1'),
        throwsA(isA<UnknownFailure>()),
      );
    });
  });

  group('subscribe e unsubscribe', () {
    test('subscribe chiama subscribe_to_channel', () async {
      final supabase = MockSupabase((_) async => http.Response('', 204));

      await SubscriptionsRemoteDataSource(supabase.client).subscribe('c1');

      expect(
        supabase.lastRequest.url.path,
        '/rest/v1/rpc/subscribe_to_channel',
      );
      expect(jsonDecode(supabase.lastRequest.body), {'p_channel_id': 'c1'});
    });

    test('unsubscribe chiama unsubscribe_from_channel', () async {
      final supabase = MockSupabase((_) async => http.Response('', 204));

      await SubscriptionsRemoteDataSource(supabase.client).unsubscribe('c1');

      expect(
        supabase.lastRequest.url.path,
        '/rest/v1/rpc/unsubscribe_from_channel',
      );
    });

    test('canale inesistente (23503): UnknownFailure', () async {
      final supabase = MockSupabase(
        (_) async => postgrestError(
          '23503',
          'violates foreign key constraint',
          status: 409,
        ),
      );
      final repository = SubscriptionsRepositoryImpl(
        SubscriptionsRemoteDataSource(supabase.client),
      );

      await expectLater(
        repository.subscribe('manca'),
        throwsA(isA<UnknownFailure>()),
      );
    });

    test(
      'utente non autenticato (permesso negato): PermissionFailure',
      () async {
        final supabase = MockSupabase(
          (_) async => postgrestError(
            '42501',
            'permission denied for function subscribe_to_channel',
            status: 403,
          ),
        );
        final repository = SubscriptionsRepositoryImpl(
          SubscriptionsRemoteDataSource(supabase.client),
        );

        await expectLater(
          repository.subscribe('c1'),
          throwsA(isA<PermissionFailure>()),
        );
      },
    );
  });

  test('getMySubscribedChannels legge i canali seguiti', () async {
    final supabase = MockSupabase(
      (_) async => jsonResponse([
        channelRow('1', name: 'Spotted Pisa'),
        channelRow('2', name: 'Spotted Roma'),
      ]),
    );

    final channels = await SubscriptionsRemoteDataSource(
      supabase.client,
    ).getMySubscribedChannels();

    expect(channels.map((c) => c.name), ['Spotted Pisa', 'Spotted Roma']);
    expect(
      supabase.lastRequest.url.path,
      '/rest/v1/rpc/my_subscribed_channels',
    );
  });
}
