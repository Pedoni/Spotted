import 'package:json_annotation/json_annotation.dart';
import 'package:spotted/features/tags/domain/entities/tag.dart';

part 'tag_dto.g.dart';

@JsonSerializable(createToJson: false)
class TagDto {
  const TagDto({
    required this.slug,
    required this.label,
    required this.category,
  });

  factory TagDto.fromJson(Map<String, dynamic> json) => _$TagDtoFromJson(json);

  final String slug;
  final String label;
  final String category;

  Tag toEntity() => Tag(slug: slug, label: label, category: category);
}
