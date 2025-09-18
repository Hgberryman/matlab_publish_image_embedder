import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

class FileService {
  static Future<Map<String, dynamic>?> pickHtmlFile() async {
    try {
      // Create file input element
      final input = web.document.createElement('input') as web.HTMLInputElement
        ..type = 'file'
        ..accept = '.html,.htm'
        ..style.display = 'none';

      web.document.body?.appendChild(input);

      // Wait for file selection
      final completer = Completer<Map<String, dynamic>?>();
      
      void handleChange(web.Event event) {
        final files = input.files;
        if (files != null && files.length > 0) {
          final file = files.item(0)!;
          final reader = web.FileReader();
          
          void handleLoad(web.Event e) {
            final content = reader.result as String;
            completer.complete({
              'content': content,
              'fileName': file.name,
            });
          }
          
          void handleError(web.Event e) {
            completer.complete(null);
          }
          
          reader.addEventListener('load', handleLoad.toJS);
          reader.addEventListener('error', handleError.toJS);
          
          reader.readAsText(file);
        } else {
          completer.complete(null);
        }
        
        // Clean up
        web.document.body?.removeChild(input);
      }

      void handleCancel(web.Event event) {
        completer.complete(null);
        web.document.body?.removeChild(input);
      }

      input.addEventListener('change', handleChange.toJS);
      input.addEventListener('cancel', handleCancel.toJS);

      // Trigger file picker
      input.click();
      
      return await completer.future;
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> pickImageFiles() async {
    try {
      // Create file input element
      final input = web.document.createElement('input') as web.HTMLInputElement
        ..type = 'file'
        ..accept = 'image/*'
        ..multiple = true
        ..style.display = 'none';

      web.document.body?.appendChild(input);

      // Wait for file selection
      final completer = Completer<List<Map<String, dynamic>>>();
      
      void handleChange(web.Event event) {
        final files = input.files;
        if (files != null && files.length > 0) {
          List<Map<String, dynamic>> imageData = [];
          int processedFiles = 0;
          
          void checkComplete() {
            if (processedFiles == files.length) {
              completer.complete(imageData);
            }
          }
          
          for (int i = 0; i < files.length; i++) {
            final file = files.item(i)!;
            final reader = web.FileReader();
            
            void handleLoad(web.Event e) {
              final result = reader.result as String;
              // Extract base64 data (remove data:image/...;base64, prefix)
              final base64Data = result.split(',')[1];
              
              imageData.add({
                'fileName': file.name,
                'base64Data': base64Data,
              });
              
              processedFiles++;
              checkComplete();
            }
            
            void handleError(web.Event e) {
              processedFiles++;
              checkComplete();
            }
            
            reader.addEventListener('load', handleLoad.toJS);
            reader.addEventListener('error', handleError.toJS);
            
            reader.readAsDataURL(file);
          }
        } else {
          completer.complete([]);
        }
        
        // Clean up
        web.document.body?.removeChild(input);
      }

      void handleCancel(web.Event event) {
        completer.complete([]);
        web.document.body?.removeChild(input);
      }

      input.addEventListener('change', handleChange.toJS);
      input.addEventListener('cancel', handleCancel.toJS);

      // Trigger file picker
      input.click();
      
      return await completer.future;
    } catch (e) {
      return [];
    }
  }

  static void downloadFile(String content, String fileName) {
    try {
      final bytes = utf8.encode(content);
      final uint8List = Uint8List.fromList(bytes);
      
      // Create blob using the correct web API
      final blob = web.Blob([uint8List.toJS].toJS, web.BlobPropertyBag(type: 'text/html'));
      final url = web.URL.createObjectURL(blob);
      
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..download = fileName
        ..style.display = 'none';
      
      web.document.body?.appendChild(anchor);
      anchor.click();
      
      // Clean up
      web.document.body?.removeChild(anchor);
      web.URL.revokeObjectURL(url);
    } catch (e) {
      // Fallback method
      _downloadFileFallback(content, fileName);
    }
  }

  static void _downloadFileFallback(String content, String fileName) {
    try {
      // Use base64 data URL as fallback
      final bytes = utf8.encode(content);
      final base64Content = base64Encode(bytes);
      final dataUrl = 'data:text/html;base64,$base64Content';
      
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement
        ..href = dataUrl
        ..download = fileName
        ..style.display = 'none';
      
      web.document.body?.appendChild(anchor);
      anchor.click();
      web.document.body?.removeChild(anchor);
    } catch (e) {
    //
    }
  }
}