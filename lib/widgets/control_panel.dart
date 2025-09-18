import 'package:flutter/material.dart';
import '../models/image_reference.dart';
import '../services/html_parser_service.dart';
import '../services/file_service.dart';
import 'image_upload_button.dart';

class ControlPanel extends StatefulWidget {
  final List<ImageReference> imageReferences;
  final String? htmlFileName;
  final Function(String content, String fileName, List<ImageReference> images) onHtmlUploaded;
  final Function(String imageName, String base64Data) onImageUploaded;
  final VoidCallback onDownload;

  const ControlPanel({
    super.key,
    required this.imageReferences,
    required this.htmlFileName,
    required this.onHtmlUploaded,
    required this.onImageUploaded,
    required this.onDownload,
  });

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  bool _isProcessing = false;
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HTML Upload Button
          _buildSquareButton(
            onPressed: _isProcessing ? null : _uploadHtmlFile,
            icon: _isProcessing 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            label: widget.htmlFileName ?? 'Upload HTML File',
            color: widget.htmlFileName != null ? Colors.green : null,
          ),

          const SizedBox(height: 24),

          // Image Upload Buttons
          if (widget.imageReferences.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Images Required:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${_getUploadedCount()}/${widget.imageReferences.length}',
                  style: TextStyle(
                    color: _canDownload() ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            if (_hasUnuploadedImages()) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'When uploading you can select multiple images.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ],
            
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView.builder(
                itemCount: widget.imageReferences.length,
                itemBuilder: (context, index) {
                  final ref = widget.imageReferences[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ImageUploadButton(
                      imageReference: ref,
                      onMultipleImagesUploaded: _handleMultipleImagesUploaded,
                    ),
                  );
                },
              ),
            ),
          ] else if (widget.htmlFileName != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade600, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'No local images found in this HTML file',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'The file may already have embedded images or only uses external URLs',
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Spacer(),
          ] else ...[
            const Spacer(),
          ],

          const SizedBox(height: 24),

          // Download Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: _canDownload()
                  ? const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              boxShadow: _canDownload()
                  ? [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: (_canDownload() && !_isDownloading) ? _downloadFile : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isDownloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              Icons.download,
                              color: _canDownload() ? Colors.white : Colors.grey,
                              size: 24,
                            ),
                      const SizedBox(width: 12),
                      Text(
                        _isDownloading ? 'Downloading...' : 'Download Modified HTML',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _canDownload() ? Colors.white : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16)
        ],
      ),
    );
  }

  Widget _buildSquareButton({
    required VoidCallback? onPressed,
    required Widget icon,
    required String label,
    Color? color,
  }) {
    return Card(
      elevation: onPressed != null ? 2 : 1,
      child: ListTile(
        leading: icon,
        title: Text(
          label,
          style: TextStyle(
            fontWeight: onPressed != null ? FontWeight.w500 : FontWeight.normal,
            color: color,
          ),
        ),
        onTap: onPressed,
        enabled: onPressed != null,
        tileColor: color?.withValues(alpha: 0.05),
      ),
    );
  }

  bool _hasUnuploadedImages() {
    return widget.imageReferences.any((ref) => !ref.isUploaded);
  }

  void _handleMultipleImagesUploaded(List<Map<String, dynamic>> uploadedImages, String? targetImageName) async {
    if (uploadedImages.isEmpty) return;
    
    int matchedCount = 0;
    List<Map<String, dynamic>> unmatchedImages = [];
    
    // First pass: exact and case-insensitive matches
    for (final imageData in uploadedImages) {
      final fileName = imageData['fileName'] as String;
      final base64Data = imageData['base64Data'] as String;
      bool matched = false;
      
      // Try exact match first
      final exactMatch = widget.imageReferences.where(
        (ref) => !ref.isUploaded && ref.fileName == fileName
      ).toList();
      
      if (exactMatch.isNotEmpty) {
        widget.onImageUploaded(exactMatch.first.fileName, base64Data);
        matchedCount++;
        matched = true;
      } else {
        // Try case-insensitive match
        final caseInsensitiveMatch = widget.imageReferences.where(
          (ref) => !ref.isUploaded && ref.fileName.toLowerCase() == fileName.toLowerCase()
        ).toList();
        
        if (caseInsensitiveMatch.isNotEmpty) {
          widget.onImageUploaded(caseInsensitiveMatch.first.fileName, base64Data);
          matchedCount++;
          matched = true;
        }
      }
      
      if (!matched) {
        unmatchedImages.add(imageData);
      }
    }
    
    // Handle unmatched images
    for (final imageData in unmatchedImages) {
      final selectedReference = await _showImageSelectionDialog(imageData, targetImageName);
      if (selectedReference != null) {
        widget.onImageUploaded(selectedReference.fileName, imageData['base64Data']);
        matchedCount++;
        
        if (imageData['fileName'] != selectedReference.fileName) {
          _showMessage('Warning: Using ${imageData['fileName']} for ${selectedReference.fileName}', isWarning: true);
        }
      }
    }
    
    // Show single summary message
    if (matchedCount > 0) {
      _showMessage('Matched $matchedCount image(s) successfully');
    }
  }

  Future<ImageReference?> _showImageSelectionDialog(Map<String, dynamic> imageData, String? targetImageName) async {
    final availableRefs = widget.imageReferences.where((ref) => !ref.isUploaded).toList();
    
    if (availableRefs.isEmpty) return null;
    
    // If there's only one available reference, use it automatically
    if (availableRefs.length == 1) {
      return availableRefs.first;
    }
    
    return await showDialog<ImageReference>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Target for ${imageData['fileName']}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No exact filename match found. Select which image reference to use for "${imageData['fileName']}":',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: Column(
                      children: availableRefs.map((ref) => Card(
                        color: ref.fileName == targetImageName ? Colors.blue.shade50 : null,
                        child: ListTile(
                          title: Text(ref.fileName),
                          subtitle: Text(
                            _getSimilarityMessage(imageData['fileName'], ref.fileName),
                            style: TextStyle(
                              color: _getSimilarityColor(imageData['fileName'], ref.fileName),
                              fontSize: 12,
                            ),
                          ),
                          leading: Icon(
                            _getSimilarityIcon(imageData['fileName'], ref.fileName),
                            color: _getSimilarityColor(imageData['fileName'], ref.fileName),
                          ),
                          trailing: ref.fileName == targetImageName 
                              ? Icon(Icons.push_pin, color: Colors.blue.shade600, size: 16)
                              : null,
                          onTap: () => Navigator.of(context).pop(ref),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  String _getSimilarityMessage(String uploadedName, String requiredName) {
    if (uploadedName.toLowerCase() == requiredName.toLowerCase()) {
      return 'Case mismatch only';
    } else if (uploadedName.toLowerCase().contains(requiredName.toLowerCase().split('.').first)) {
      return 'Similar name detected';
    } else {
      return 'Different name - use with caution';
    }
  }

  Color _getSimilarityColor(String uploadedName, String requiredName) {
    if (uploadedName.toLowerCase() == requiredName.toLowerCase()) {
      return Colors.orange;
    } else if (uploadedName.toLowerCase().contains(requiredName.toLowerCase().split('.').first)) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  IconData _getSimilarityIcon(String uploadedName, String requiredName) {
    if (uploadedName.toLowerCase() == requiredName.toLowerCase()) {
      return Icons.text_fields;
    } else if (uploadedName.toLowerCase().contains(requiredName.toLowerCase().split('.').first)) {
      return Icons.compare;
    } else {
      return Icons.warning;
    }
  }

  Future<void> _uploadHtmlFile() async {
    setState(() => _isProcessing = true);
    
    try {
      final result = await FileService.pickHtmlFile();
      if (result != null) {
        final content = result['content'] as String;
        final fileName = result['fileName'] as String;
        final images = HtmlParserService.extractImageReferences(content);
        
        widget.onHtmlUploaded(content, fileName, images);
        
        if (images.isEmpty) {
          _showMessage('No local images found in HTML file.', isWarning: true);
        } else {
          _showMessage('HTML file loaded successfully! Found ${images.length} image(s) to process.');
        }
      }
    } catch (e) {
      _showMessage('Error loading HTML file: $e', isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _downloadFile() async {
    setState(() => _isDownloading = true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      widget.onDownload();
      _showMessage('Download completed successfully!');
    } catch (e) {
      _showMessage('Download failed: $e', isError: true);
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  bool _canDownload() {
    return widget.htmlFileName != null && 
           (widget.imageReferences.isEmpty || 
            widget.imageReferences.every((ref) => ref.isUploaded));
  }

  int _getUploadedCount() {
    return widget.imageReferences.where((ref) => ref.isUploaded).length;
  }

  void _showMessage(String message, {bool isError = false, bool isWarning = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error : isWarning ? Icons.warning : Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: isError ? Colors.red : isWarning ? Colors.orange : Colors.green,
          duration: Duration(seconds: isError ? 4 : 3),
        ),
      );
    }
  }
}