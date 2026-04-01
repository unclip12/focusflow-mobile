import 'package:flutter/material.dart';
import 'dart:io';

import 'package:focusflow_mobile/screens/library/immersive_attachment_scaffold.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatelessWidget {
  final String filePath;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ImmersiveAttachmentScaffold(
      backgroundColor: Colors.black,
      child: ColoredBox(
        color: Colors.black,
        child: SfPdfViewer.file(
          File(filePath),
        ),
      ),
    );
  }
}
