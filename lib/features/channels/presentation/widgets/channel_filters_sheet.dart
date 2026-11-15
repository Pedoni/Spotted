import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/features/channels/presentation/providers/channels_feed.dart';
import 'package:spotted/features/municipalities/domain/entities/province.dart';
import 'package:spotted/features/municipalities/presentation/providers/municipalities_providers.dart';
import 'package:spotted/features/municipalities/presentation/widgets/municipality_field.dart';
import 'package:spotted/features/topics/presentation/providers/topics_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Apre il foglio dei filtri. Restituisce i filtri scelti (premendo
/// "Applica" o "Azzera"), o `null` se lo si chiude senza scegliere.
Future<ChannelFilterState?> showChannelFiltersSheet(
  BuildContext context,
  ChannelFilterState current,
) {
  return showModalBottomSheet<ChannelFilterState>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ChannelFiltersSheet(initial: current),
  );
}

String _provinceLabel(String name, String code) => '$name ($code)';

class _ChannelFiltersSheet extends ConsumerStatefulWidget {
  const _ChannelFiltersSheet({required this.initial});

  final ChannelFilterState initial;

  @override
  ConsumerState<_ChannelFiltersSheet> createState() =>
      _ChannelFiltersSheetState();
}

class _ChannelFiltersSheetState extends ConsumerState<_ChannelFiltersSheet> {
  late ChannelFilterState _draft = widget.initial;

  /// Cresce quando il comune viene tolto dall'esterno (cambiando regione o
  /// provincia): il campo ricomincia vuoto. Se cambiasse a ogni scelta
  /// dell'utente il campo perderebbe il testo mentre si scrive.
  int _municipalityEpoch = 0;

  void _setTopic(String? topicId) {
    setState(() {
      _draft = ChannelFilterState(
        topicId: topicId,
        regionName: _draft.regionName,
        provinceCode: _draft.provinceCode,
        provinceLabel: _draft.provinceLabel,
        municipality: _draft.municipality,
      );
    });
  }

  /// Cambiando regione provincia e comune non valgono più.
  void _setRegion(String? region) {
    if (region == _draft.regionName) return;
    setState(() {
      _draft = ChannelFilterState(topicId: _draft.topicId, regionName: region);
      _municipalityEpoch++;
    });
  }

  /// Scegliere una provincia porta con sé la sua regione; il comune resta solo
  /// se è di quella provincia.
  void _setProvince(Province? province) {
    if (province?.code == _draft.provinceCode) return;
    setState(() {
      _draft = ChannelFilterState(
        topicId: _draft.topicId,
        regionName: province?.regionName ?? _draft.regionName,
        provinceCode: province?.code,
        provinceLabel: province == null
            ? null
            : _provinceLabel(province.name, province.code),
      );
      _municipalityEpoch++;
    });
  }

  /// Scegliere un comune imposta anche la sua provincia e la sua regione.
  void _setMunicipality(MunicipalityChoice? choice) {
    setState(() {
      if (choice == null) {
        _draft = ChannelFilterState(
          topicId: _draft.topicId,
          regionName: _draft.regionName,
          provinceCode: _draft.provinceCode,
          provinceLabel: _draft.provinceLabel,
        );
        return;
      }
      final provinceCode = choice.provinceCode;
      _draft = ChannelFilterState(
        topicId: _draft.topicId,
        regionName: choice.regionName ?? _draft.regionName,
        provinceCode: provinceCode ?? _draft.provinceCode,
        provinceLabel: provinceCode == null
            ? _draft.provinceLabel
            : _provinceLabel(choice.provinceName ?? provinceCode, provinceCode),
        municipality: MunicipalityFilter(
          istatCode: choice.istatCode,
          label: choice.label,
        ),
      );
    });
  }

  void _reset() {
    setState(() {
      _draft = const ChannelFilterState();
      _municipalityEpoch++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final topics = ref.watch(topicsProvider).value ?? const [];
    final regions = ref.watch(regionsProvider);
    final provinces = ref.watch(provincesProvider(_draft.regionName));
    final provinceItems = provinces.value ?? const <Province>[];
    final regionItems = regions.value ?? const <String>[];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.filtersTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(l10n.filtersTopic, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.allTopics),
                  selected: _draft.topicId == null,
                  onSelected: (_) => _setTopic(null),
                ),
                for (final topic in topics)
                  ChoiceChip(
                    label: Text(topic.name),
                    selected: _draft.topicId == topic.id,
                    onSelected: (_) => _setTopic(topic.id),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(l10n.filtersPlace, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              key: ValueKey('region-${_draft.regionName}'),
              initialValue: regionItems.contains(_draft.regionName)
                  ? _draft.regionName
                  : null,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.filtersRegion),
              items: [
                DropdownMenuItem(child: Text(l10n.allRegions)),
                for (final region in regionItems)
                  DropdownMenuItem(value: region, child: Text(region)),
              ],
              onChanged: regions.hasValue ? _setRegion : null,
            ),
            if (regions.hasError)
              _LoadError(
                error: regions.error!,
                onRetry: () => ref.invalidate(regionsProvider),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              key: ValueKey(
                'province-${_draft.regionName}-${_draft.provinceCode}',
              ),
              initialValue:
                  provinceItems.any((p) => p.code == _draft.provinceCode)
                  ? _draft.provinceCode
                  : null,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.filtersProvince),
              items: [
                DropdownMenuItem(child: Text(l10n.allProvinces)),
                for (final province in provinceItems)
                  DropdownMenuItem(
                    value: province.code,
                    child: Text(_provinceLabel(province.name, province.code)),
                  ),
              ],
              onChanged: provinces.hasValue
                  ? (code) => _setProvince(
                      provinceItems.where((p) => p.code == code).firstOrNull,
                    )
                  : null,
            ),
            if (provinces.hasError)
              _LoadError(
                error: provinces.error!,
                onRetry: () =>
                    ref.invalidate(provincesProvider(_draft.regionName)),
              ),
            const SizedBox(height: 12),
            MunicipalityField(
              key: ValueKey('municipality-$_municipalityEpoch'),
              labelText: l10n.filtersMunicipality,
              initialValue: _draft.municipality == null
                  ? null
                  : MunicipalityChoice(
                      istatCode: _draft.municipality!.istatCode,
                      label: _draft.municipality!.label,
                    ),
              onChanged: _setMunicipality,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    child: Text(l10n.filtersReset),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_draft),
                    child: Text(l10n.filtersApply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(child: Text(failureMessage(l10n, error))),
        TextButton(onPressed: onRetry, child: Text(l10n.retry)),
      ],
    );
  }
}
