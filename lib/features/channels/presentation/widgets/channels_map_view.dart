import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/empty_state.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/channels/domain/entities/channel_map_pin.dart';
import 'package:spotted/features/channels/presentation/providers/channels_feed.dart';
import 'package:spotted/features/channels/presentation/providers/channels_map_providers.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_map_pin_marker.dart';
import 'package:spotted/features/channels/presentation/widgets/municipality_channels_dialog.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// La mappa dei canali (la vista "Mappa" di Esplora): un pin per ogni comune
/// che ha canali, con gli stessi filtri dell'elenco. Un solo canale: il pin ha
/// la sua foto e un tocco lo apre. Più canali: il pin ha il numero e un tocco
/// apre l'elenco di quel comune. I canali senza città non compaiono.
class ChannelsMapView extends ConsumerStatefulWidget {
  const ChannelsMapView({super.key});

  /// L'Italia intera, finché non ci sono pin da inquadrare.
  static const italy = LatLng(42.5, 12.5);

  /// Il riquadro della mappa quando c'è un solo pin.
  static const singlePinZoom = 10.0;

  @override
  ConsumerState<ChannelsMapView> createState() => _ChannelsMapViewState();
}

class _ChannelsMapViewState extends ConsumerState<ChannelsMapView> {
  final _controller = MapController();

  /// I pin già inquadrati: si reinquadra solo quando cambiano.
  List<ChannelMapPin>? _framed;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Sposta la mappa in modo che si vedano tutti i pin.
  void _frame(List<ChannelMapPin> pins) {
    if (pins.isEmpty) return;
    final points = [for (final p in pins) LatLng(p.latitude, p.longitude)];
    if (points.length == 1) {
      _controller.move(points.single, ChannelsMapView.singlePinZoom);
      return;
    }
    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(72),
        maxZoom: 12,
      ),
    );
  }

  void _onPinTap(ChannelMapPin pin) {
    final channel = pin.channel;
    if (channel != null) {
      unawaited(context.push(AppRoutes.channelPath(channel.slug)));
    } else {
      unawaited(showMunicipalityChannelsDialog(context, pin));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final pins = ref.watch(channelsMapPinsProvider);
    final filter = ref.watch(channelFilterProvider);

    return pins.when(
      loading: () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Skeleton(
          child: SizedBox.expand(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: scheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
        ),
      ),
      error: (error, _) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(channelsMapPinsProvider),
      ),
      data: (pins) {
        if (pins.isEmpty) {
          return Center(
            child: EmptyState(
              icon: Icons.map_rounded,
              title: l10n.mapNoChannels,
              message: l10n.mapNoChannelsHint,
              action: filter.hasFilters
                  ? OutlinedButton(
                      onPressed: () => ref
                          .read(channelFilterProvider.notifier)
                          .clearFilters(),
                      child: Text(l10n.filtersReset),
                    )
                  : null,
            ),
          );
        }
        // Inquadra i pin la prima volta e ogni volta che cambiano (nuovi
        // filtri), senza togliere la mappa all'utente a ogni ricostruzione.
        if (_framed != pins) {
          _framed = pins;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _frame(pins);
          });
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: FlutterMap(
              mapController: _controller,
              options: const MapOptions(
                initialCenter: ChannelsMapView.italy,
                initialZoom: 5.2,
                minZoom: 4,
                maxZoom: 18,
                interactionOptions: InteractionOptions(
                  // Niente rotazione: la mappa resta con il nord in alto.
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.spotted',
                  tileProvider: ref.watch(mapTileProviderProvider),
                ),
                MarkerLayer(
                  markers: [
                    for (final pin in pins)
                      Marker(
                        point: LatLng(pin.latitude, pin.longitude),
                        width: ChannelMapPinMarker.size,
                        height: ChannelMapPinMarker.size,
                        child: ChannelMapPinMarker(
                          pin: pin,
                          onTap: () => _onPinTap(pin),
                        ),
                      ),
                  ],
                ),
                // I dati delle mappe sono di OpenStreetMap: la licenza chiede
                // di dirlo sempre. In basso a sinistra, per non stare sotto il
                // pulsante "Nuovo canale".
                const RichAttributionWidget(
                  alignment: AttributionAlignment.bottomLeft,
                  showFlutterMapAttribution: false,
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
