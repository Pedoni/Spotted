import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/features/moderation/presentation/providers/moderation_providers.dart';
import 'package:spotted/features/moderation/presentation/widgets/spot_decision_flows.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/domain/entities/spot_status.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// "Rifiuta" e "Pubblica" in fondo al dettaglio di uno spot in attesa, solo per
/// il proprietario del canale: così si decide anche aprendo lo spot da una
/// chat, senza passare dalla pagina Moderazione. Per tutti gli altri, e per
/// gli spot già decisi, non c'è.
class SpotDecisionBar extends ConsumerWidget {
  const SpotDecisionBar({required this.spot, super.key});

  final Spot spot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (spot.status != SpotStatus.pending) return const SizedBox.shrink();
    final isOwner = ref.watch(isChannelOwnerProvider(spot.channelId)).value;
    if (isOwner != true) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => unawaited(rejectSpotFlow(context, ref, spot)),
                child: Text(l10n.rejectSpotAction),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => unawaited(approveSpotFlow(context, ref, spot)),
                child: Text(l10n.approveSpotAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
