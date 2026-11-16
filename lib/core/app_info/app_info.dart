import 'package:equatable/equatable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_info.g.dart';

/// Cos'è l'app installata: la versione e il numero di build, come stanno
/// scritti in `pubspec.yaml` (`0.8.0+1`).
class AppInfo extends Equatable {
  const AppInfo({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;

  /// Come si mostra: "0.8.0 (1)". Senza numero di build, solo la versione.
  String get label => buildNumber.isEmpty ? version : '$version ($buildNumber)';

  @override
  List<Object?> get props => [version, buildNumber];
}

/// La versione dell'app, letta dal sistema. Non cambia finché l'app è aperta.
/// Nei test si sostituisce con una versione fissa.
@Riverpod(keepAlive: true)
Future<AppInfo> appInfo(Ref ref) async {
  final info = await PackageInfo.fromPlatform();
  return AppInfo(version: info.version, buildNumber: info.buildNumber);
}
