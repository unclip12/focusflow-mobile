import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfViewerScreen extends StatelessWidget {
  final String filePath;

  const PdfViewerScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    final filename = filePath.split('/').last.split('\\').last;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(filename, style: const TextStyle(fontSize: 16)),
      ),
      body: PdfViewer.file(
        filePath,
        params: PdfViewerParams(
          backgroundColor: cs.surface,
          loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
