import 'package:flutter/material.dart';
import 'package:spotted/core/widgets/channel_avatar.dart';
import 'package:spotted/core/widgets/squircle_avatar.dart';

/// Avatar di una persona. Se lo username è noto è l'iniziale su un colore
/// della palette; se è anonima (`username` nullo) è una maschera su indaco, il
/// colore dell'anonimato.
class UserAvatar extends StatelessWidget {
  const UserAvatar({this.username, this.size = 44, super.key});

  /// `null` quando la persona è anonima.
  final String? username;
  final double size;

  @override
  Widget build(BuildContext context) {
    final name = username;
    if (name != null) {
      return ChannelAvatar(name: name, size: size);
    }
    final scheme = Theme.of(context).colorScheme;
    return SquircleAvatar(
      background: scheme.secondaryContainer,
      size: size,
      child: Icon(
        Icons.theater_comedy_outlined,
        size: size * 0.52,
        color: scheme.onSecondaryContainer,
      ),
    );
  }
}
