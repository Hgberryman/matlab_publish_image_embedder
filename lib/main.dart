import 'package:flutter/material.dart';
import 'widgets/control_panel.dart';
import 'widgets/preview_panel.dart';
import 'models/image_reference.dart';
import 'services/html_parser_service.dart';
import 'services/file_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HTML Image Embedder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String? htmlContent;
  String? htmlFileName;
  List<ImageReference> imageReferences = [];
  String previewContent = '';

  void _onHtmlUploaded(String content, String fileName, List<ImageReference> images) {
    setState(() {
      htmlContent = content;
      htmlFileName = fileName;
      imageReferences = images;
      previewContent = content;
    });
  }

  void _onImageUploaded(String imageName, String base64Data) {
    setState(() {
      final index = imageReferences.indexWhere((ref) => ref.fileName == imageName);
      if (index != -1) {
        imageReferences[index].base64Data = base64Data;
        imageReferences[index].isUploaded = true;
        _updatePreview();
      }
    });
  }

  void _updatePreview() {
    if (htmlContent == null) return;
    
    final updatedContent = HtmlParserService.replaceImageSources(htmlContent!, imageReferences);
    
    setState(() {
      previewContent = updatedContent;
    });
  }

  void _downloadModifiedHtml() {
    if (htmlContent == null || htmlFileName == null) return;
    
    final modifiedContent = HtmlParserService.replaceImageSources(htmlContent!, imageReferences);
    
    // Create new filename with _embedded suffix
    final fileNameWithoutExtension = htmlFileName!.replaceAll(RegExp(r'\.(html?|htm)$', caseSensitive: false), '');
    final newFileName = '${fileNameWithoutExtension}_embedded.html';
    
    FileService.downloadFile(modifiedContent, newFileName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Row(
        children: [
          // Control Panel (Left Pane)
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: ControlPanel(
                imageReferences: imageReferences,
                htmlFileName: htmlFileName,
                onHtmlUploaded: _onHtmlUploaded,
                onImageUploaded: _onImageUploaded,
                onDownload: _downloadModifiedHtml,
              ),
            ),
          ),
          // Preview Panel (Right Pane)
          Expanded(
            flex: 2,
            child: PreviewPanel(content: previewContent),
          ),
        ],
      ),
    );
  }
}