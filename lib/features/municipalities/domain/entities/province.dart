import 'package:equatable/equatable.dart';

/// Una provincia (o città metropolitana, o libero consorzio) con la sua
/// regione.
class Province extends Equatable {
  const Province({
    required this.code,
    required this.name,
    required this.regionName,
  });

  /// La sigla ("PI").
  final String code;
  final String name;
  final String regionName;

  @override
  List<Object?> get props => [code, name, regionName];
}
