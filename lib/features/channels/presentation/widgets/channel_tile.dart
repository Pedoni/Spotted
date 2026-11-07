import 'package:flutter/material.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';

class ChannelTile extends StatelessWidget {
  const ChannelTile({
    required this.channel,
    required this.onTap,
    this.topicName,
    super.key,
  });

  final Channel channel;
  final String? topicName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = [
      topicName,
      channel.place,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

    return ListTile(
      leading: CircleAvatar(
        child: Text(channel.name.characters.first.toUpperCase()),
      ),
      title: Text(channel.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: details.isEmpty
          ? null
          : Text(details, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}
