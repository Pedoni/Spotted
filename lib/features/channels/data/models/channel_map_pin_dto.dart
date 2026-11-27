import 'package:json_annotation/json_annotation.dart';
import 'package:spotted/features/channels/domain/entities/channel_map_pin.dart';

part 'channel_map_pin_dto.g.dart';

/// Riga dell'RPC `channels_map`. I dati del canale ci sono solo se nel comune
/// ce n'è uno solo.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class ChannelMapPinDto {
  const ChannelMapPinDto({
    required this.municipalityId,
    required this.municipalityLabel,
    required this.latitude,
    required this.longitude,
    required this.channelCount,
    this.channelId,
    this.channelName,
    this.channelSlug,
    this.channelAvatarPath,
  });

  factory ChannelMapPinDto.fromJson(Map<String, dynamic> json) =>
      _$ChannelMapPinDtoFromJson(json);

  final String municipalityId;
  final String municipalityLabel;
  final double latitude;
  final double longitude;
  final int channelCount;
  final String? channelId;
  final String? channelName;
  final String? channelSlug;
  final String? channelAvatarPath;

  ChannelMapPin toEntity() => ChannelMapPin(
    municipalityId: municipalityId,
    municipalityLabel: municipalityLabel,
    latitude: latitude,
    longitude: longitude,
    channelCount: channelCount,
    channel: channelId == null || channelName == null || channelSlug == null
        ? null
        : MapChannel(
            id: channelId!,
            name: channelName!,
            slug: channelSlug!,
            avatarPath: channelAvatarPath,
          ),
  );
}
