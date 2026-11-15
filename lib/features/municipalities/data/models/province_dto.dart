import 'package:json_annotation/json_annotation.dart';
import 'package:spotted/features/municipalities/domain/entities/province.dart';

part 'province_dto.g.dart';

/// Riga dell'RPC `municipality_provinces`.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class ProvinceDto {
  const ProvinceDto({
    required this.provinceCode,
    required this.provinceName,
    required this.regionName,
  });

  factory ProvinceDto.fromJson(Map<String, dynamic> json) =>
      _$ProvinceDtoFromJson(json);

  final String provinceCode;
  final String provinceName;
  final String regionName;

  Province toEntity() => Province(
    code: provinceCode,
    name: provinceName,
    regionName: regionName,
  );
}
