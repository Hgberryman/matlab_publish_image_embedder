import '../models/image_reference.dart';

class HtmlParserService {
  static List<ImageReference> extractImageReferences(String htmlContent) {
    final List<ImageReference> references = [];
    
    // Regular expression to match img tags with src attributes
    final imgTagRegex = RegExp('<img[^>]+src\\s*=\\s*["\']([^"\']+)["\'][^>]*>', caseSensitive: false);
    
    final matches = imgTagRegex.allMatches(htmlContent);
    
    for (final match in matches) {
      final fullTag = match.group(0)!;
      final src = match.group(1)!;
      
      // Extract filename from src (handle both relative and absolute paths)
      final fileName = src.split('/').last.split('\\').last;
      
      // Only process local image files (not URLs)
      if (!src.startsWith('http://') && 
          !src.startsWith('https://') && 
          !src.startsWith('data:') &&
          _isImageFile(fileName)) {
        references.add(ImageReference(
          src: src,
          fileName: fileName,
          fullTag: fullTag,
        ));
      }
    }
    
    return references;
  }
  
  static bool _isImageFile(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    const imageExtensions = ['png', 'jpg', 'jpeg', 'gif', 'svg', 'webp', 'bmp'];
    return imageExtensions.contains(extension);
  }
  
  static String replaceImageSources(String htmlContent, List<ImageReference> references) {
    String updatedContent = htmlContent;
    
    for (final ref in references) {
      if (ref.isUploaded && ref.base64Data != null) {
        final mimeType = _getMimeType(ref.fileName);
        final dataUrl = 'data:$mimeType;base64,${ref.base64Data}';
        
        // Replace the src attribute value
        updatedContent = updatedContent.replaceAll(
          'src="${ref.src}"', 
          'src="$dataUrl"'
        );
      }
    }
    
    return updatedContent;
  }
  
  static String _getMimeType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'svg':
        return 'image/svg+xml';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/png';
    }
  }
}