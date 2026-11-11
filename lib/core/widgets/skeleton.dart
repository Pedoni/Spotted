import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:spotted/core/theme/app_skeleton.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// `true` se [context] sta venendo disegnato come scheletro. I widget con un
/// colore proprio (avatar, bolle) lo usano per mostrarsi neutri invece di
/// colorati mentre carica.
bool isSkeleton(BuildContext context) {
  return Skeletonizer.maybeOf(context)?.enabled ?? false;
}

/// Mostra [child] come scheletro di caricamento: gli stessi widget della
/// schermata vera, con dati finti, disegnati come forme grigie che brillano.
///
/// Per i caricamenti si usa sempre questo widget e mai `Skeletonizer`
/// direttamente: qui ci sono il tema dell'app, il blocco dei tocchi (i dati
/// sono finti, non si deve poter aprire niente) e l'accessibilità (un lettore
/// di schermo annuncia "Caricamento in corso", non i testi finti).
class Skeleton extends StatelessWidget {
  const Skeleton({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.loading,
      container: true,
      child: ExcludeSemantics(
        child: SkeletonizerConfig(
          data: AppSkeleton.config(Theme.of(context).colorScheme),
          child: Skeletonizer(child: child),
        ),
      ),
    );
  }
}

/// Uno scheletro a tutta pagina: non scorre e, se è più alto dello schermo,
/// viene tagliato invece di dare errore di overflow.
class SkeletonScroll extends StatelessWidget {
  const SkeletonScroll({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: child,
    );
  }
}
