import 'package:flutter/material.dart';
import 'package:focusflow_mobile/models/library_note.dart';
import 'package:focusflow_mobile/screens/library/audio_player_screen.dart';
import 'package:focusflow_mobile/screens/library/image_viewer_screen.dart';
import 'package:focusflow_mobile/screens/library/pdf_viewer_screen.dart';
import 'package:focusflow_mobile/screens/library/video_player_screen.dart';
import 'package:url_launcher/url_launcher.dart';

enum AttachmentType { link, image, pdf, video, audio, unknown }

class AttachmentHelper {
  static const _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
    'heic',
    'heif',
    'tiff',
    'tif',
  };

  static const _videoExtensions = {
    'mp4',
    'mov',
    'avi',
    'mkv',
    'wmv',
    'flv',
    'webm',
    'm4v',
    '3gp',
  };

  static const _audioExtensions = {
    'mp3',
    'wav',
    'm4a',
    'aac',
    'ogg',
    'oga',
    'flac',
    'wma',
    'amr',
  };

  static bool isWebLink(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static String? normalizeLink(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    return isWebLink(withScheme) ? withScheme : null;
  }

  static AttachmentType getType(String path) {
    if (isWebLink(path)) return AttachmentType.link;
    final ext = path.split('.').last.toLowerCase();
    if (_imageExtensions.contains(ext)) return AttachmentType.image;
    if (ext == 'pdf') return AttachmentType.pdf;
    if (_videoExtensions.contains(ext)) return AttachmentType.video;
    if (_audioExtensions.contains(ext)) return AttachmentType.audio;
    return AttachmentType.unknown;
  }

  static AttachmentType getAttachmentType(LibraryNoteAttachment attachment) {
    switch (attachment.kind) {
      case LibraryNoteAttachmentKind.link:
        return AttachmentType.link;
      case LibraryNoteAttachmentKind.image:
        return AttachmentType.image;
      case LibraryNoteAttachmentKind.pdf:
        return AttachmentType.pdf;
      case LibraryNoteAttachmentKind.video:
        return AttachmentType.video;
      case LibraryNoteAttachmentKind.audio:
        return AttachmentType.audio;
      default:
        return getType(attachment.source);
    }
  }

  static IconData getIcon(String path) {
    switch (getType(path)) {
      case AttachmentType.link:
        return Icons.link_rounded;
      case AttachmentType.image:
        return Icons.image_rounded;
      case AttachmentType.pdf:
        return Icons.picture_as_pdf_rounded;
      case AttachmentType.video:
        return Icons.videocam_rounded;
      case AttachmentType.audio:
        return Icons.audiotrack_rounded;
      case AttachmentType.unknown:
        return Icons.attachment_rounded;
    }
  }

  static IconData getAttachmentIcon(LibraryNoteAttachment attachment) {
    switch (getAttachmentType(attachment)) {
      case AttachmentType.link:
        return Icons.link_rounded;
      case AttachmentType.image:
        return Icons.image_rounded;
      case AttachmentType.pdf:
        return Icons.picture_as_pdf_rounded;
      case AttachmentType.video:
        return Icons.videocam_rounded;
      case AttachmentType.audio:
        return Icons.audiotrack_rounded;
      case AttachmentType.unknown:
        return Icons.attachment_rounded;
    }
  }

  static Future<void> openAttachment(
    BuildContext context,
    String path, {
    String? displayName,
  }) async {
    final attachment = LibraryNoteAttachment(
      source: path,
      displayName:
          (displayName ?? LibraryNoteAttachment.deriveDisplayName(path)).trim(),
      kind: LibraryNoteAttachment.detectKind(path),
    );
    return openNoteAttachment(context, attachment);
  }

  static Future<void> openNoteAttachment(
    BuildContext context,
    LibraryNoteAttachment attachment,
  ) async {
    switch (getAttachmentType(attachment)) {
      case AttachmentType.link:
        final uri = Uri.parse(attachment.source);
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!context.mounted) return;
        if (!launched) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Could not open link: ${attachment.source}')),
          );
        }
        break;
      case AttachmentType.image:
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => ImageViewerScreen(
              filePath: attachment.source,
              title: attachment.displayName,
            ),
          ),
        );
        break;
      case AttachmentType.pdf:
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              filePath: attachment.source,
              title: attachment.displayName,
            ),
          ),
        );
        break;
      case AttachmentType.video:
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              filePath: attachment.source,
              title: attachment.displayName,
            ),
          ),
        );
        break;
      case AttachmentType.audio:
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => AudioPlayerScreen(
              filePath: attachment.source,
              title: attachment.displayName,
            ),
          ),
        );
        break;
      case AttachmentType.unknown:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Cannot preview this file type: ${attachment.source.split('.').last}'),
          ),
        );
        break;
    }
  }
}
