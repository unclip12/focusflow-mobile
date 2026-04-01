import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import 'package:focusflow_mobile/screens/library/immersive_attachment_scaffold.dart';

class ImageViewerScreen extends StatelessWidget {
  final String filePath;
  final String title;

  const ImageViewerScreen({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ImmersiveAttachmentScaffold(
      child: PhotoView(
        imageProvider: FileImage(File(filePath)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3.0,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
              SizedBox(height: 16),
              Text(
                'Could not load image',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
