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
  });

  factory ProfileDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileDtoFromJson(json);

  final String id;
  final String username;
  final String? firstName;
  final String? lastName;

  Profile toEntity() => Profile(
    id: id,
    username: username,
    firstName: firstName,
    lastName: lastName,
  );
}
