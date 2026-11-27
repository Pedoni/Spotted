import 'package:json_annotation/json_annotation.dart';
import 'package:spotted/features/profile/domain/entities/profile.dart';

part 'profile_dto.g.dart';

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class ProfileDto {
  const ProfileDto({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.birthDate,
  });

  factory ProfileDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileDtoFromJson(json);

  final String id;
  final String username;
  final String? firstName;
  final String? lastName;

  /// Una data senza ora (`2000-01-31`).
  final DateTime? birthDate;

  Profile toEntity() => Profile(
    id: id,
    username: username,
    firstName: firstName,
    lastName: lastName,
    birthDate: birthDate,
  );
}
