import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/widgets/squircle_avatar.dart';
import 'package:spotted/features/channels/domain/entities/channel_map_pin.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_map_pin_marker.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  const pisaChannel = MapChannel(
    id: 'c1',
    name: 'Spotted Pisa',
    slug: 'canale-1',
  );

  late FakeChannelsRepository repo;

  final pins = [
    // Un solo canale: il pin ha la sua foto.
    makePin('050026', channel: pisaChannel),
    // Tre canali: il pin ha il numero.
    makePin(
      '037006',
      label: 'Bologna (BO)',
      latitude: 44.4949,
      longitude: 11.3426,
      count: 3,
    ),
  ];

  final channels = [
    makeChannel(1, name: 'Spotted Pisa', municipalityId: '050026'),
    makeChannel(2, name: 'Spotted Bologna', municipalityId: '037006'),
    makeChannel(3, name: 'Bologna Sport', municipalityId: '037006'),
    makeChannel(4, name: 'Bologna Musica', municipalityId: '037006'),
  ];

  Future<void> openExplore(
    WidgetTester tester, {
    List<ChannelMapPin>? mapPins,
    Failure? mapError,
  }) async {
    repo = FakeChannelsRepository(channels: channels)
      ..pins = mapPins ?? pins
      ..mapError = mapError;
    await pumpApp(tester, channels: repo, screenSize: const Size(800, 1000));
    await tester.tap(find.byIcon(Icons.tag_rounded));
    await tester.pumpAndSettle();
  }

  Future<void> openMap(
    WidgetTester tester, {
    List<ChannelMapPin>? mapPins,
    Failure? mapError,
  }) async {
    await openExplore(tester, mapPins: mapPins, mapError: mapError);
    await tester.tap(find.text('Mappa'));
    await tester.pumpAndSettle();
  }

  group('l interruttore Lista / Mappa', () {
    testWidgets('si parte dalla lista, senza chiedere i pin', (tester) async {
      await openExplore(tester);

      expect(find.text('Lista'), findsOneWidget);
      expect(find.text('Mappa'), findsOneWidget);
      expect(find.byType(FlutterMap), findsNothing);
      expect(find.text('Spotted Pisa'), findsOneWidget);
      expect(repo.mapCalls, isEmpty);
    });

    testWidgets('Mappa mostra la mappa al posto dell elenco', (tester) async {
      await openMap(tester);

      expect(find.byType(FlutterMap), findsOneWidget);
      // L'elenco non c'è più.
      expect(find.text('Spotted Bologna'), findsNothing);
      expect(repo.mapCalls, hasLength(1));
    });

    testWidgets('Lista torna all elenco', (tester) async {
      await openMap(tester);

      await tester.tap(find.text('Lista'));
      await tester.pumpAndSettle();

      expect(find.byType(FlutterMap), findsNothing);
      expect(find.text('Spotted Pisa'), findsOneWidget);
    });

    testWidgets('la ricerca e il filtro restano visibili nella mappa', (
      tester,
    ) async {
      await openMap(tester);

      expect(find.byTooltip('Filtri'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('i pin', () {
    testWidgets('uno per ogni comune con canali', (tester) async {
      await openMap(tester);

      expect(find.byType(ChannelMapPinMarker), findsNWidgets(2));
    });

    testWidgets('un solo canale: il pin ha il suo nome, senza numero', (
      tester,
    ) async {
      await openMap(tester);

      expect(find.byTooltip('Spotted Pisa, Pisa (PI)'), findsOneWidget);
    });

    testWidgets('più canali: il pin ha il numero', (tester) async {
      await openMap(tester);

      expect(find.byTooltip('3 canali a Bologna (BO)'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('i pin hanno la forma degli avatar, non un cerchio', (
      tester,
    ) async {
      await openMap(tester);

      for (final marker in tester.widgetList<ChannelMapPinMarker>(
        find.byType(ChannelMapPinMarker),
      )) {
        final ring = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byWidget(marker),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final shape = (ring.decoration as ShapeDecoration).shape;
        expect(shape, isA<RoundedSuperellipseBorder>());
      }
      // Dentro, l'avatar è lo stesso quadrato arrotondato dei canali.
      expect(find.byType(SquircleAvatar), findsNWidgets(2));
    });

    testWidgets('toccando un pin con un solo canale si apre il canale', (
      tester,
    ) async {
      await openMap(tester);

      await tester.tap(find.byTooltip('Spotted Pisa, Pisa (PI)'));
      await tester.pumpAndSettle();

      // Siamo nella pagina del canale.
      expect(find.byType(FlutterMap), findsNothing);
      expect(find.text('Pubblica uno spot'), findsOneWidget);
    });

    testWidgets('toccando un pin con più canali si apre l elenco', (
      tester,
    ) async {
      await openMap(tester);

      await tester.tap(find.byTooltip('3 canali a Bologna (BO)'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Bologna (BO)'), findsOneWidget);
      expect(find.text('3 canali'), findsOneWidget);
      // Sono i canali di quel comune, non gli altri.
      expect(find.text('Spotted Bologna'), findsOneWidget);
      expect(find.text('Bologna Sport'), findsOneWidget);
      expect(find.text('Bologna Musica'), findsOneWidget);
      expect(find.text('Spotted Pisa'), findsNothing);
      expect(repo.listCalls.last.municipalityId, '037006');
    });

    testWidgets('dall elenco si apre un canale e la finestra si chiude', (
      tester,
    ) async {
      await openMap(tester);
      await tester.tap(find.byTooltip('3 canali a Bologna (BO)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bologna Sport'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Pubblica uno spot'), findsOneWidget);
    });

    testWidgets('la finestra si chiude con la x', (tester) async {
      await openMap(tester);
      await tester.tap(find.byTooltip('3 canali a Bologna (BO)'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Chiudi'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('l elenco del comune ha gli stessi filtri di Esplora', (
      tester,
    ) async {
      await openMap(tester);
      await tester.enterText(find.byType(TextField), 'sport');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('3 canali a Bologna (BO)'));
      await tester.pumpAndSettle();

      expect(repo.listCalls.last.query, 'sport');
      expect(find.text('Bologna Sport'), findsOneWidget);
      expect(find.text('Spotted Bologna'), findsNothing);
    });

    testWidgets('errore nell elenco del comune: Riprova', (tester) async {
      await openMap(tester);
      repo.listError = const NetworkFailure();
      await tester.tap(find.byTooltip('3 canali a Bologna (BO)'));
      await tester.pumpAndSettle();

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

      repo.listError = null;
      await tester.tap(find.text('Riprova'));
      await tester.pumpAndSettle();

      expect(find.text('Bologna Sport'), findsOneWidget);
    });
  });

  group('i filtri valgono anche per la mappa', () {
    testWidgets('il testo cercato si manda ai pin', (tester) async {
      await openMap(tester);

      await tester.enterText(find.byType(TextField), 'pisa');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(repo.mapCalls.last.query, 'pisa');
    });

    testWidgets('i filtri scelti si mandano ai pin', (tester) async {
      await openMap(tester);

      await tester.tap(find.byTooltip('Filtri'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Sport'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Applica'));
      await tester.pumpAndSettle();

      expect(repo.mapCalls.last.topicId, 't-sport');
    });

    testWidgets('cambiando filtri la mappa si aggiorna', (tester) async {
      await openMap(tester);
      expect(find.byType(ChannelMapPinMarker), findsNWidgets(2));

      repo.pins = [pins.first];
      await tester.enterText(find.byType(TextField), 'pisa');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(ChannelMapPinMarker), findsOneWidget);
    });

    testWidgets('il filtro scelto in Lista c è anche in Mappa', (tester) async {
      await openExplore(tester);
      await tester.enterText(find.byType(TextField), 'bologna');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mappa'));
      await tester.pumpAndSettle();

      expect(repo.mapCalls.last.query, 'bologna');
    });
  });

  group('stati', () {
    testWidgets('nessun canale sulla mappa: lo dice', (tester) async {
      await openMap(tester, mapPins: []);

      expect(find.byType(FlutterMap), findsNothing);
      expect(find.text('Nessun canale sulla mappa'), findsOneWidget);
      expect(find.textContaining('hanno una città'), findsOneWidget);
    });

    testWidgets('con un filtro attivo si può azzerare', (tester) async {
      await openMap(tester, mapPins: []);
      await tester.tap(find.byTooltip('Filtri'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Sport'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Applica'));
      await tester.pumpAndSettle();
      expect(find.text('Nessun canale sulla mappa'), findsOneWidget);

      repo.pins = pins;
      await tester.tap(find.widgetWithText(OutlinedButton, 'Azzera'));
      await tester.pumpAndSettle();

      expect(find.byType(ChannelMapPinMarker), findsNWidgets(2));
      expect(repo.mapCalls.last.topicId, isNull);
    });

    testWidgets('errore: messaggio e Riprova', (tester) async {
      await openMap(tester, mapError: const NetworkFailure());

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
      expect(find.byType(FlutterMap), findsNothing);

      repo.mapError = null;
      await tester.tap(find.text('Riprova'));
      await tester.pumpAndSettle();

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(ChannelMapPinMarker), findsNWidgets(2));
    });

    testWidgets('mostra da dove vengono i dati della mappa', (tester) async {
      await openMap(tester);

      // L'attribuzione di OpenStreetMap è sempre visibile (la licenza la
      // chiede).
      expect(find.byType(RichAttributionWidget), findsOneWidget);
    });
  });

  testWidgets('un solo pin: la mappa si sposta lì', (tester) async {
    await openMap(tester, mapPins: [pins.first]);

    final camera = tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .mapController!
        .camera;
    expect(camera.center.latitude, closeTo(43.7228, 0.01));
    expect(camera.center.longitude, closeTo(10.4017, 0.01));
    expect(camera.zoom, 10);
  });

  testWidgets('più pin: la mappa li inquadra tutti', (tester) async {
    await openMap(tester);

    final camera = tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .mapController!
        .camera;
    for (final pin in pins) {
      expect(
        camera.visibleBounds.contains(
          LatLng(pin.latitude, pin.longitude),
        ),
        isTrue,
      );
    }
  });
}
