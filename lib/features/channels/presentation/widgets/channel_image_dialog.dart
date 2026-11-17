import 'package:flutter/material.dart';
import 'package:spotted/features/channels/domain/entities/channel_image_kind.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Cosa sceglie il proprietario nella finestra della foto o della copertina.
enum ChannelImageChoice { gallery, camera, remove }

/// La finestra per cambiare un'immagine del canale: sceglierla dalla galleria,
/// scattarla o, se ce n'è già una, toglierla. Restituisce la scelta, o `null`
/// se si annulla.
Future<ChannelImageChoice?> showChannelImageDialog(
  BuildContext context, {
  required ChannelImageKind kind,
  required bool hasImage,
}) {
  return showDialog<ChannelImageChoice>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final isAvatar = kind == ChannelImageKind.avatar;
      return AlertDialog(
        title: Text(isAvatar ? l10n.channelPhotoTitle : l10n.channelCoverTitle),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(l10n.imageFromGallery),
              onTap: () =>
                  Navigator.of(context).pop(ChannelImageChoice.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: Text(l10n.imageFromCamera),
              onTap: () => Navigator.of(context).pop(ChannelImageChoice.camera),
            ),
            if (hasImage)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: Text(isAvatar ? l10n.removePhoto : l10n.removeCover),
                onTap: () =>
                    Navigator.of(context).pop(ChannelImageChoice.remove),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      );
    },
  );
}

/// Chiede conferma prima di togliere un'immagine.
Future<bool> confirmRemoveChannelImage(
  BuildContext context, {
  required ChannelImageKind kind,
}) async {
  final l10n = AppLocalizations.of(context);
  final isAvatar = kind == ChannelImageKind.avatar;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(isAvatar ? l10n.removePhotoTitle : l10n.removeCoverTitle),
      content: Text(l10n.removeImageBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.removeImageConfirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
