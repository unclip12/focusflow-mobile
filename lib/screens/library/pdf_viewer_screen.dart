import 'package:flutter/material.dart';
import 'dart:io';

import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

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
      body: Container(
        color: cs.surface,
        child: SfPdfViewer.file(
          File(filePath),
        ),
      ),
    );
  }
}
