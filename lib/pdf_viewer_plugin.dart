import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

typedef void PdfViewerCreatedCallback();

class PDF extends StatefulWidget {
  const PDF._(this.filePath,
      {this.width = 150, this.height = 250, this.placeHolder});

  factory PDF.network(
    String filePath, {
    double width = 150,
    double height = 250,
    Widget placeHolder,
  }) {
    return PDF._(filePath,
        width: width, height: height, placeHolder: placeHolder);
  }

  final String filePath;
  final double height;
  final double width;
  final Widget placeHolder;

  @override
  _PDFState createState() => _PDFState();
}

class _PDFState extends State<PDF> {
  String path;

  Future<File> get _localFile async {
    final String path = (await getApplicationDocumentsDirectory()).path;
    return File('$path/${Uuid().toString()}.pdf');
  }

  Future<File> writeCounter(Uint8List stream) async {
    final file = await _localFile;

    // Write the file
    return file.writeAsBytes(stream);
  }

  Future<bool> existsFile() async {
    final file = await _localFile;
    return file.exists();
  }

  Future<Uint8List> fetchPost() async {
    final response = await http.get(widget.filePath);
    final responseJson = response.bodyBytes;

    return responseJson;
  }

  void loadPdf() async {
    await writeCounter(await fetchPost());
    await existsFile();
    path = (await _localFile).path;

    if (!mounted) return;

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadPdf();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
        duration: Duration(milliseconds: 500),
        child: (path != null)
            ? Container(
                height: widget.height,
                width: widget.width,
                child: PdfViewer(
                  filePath: path,
                ),
              )
            : Container(
                height: widget.height,
                width: widget.width,
                child: widget.placeHolder ??
                    Center(
                      child: Container(
                        height: min(widget.height, widget.width),
                        width: min(widget.height, widget.width),
                        child: CircularProgressIndicator(),
                      ),
                    ),
              ));
  }
}

class PdfViewer extends StatefulWidget {
  const PdfViewer({
    Key key,
    this.filePath,
    this.onPdfViewerCreated,
  }) : super(key: key);

  final String filePath;
  final PdfViewerCreatedCallback onPdfViewerCreated;

  @override
  _PdfViewerState createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'pdf_viewer_plugin',
        creationParams: <String, dynamic>{
          'filePath': widget.filePath,
        },
        creationParamsCodec: StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'pdf_viewer_plugin',
        creationParams: <String, dynamic>{
          'filePath': widget.filePath,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }

    return Text(
        '$defaultTargetPlatform is not yet supported by the pdf_viewer plugin');
  }

  void _onPlatformViewCreated(int id) {
    if (widget.onPdfViewerCreated == null) {
      return;
    }
    widget.onPdfViewerCreated();
  }
}
