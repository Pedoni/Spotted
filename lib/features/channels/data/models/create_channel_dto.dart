import 'package:json_annotation/json_annotation.dart';

part 'create_channel_dto.g.dart';

/// Dati inviati a Supabase per creare un canale.
@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class CreateChannelDto {
  const CreateChannelDto({
    required this.ownerId,
    required this.name,
    required this.slug,
    this.description,
    this.municipalityId,
    this.topicId,
  });

  final String ownerId;
  final String name;
  final String slug;
  final String? description;

  /// Il comune (codice ISTAT), facoltativo. Il luogo da mostrare lo calcola il
  /// database: il client non lo scrive.
  final String? municipalityId;
  final String? topicId;

  Map<String, dynamic> toJson() => _$CreateChannelDtoToJson(this);
}
