import 'package:json_annotation/json_annotation.dart';
import 'package:spotted/features/municipalities/domain/entities/municipality.dart';

part 'municipality_dto.g.dart';

/// Riga dell'RPC `search_municipalities`.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class MunicipalityDto {
  const MunicipalityDto({
    required this.istatCode,
    required this.name,
    required this.provinceCode,
    required this.provinceName,
    required this.regionName,
  });

  factory MunicipalityDto.fromJson(Map<String, dynamic> json) =>
      _$MunicipalityDtoFromJson(json);

  final String istatCode;
  final String name;
  final String provinceCode;
  final String provinceName;
  final String regionName;

  Municipality toEntity() => Municipality(
    istatCode: istatCode,
    name: name,
    provinceCode: provinceCode,
    provinceName: provinceName,
    regionName: regionName,
  );
}
