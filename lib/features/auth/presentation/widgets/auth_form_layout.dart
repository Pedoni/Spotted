import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spotted/core/theme/app_colors.dart';
import 'package:spotted/core/theme/app_shapes.dart';
import 'package:spotted/core/theme/app_text.dart';
import 'package:spotted/core/theme/app_theme.dart';
import 'package:spotted/core/widgets/brand_blobs.dart';
import 'package:spotted/core/widgets/radar_logo.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Scheletro comune di accesso e registrazione: in alto il marchio (macchie
/// colorate, radar e scritta, sempre su inchiostro viola come la splash), sotto
/// un foglio con il titolo e il modulo. Scorre se non ci sta.
///
/// Con [tall] la parte alta è più alta e il radar più grande: per i moduli
/// brevi (accesso), che altrimenti lascerebbero il foglio mezzo vuoto.
class AuthFormLayout extends StatelessWidget {
  const AuthFormLayout({
    required this.title,
    required this.child,
    this.tall = false,
    super.key,
  });

  final String title;
  final Widget child;
  final bool tall;

  /// Quanto il foglio sale sulle macchie.
  static const _overlap = 28.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final heroHeight =
        media.padding.top +
        (tall
            ? (media.size.height * 0.36).clamp(230.0, 330.0)
            : (media.size.height * 0.26).clamp(170.0, 250.0));
    final sheetMinHeight = media.size.height - heroHeight + _overlap;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // L'alto è sempre scuro: icone chiare anche con il tema chiaro.
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: heroHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const BrandBlobs(),
                    Padding(
                      padding: EdgeInsets.only(
                        top: media.padding.top,
                        bottom: _overlap,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadarLogo(size: tall ? 108 : 84),
                            const SizedBox(height: 8),
                            Text(
                              l10n.appTitle,
                              style: const TextStyle(
                                fontFamily: AppFonts.display,
                                fontWeight: FontWeight.w800,
                                fontSize: 34,
                                height: 1.1,
                                color: AppColors.cream,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -_overlap),
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(minHeight: sheetMinHeight),
                  decoration: BoxDecoration(
                    color: AppTheme.raised(theme.colorScheme),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.lg),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    24,
                    28,
                    24,
                    24 + media.padding.bottom,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: theme.textTheme.headlineSmall,
                            ),
                          ),
                          const SizedBox(height: 20),
                          child,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
