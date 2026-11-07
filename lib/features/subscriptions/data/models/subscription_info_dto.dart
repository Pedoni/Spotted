import 'package:json_annotation/json_annotation.dart';
import 'package:spotted/features/subscriptions/domain/entities/subscription_info.dart';

part 'subscription_info_dto.g.dart';

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class SubscriptionInfoDto {
  const SubscriptionInfoDto({
    required this.subscriberCount,
    required this.isSubscribed,
  });

  factory SubscriptionInfoDto.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionInfoDtoFromJson(json);

  final int subscriberCount;
  final bool isSubscribed;

  SubscriptionInfo toEntity() => SubscriptionInfo(
    subscriberCount: subscriberCount,
    isSubscribed: isSubscribed,
  );
}
