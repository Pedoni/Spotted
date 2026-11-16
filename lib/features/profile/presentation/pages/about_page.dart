import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/core/app_info/app_info.dart';
import 'package:spotted/core/theme/app_colors.dart';
import 'package:spotted/core/widgets/radar_logo.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/core/widgets/squircle_avatar.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Informazioni sull'app: il logo, il nome, la versione e le licenze dei
/// pacchetti open source usati.
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final info = ref.watch(appInfoProvider);

    Widget versionTile(String value) => ListTile(
      leading: const Icon(Icons.info_outline_rounded),
      title: Text(l10n.appVersion),
      trailing: Text(value, style: theme.textTheme.bodyMedium),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutApp)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(
            // Il logo è pensato per lo sfondo inchiostro, uguale nel tema
            // chiaro e in quello scuro.
            child: SquircleAvatar(
              background: AppColors.ink,
              size: 112,
              child: RadarLogo(size: 76, animate: false),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.appTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.appTagline,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          // Mentre la versione si legge la riga è uno scheletro. Se non si
          // legge (non dovrebbe succedere) resta senza valore: il resto della
          // pagina funziona lo stesso.
          if (info.isLoading)
            Skeleton(child: versionTile('0.0.0 (0)'))
          else
            versionTile(info.value?.label ?? ''),
          ListTile(
            leading: const Icon(Icons.description_rounded),
            title: Text(l10n.openSourceLicenses),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appTitle,
              applicationVersion: info.value?.label,
              applicationIcon: const Padding(
                padding: EdgeInsets.all(8),
                child: SquircleAvatar(
                  background: AppColors.ink,
                  size: 64,
                  child: RadarLogo(size: 44, animate: false),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
