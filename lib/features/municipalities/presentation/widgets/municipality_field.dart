import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/theme/app_shapes.dart';
import 'package:spotted/core/theme/app_theme.dart';
import 'package:spotted/features/municipalities/domain/entities/municipality.dart';
import 'package:spotted/features/municipalities/domain/usecases/search_municipalities.dart';
import 'package:spotted/features/municipalities/presentation/providers/municipalities_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Un comune scelto: il codice ISTAT e il testo da mostrare ("Pisa (PI)"),
/// con la provincia e la regione quando si sa da dove viene la scelta (i
/// filtri le usano per tenere coerente il luogo).
class MunicipalityChoice extends Equatable {
  const MunicipalityChoice({
    required this.istatCode,
    required this.label,
    this.provinceCode,
    this.provinceName,
    this.regionName,
  });

  factory MunicipalityChoice.fromMunicipality(Municipality municipality) {
    return MunicipalityChoice(
      istatCode: municipality.istatCode,
      label: municipality.label,
      provinceCode: municipality.provinceCode,
      provinceName: municipality.provinceName,
      regionName: municipality.regionName,
    );
  }

  final String istatCode;
  final String label;
  final String? provinceCode;
  final String? provinceName;
  final String? regionName;

  @override
  List<Object?> get props => [
    istatCode,
    label,
    provinceCode,
    provinceName,
    regionName,
  ];
}

/// Campo per scegliere un comune: si scrive il nome e compaiono i suggerimenti
/// dell'elenco ufficiale. Si può solo **scegliere** un suggerimento: un testo
/// scritto a mano e non scelto non è valido. È facoltativo (vuoto va bene) e si
/// può togliere con la "x".
///
/// [onChanged] riceve il comune scelto, o `null` quando si toglie o si
/// modifica il testo dopo averlo scelto.
class MunicipalityField extends ConsumerStatefulWidget {
  const MunicipalityField({
    required this.onChanged,
    this.initialValue,
    this.labelText,
    this.debounce = const Duration(milliseconds: 300),
    super.key,
  });

  final MunicipalityChoice? initialValue;
  final ValueChanged<MunicipalityChoice?> onChanged;

  /// Il testo del campo; di default "Comune (facoltativo)".
  final String? labelText;

  /// Quanto si aspetta, dopo l'ultima lettera scritta, prima di cercare.
  final Duration debounce;

  @override
  ConsumerState<MunicipalityField> createState() => _MunicipalityFieldState();
}

class _MunicipalityFieldState extends ConsumerState<MunicipalityField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue?.label,
  );
  final _focusNode = FocusNode();

  MunicipalityChoice? _selected;

  /// L'ultimo testo cercato: una risposta che arriva dopo che si è scritto
  /// altro non vale più.
  String _latestQuery = '';
  bool _noResults = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<Iterable<Municipality>> _options(TextEditingValue value) async {
    final query = value.text.trim();
    _latestQuery = query;

    // Il testo del comune già scelto ("Pisa (PI)") non si cerca di nuovo.
    if (_selected != null && value.text == _selected!.label) return const [];

    if (query.length < SearchMunicipalities.minQueryLength) {
      if (_noResults || _error != null) {
        setState(() {
          _noResults = false;
          _error = null;
        });
      }
      return const [];
    }

    // Aspetta che l'utente smetta di scrivere.
    await Future<void>.delayed(widget.debounce);
    if (!mounted || query != _latestQuery) return const [];

    try {
      final results = await ref.read(searchMunicipalitiesUseCaseProvider)(
        query,
      );
      if (!mounted || query != _latestQuery) return const [];
      setState(() {
        _noResults = results.isEmpty;
        _error = null;
      });
      return results;
    } on Exception catch (error) {
      if (mounted && query == _latestQuery) {
        setState(() {
          _noResults = false;
          _error = error;
        });
      }
      return const [];
    }
  }

  void _onSelected(Municipality municipality) {
    final choice = MunicipalityChoice.fromMunicipality(municipality);
    setState(() {
      _selected = choice;
      _noResults = false;
      _error = null;
    });
    widget.onChanged(choice);
  }

  void _onTextChanged(String text) {
    // Dopo aver scelto, modificare il testo annulla la scelta.
    if (_selected != null && text != _selected!.label) {
      setState(() => _selected = null);
      widget.onChanged(null);
    }
  }

  void _clear() {
    _controller.clear();
    final hadSelection = _selected != null;
    setState(() {
      _selected = null;
      _noResults = false;
      _error = null;
    });
    if (hadSelection) widget.onChanged(null);
  }

  String? _validate(String? text, AppLocalizations l10n) {
    final typed = text?.trim().isNotEmpty ?? false;
    // Vuoto va bene; scritto ma non scelto no.
    return typed && _selected == null ? l10n.municipalityChoose : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<Municipality>(
          textEditingController: _controller,
          focusNode: _focusNode,
          optionsBuilder: _options,
          displayStringForOption: (municipality) => municipality.label,
          onSelected: _onSelected,
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) => TextFormField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.next,
                onChanged: _onTextChanged,
                onFieldSubmitted: (_) => onSubmitted(),
                validator: (text) => _validate(text, l10n),
                decoration: InputDecoration(
                  labelText: widget.labelText ?? l10n.channelMunicipalityLabel,
                  hintText: l10n.municipalityHint,
                  helperText: _error != null
                      ? failureMessage(l10n, _error!)
                      : _noResults
                      ? l10n.municipalityNoResults
                      : null,
                  suffixIcon: value.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.clearMunicipality,
                          icon: const Icon(Icons.close),
                          onPressed: _clear,
                        ),
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return _Suggestions(
              width: constraints.maxWidth,
              options: options,
              onSelected: onSelected,
            );
          },
        );
      },
    );
  }
}

/// L'elenco dei suggerimenti sotto il campo.
class _Suggestions extends StatelessWidget {
  const _Suggestions({
    required this.width,
    required this.options,
    required this.onSelected,
  });

  final double width;
  final Iterable<Municipality> options;
  final ValueChanged<Municipality> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Material(
          color: AppTheme.raised(scheme),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: scheme.outlineVariant, width: 1.5),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width, maxHeight: 280),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final municipality = options.elementAt(index);
                return ListTile(
                  title: Text(municipality.name),
                  subtitle: Text(
                    '${municipality.provinceName} · ${municipality.regionName}',
                  ),
                  trailing: Text(
                    municipality.provinceCode,
                    style: theme.textTheme.labelLarge,
                  ),
                  onTap: () => onSelected(municipality),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
