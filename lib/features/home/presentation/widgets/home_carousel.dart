import 'package:flutter/material.dart';
import 'package:spotted/core/theme/app_shapes.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Larghezza di una card dei caroselli della Home.
const homeCardWidth = 260.0;

/// La forma delle card dei caroselli: a fumetto, con il bordo sottile.
ShapeBorder homeCardShape(ThemeData theme) => RoundedRectangleBorder(
  borderRadius: AppShapes.bubbleRadius,
  side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1.5),
);

/// Un carosello orizzontale della Home: le [children] (le card) e, se c'è
/// [onViewAll], l'ultima card "Visualizza tutti".
class HomeCarousel extends StatelessWidget {
  const HomeCarousel({
    required this.height,
    required this.children,
    this.onViewAll,
    super.key,
  });

  final double height;
  final List<Widget> children;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final cards = [
      ...children,
      if (onViewAll != null) _ViewAllCard(onViewAll!),
    ];
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => cards[index],
      ),
    );
  }
}

/// Scheletro di un carosello: le [children] sono card vere con dati finti.
class HomeCarouselSkeleton extends StatelessWidget {
  const HomeCarouselSkeleton({
    required this.height,
    required this.children,
    super.key,
  });

  final double height;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: SizedBox(
        height: height,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            for (final child in children) ...[child, const SizedBox(width: 12)],
          ],
        ),
      ),
    );
  }
}

class _ViewAllCard extends StatelessWidget {
  const _ViewAllCard(this.onTap);

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 160,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: theme.colorScheme.primaryContainer,
        shape: homeCardShape(theme),
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_forward_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.viewAll,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
