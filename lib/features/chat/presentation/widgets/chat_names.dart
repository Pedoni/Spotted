import 'package:spotted/features/chat/domain/entities/chat_message_kind.dart';
import 'package:spotted/features/chat/domain/entities/chat_summary.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Come si chiama l'altra parte.
///
/// Chat con un canale: il proprietario vede lo username dell'utente, l'utente
/// vede il canale (il proprietario non compare mai). Chat di uno spot: l'autore
/// vede lo username del commentatore; il commentatore vede l'autore come
/// "Autore del post" finché l'identità non è rivelata.
String chatPartnerName(AppLocalizations l10n, ChatSummary chat) {
  final username = chat.otherUsername;
  if (chat.isChannelChat) {
    return chat.iAmAuthor && username != null ? '@$username' : chat.channelName;
  }
  return username == null ? l10n.spotAuthor : '@$username';
}

/// Il testo di un messaggio di sistema, dal punto di vista di chi legge: chi
/// scrive al canale ("Hai inviato uno spot", "Il canale ha pubblicato il tuo
/// spot") o il proprietario ("@utente ha inviato uno spot", "Hai pubblicato lo
/// spot").
String systemMessageText(
  AppLocalizations l10n,
  ChatSummary chat,
  ChatMessageKind kind,
) {
  final owner = chat.iAmAuthor;
  final user = '@${chat.otherUsername ?? ''}';
  return switch (kind) {
    ChatMessageKind.spotSent =>
      owner ? l10n.systemSpotSentTheirs(user) : l10n.systemSpotSentMine,
    ChatMessageKind.spotApproved =>
      owner
          ? l10n.systemSpotApprovedMine
          : l10n.systemSpotApprovedTheirs(chat.channelName),
    ChatMessageKind.spotRejected =>
      owner
          ? l10n.systemSpotRejectedMine
          : l10n.systemSpotRejectedTheirs(chat.channelName),
    ChatMessageKind.text => '',
  };
}
