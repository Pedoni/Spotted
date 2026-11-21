import 'package:json_annotation/json_annotation.dart';

/// Un messaggio normale o uno di sistema, scritto dal database nelle chat con
/// un canale quando uno spot viene inviato, pubblicato o rifiutato.
enum ChatMessageKind {
  @JsonValue('text')
  text,
  @JsonValue('spot_sent')
  spotSent,
  @JsonValue('spot_approved')
  spotApproved,
  @JsonValue('spot_rejected')
  spotRejected;

  /// Un messaggio di sistema (non scritto da una persona).
  bool get isSystem => this != text;
}
