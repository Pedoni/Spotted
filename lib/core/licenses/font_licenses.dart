import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Una licenza di un font incluso nell'app: il nome con cui compare nella
/// pagina delle licenze e il file con il testo.
class FontLicense {
  const FontLicense({required this.name, required this.asset});

  final String name;
  final String asset;
}

/// I font inclusi nell'app e il testo delle loro licenze (SIL Open Font
/// License). I file stanno in `assets/fonts` e vanno dichiarati in
/// `pubspec.yaml`, altrimenti non si possono leggere.
const fontLicenses = [
  FontLicense(
    name: 'Bricolage Grotesque',
    asset: 'assets/fonts/OFL-BricolageGrotesque.txt',
  ),
  FontLicense(
    name: 'Plus Jakarta Sans',
    asset: 'assets/fonts/OFL-PlusJakartaSans.txt',
  ),
];

/// Aggiunge le licenze dei font a quelle che mostra la pagina "Licenze open
/// source". Flutter raccoglie da solo quelle dei pacchetti, ma non quelle dei
/// font: queste si aggiungono a mano. Da chiamare una volta, all'avvio.
void registerFontLicenses([AssetBundle? bundle]) {
  LicenseRegistry.addLicense(() => _entries(bundle ?? rootBundle));
}

Stream<LicenseEntry> _entries(AssetBundle bundle) async* {
  for (final font in fontLicenses) {
    final String text;
    try {
      text = await bundle.loadString(font.asset);
      // Una risorsa che manca lancia un `FlutterError`, che è un `Error` e non
      // un'`Exception`.
      // ignore: avoid_catching_errors
    } on FlutterError {
      // Un file che manca non deve far sparire le altre licenze.
      continue;
    } on Exception {
      continue;
    }
    yield LicenseEntryWithLineBreaks(['${font.name} (font)'], text);
  }
}
