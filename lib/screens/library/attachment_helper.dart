import 'package:flutter/material.dart';
import 'package:focusflow_mobile/screens/library/image_viewer_screen.dart';
import 'package:focusflow_mobile/screens/library/pdf_viewer_screen.dart';
import 'package:focusflow_mobile/screens/library/video_player_screen.dart';
import 'package:url_launcher/url_launcher.dart';

enum AttachmentType { link, image, pdf, video, unknown }

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
    return AttachmentType.unknown;
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
      case AttachmentType.unknown:
        return Icons.attachment_rounded;
    }
  }

  static Future<void> openAttachment(BuildContext context, String path) async {
    switch (getType(path)) {
      case AttachmentType.link:
        final uri = Uri.parse(path);
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!context.mounted) return;
        if (!launched) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $path')),
          );
        }
        break;
      case AttachmentType.image:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ImageViewerScreen(filePath: path)),
        );
        break;
      case AttachmentType.pdf:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PdfViewerScreen(filePath: path)),
        );
        break;
      case AttachmentType.video:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VideoPlayerScreen(filePath: path)),
        );
        break;
      case AttachmentType.unknown:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Cannot preview this file type: ${path.split('.').last}'),
          ),
        );
        break;
    }
  }
}
