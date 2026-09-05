import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Renders a PDF either straight from the network (fast "Read" path, no
/// download required) or from a local file (used after "Download").
class PdfViewerScreen extends StatelessWidget {
  final String title;
  final String? networkUrl;
  final String? localPath;

  const PdfViewerScreen({
    super.key,
    required this.title,
    this.networkUrl,
    this.localPath,
  }) : assert(
          networkUrl != null || localPath != null,
          'Provide either a networkUrl or a localPath',
        );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: localPath != null
          ? SfPdfViewer.file(File(localPath!))
          : SfPdfViewer.network(networkUrl!),
    );
  }
}