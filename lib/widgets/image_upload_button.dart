import 'package:flutter/material.dart';
import '../models/image_reference.dart';
import '../services/file_service.dart';

class ImageUploadButton extends StatefulWidget {
  final ImageReference imageReference;
  final Function(List<Map<String, dynamic>>, String?) onMultipleImagesUploaded;

  const ImageUploadButton({
    super.key,
    required this.imageReference,
    required this.onMultipleImagesUploaded,
  });

  @override
  State<ImageUploadButton> createState() => _ImageUploadButtonState();
}

class _ImageUploadButtonState extends State<ImageUploadButton> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: widget.imageReference.isUploaded ? 2 : 1,
      child: ListTile(
        leading: Icon(
          widget.imageReference.isUploaded 
              ? Icons.check_circle 
              : Icons.image,
          color: widget.imageReference.isUploaded 
              ? Colors.green 
              : Colors.grey,
        ),
        title: Text(
          widget.imageReference.fileName,
          style: TextStyle(
            fontWeight: widget.imageReference.isUploaded 
                ? FontWeight.bold 
                : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          widget.imageReference.isUploaded 
              ? 'Uploaded and ready' 
              : 'Click to upload image(s)',
          style: TextStyle(
            color: widget.imageReference.isUploaded 
                ? Colors.green 
                : Colors.grey.shade600,
          ),
        ),
        trailing: _isUploading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                widget.imageReference.isUploaded 
                    ? Icons.done 
                    : Icons.upload,
                color: widget.imageReference.isUploaded 
                    ? Colors.green 
                    : null,
              ),
        onTap: widget.imageReference.isUploaded || _isUploading 
            ? null 
            : _uploadImages,
      ),
    );
  }

  Future<void> _uploadImages() async {
    setState(() => _isUploading = true);

    try {
      final images = await FileService.pickImageFiles();
      
      if (images.isNotEmpty) {
        // Pass all images to parent for centralized handling
        // Include the target image name so parent knows which button was clicked
        widget.onMultipleImagesUploaded(images, widget.imageReference.fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Error uploading images: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }
}