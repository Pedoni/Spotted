import 'package:spotted/features/chat/domain/entities/chat_summary.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Come si chiama l'altra persona. L'autore vede lo username del commentatore;
/// il commentatore vede l'autore come "Autore del post" finché l'identità non
/// è rivelata.
String chatPartnerName(AppLocalizations l10n, ChatSummary chat) {
  final username = chat.otherUsername;
  return username == null ? l10n.spotAuthor : '@$username';
}
