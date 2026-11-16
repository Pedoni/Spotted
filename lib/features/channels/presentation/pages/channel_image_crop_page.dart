import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:spotted/core/widgets/inline_progress.dart';
import 'package:spotted/features/channels/domain/entities/channel_image_kind.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Ritaglio di una foto nella proporzione giusta: la cornice è fissa e si
/// muove e si ingrandisce la foto con le dita. Restituisce (con `pop`) la parte
/// dentro la cornice.
class ChannelImageCropPage extends StatefulWidget {
  const ChannelImageCropPage({
    required this.source,
    required this.kind,
    super.key,
  });

  final Uint8List source;
  final ChannelImageKind kind;

  @override
  State<ChannelImageCropPage> createState() => _ChannelImageCropPageState();
}

class _ChannelImageCropPageState extends State<ChannelImageCropPage> {
  final _controller = CropController();
  bool _ready = false;
  bool _cropping = false;

  void _onCropped(CropResult result) {
    switch (result) {
      case CropSuccess(:final croppedImage):
        Navigator.of(context).pop(croppedImage);
      case CropFailure():
        // Si resta sulla pagina: si può riprovare o rinunciare.
        setState(() => _cropping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).errorImageInvalid),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final title = widget.kind == ChannelImageKind.avatar
        ? l10n.cropPhotoTitle
        : l10n.cropCoverTitle;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Crop(
                image: widget.source,
                controller: _controller,
                aspectRatio: widget.kind.aspectRatio,
                // La cornice sta ferma e si muove la foto, con le dita.
                interactive: true,
                fixCropRect: true,
                baseColor: scheme.surface,
                maskColor: scheme.scrim.withValues(alpha: 0.6),
                progressIndicator: const InlineProgress(size: 32),
                onStatusChanged: (status) {
                  if (status == CropStatus.ready && !_ready) {
                    setState(() => _ready = true);
                  }
                },
                onCropped: _onCropped,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.cropHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: !_ready || _cropping
                        ? null
                        : () {
                            setState(() => _cropping = true);
                            _controller.crop();
                          },
                    child: _cropping
                        ? const InlineProgress()
                        : Text(l10n.cropConfirm),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
