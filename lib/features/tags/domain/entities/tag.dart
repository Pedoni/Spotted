import 'package:equatable/equatable.dart';

/// Un tag di uno spot, scelto dal proprietario del canale in un elenco fisso.
class Tag extends Equatable {
  const Tag({required this.slug, required this.label, required this.category});

  /// Nome tecnico: minuscolo, senza spazi né accenti (`curiosita`). Quello che
  /// si salva sullo spot.
  final String slug;

  /// Nome visibile ("Curiosità").
  final String label;

  /// Categoria con cui si raggruppano nel selettore ("Generici", "Burocrazia").
  final String category;

  @override
  List<Object?> get props => [slug, label, category];
}
