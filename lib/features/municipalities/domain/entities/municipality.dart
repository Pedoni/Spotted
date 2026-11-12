import 'package:equatable/equatable.dart';

/// Un comune italiano dell'elenco ufficiale (ISTAT).
class Municipality extends Equatable {
  const Municipality({
    required this.istatCode,
    required this.name,
    required this.provinceCode,
    required this.provinceName,
    required this.regionName,
  });

  /// Il codice ISTAT a 6 cifre, che identifica il comune.
  final String istatCode;
  final String name;

  /// La sigla della provincia ("PI").
  final String provinceCode;
  final String provinceName;
  final String regionName;

  /// Come si mostra: "Pisa (PI)". Il nome da solo non basta, perché alcuni
  /// comuni hanno lo stesso nome in province diverse.
  String get label => '$name ($provinceCode)';

  @override
  List<Object?> get props => [
    istatCode,
    name,
    provinceCode,
    provinceName,
    regionName,
  ];
}
