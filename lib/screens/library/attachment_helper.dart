import 'package:flutter/material.dart';
import 'package:focusflow_mobile/screens/library/image_viewer_screen.dart';
import 'package:focusflow_mobile/screens/library/pdf_viewer_screen.dart';
import 'package:focusflow_mobile/screens/library/video_player_screen.dart';

enum AttachmentType { image, pdf, video, unknown }

class AttachmentHelper {
  static const _imageExtensions = {
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'heif', 'tiff', 'tif',
  };

  static const _videoExtensions = {
    'mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv', 'webm', 'm4v', '3gp',
  };

  static AttachmentType getType(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (_imageExtensions.contains(ext)) return AttachmentType.image;
    if (ext == 'pdf') return AttachmentType.pdf;
    if (_videoExtensions.contains(ext)) return AttachmentType.video;
    return AttachmentType.unknown;
  }

  static IconData getIcon(String path) {
    switch (getType(path)) {
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

  static void openAttachment(BuildContext context, String path) {
    switch (getType(path)) {
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
            content: Text('Cannot preview this file type: ${path.split('.').last}'),
          ),
        );
        break;
    }
  }
}
