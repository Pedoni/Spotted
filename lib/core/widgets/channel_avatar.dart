import 'package:flutter/material.dart';
import 'package:spotted/core/theme/app_text.dart';
import 'package:spotted/core/widgets/squircle_avatar.dart';

/// Avatar di un canale (o di una persona di cui si conosce lo username):
/// l'iniziale su un quadrato dagli angoli molto arrotondati. Il colore viene
/// dalla palette e dipende da [seed] (di norma l'id del canale): lo stesso
/// canale ha sempre lo stesso colore.
class ChannelAvatar extends StatelessWidget {
  const ChannelAvatar({
    required this.name,
    this.seed,
    this.size = 44,
    super.key,
  });

  final String name;

  /// Da cui si sceglie il colore; se manca si usa [name].
  final String? seed;
  final double size;

  /// Le coppie (sfondo, testo) tra cui si sceglie: i tre colori di marca
  /// (lampone, indaco, giallo) pieni, lampone e indaco in versione chiara e un
  /// neutro.
  static List<(Color, Color)> palette(ColorScheme scheme) => [
    (scheme.primary, scheme.onPrimary),
    (scheme.secondary, scheme.onSecondary),
    (scheme.tertiary, scheme.onTertiary),
    (scheme.primaryContainer, scheme.onPrimaryContainer),
    (scheme.secondaryContainer, scheme.onSecondaryContainer),
    (scheme.surfaceContainerHighest, scheme.onSurface),
  ];

  /// Hash stabile (non dipende dalla sessione, a differenza di `hashCode`).
  static int colorIndex(String seed, int length) {
    final hash = seed.runes.fold<int>(0, (h, c) => (h * 31 + c) & 0x7fffffff);
    return hash % length;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = palette(scheme);
    final (background, foreground) =
        colors[colorIndex(seed ?? name, colors.length)];
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().characters.first.toUpperCase();

    return SquircleAvatar(
      background: background,
      size: size,
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.46,
          color: foreground,
          height: 1,
        ),
      ),
    );
  }
}
