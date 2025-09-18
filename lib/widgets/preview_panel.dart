import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'dart:js_interop';

class PreviewPanel extends StatefulWidget {
  final String content;

  const PreviewPanel({
    super.key,
    required this.content,
  });

  @override
  State<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<PreviewPanel> {
  final ScrollController _scrollController = ScrollController();
  late String _iframeId;
  web.HTMLIFrameElement? _iframeElement;

  @override
  void initState() {
    super.initState();
    _iframeId = 'preview-iframe-${DateTime.now().millisecondsSinceEpoch}';
    _createIframe();
  }

  void _createIframe() {
    _iframeElement = web.document.createElement('iframe') as web.HTMLIFrameElement
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = 'white';
    
    // Register the iframe with Flutter's platform view system
    ui_web.platformViewRegistry.registerViewFactory(
      _iframeId,
      (int viewId) => _iframeElement!,
    );
    
    _updateIframeContent();
  }

  void _updateIframeContent() {
  if (_iframeElement != null && widget.content.isNotEmpty) {
    // Create a complete HTML document with error handling for missing images
    final wrappedContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Preview</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 20px;
            background-color: #fafafa;
        }
        img {
            max-width: 100%;
            height: auto;
            border: 1px solid #ddd;
            border-radius: 4px;
            padding: 4px;
            background-color: white;
        }
        img[src=""], img:not([src]) {
            background-color: #f8f8f8;
            border: 2px dashed #ccc;
            color: #666;
            display: inline-block;
            min-width: 200px;
            min-height: 100px;
            position: relative;
        }
        .missing-image-placeholder {
            background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
            border: 2px dashed #6c757d;
            color: #495057;
            display: inline-flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-width: 250px;
            min-height: 150px;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            text-align: center;
            margin: 8px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            transition: all 0.2s ease;
            position: relative;
            overflow: hidden;
        }
        .missing-image-placeholder:hover {
            border-color: #495057;
            box-shadow: 0 4px 8px rgba(0,0,0,0.15);
        }
        .placeholder-icon {
            font-size: 32px;
            margin-bottom: 12px;
            opacity: 0.7;
        }
        .placeholder-title {
            font-size: 14px;
            font-weight: 600;
            margin-bottom: 8px;
            color: #343a40;
        }
        .placeholder-filename {
            font-size: 13px;
            font-weight: 500;
            color: #6f42c1;
            background-color: rgba(111, 66, 193, 0.1);
            padding: 4px 8px;
            border-radius: 4px;
            margin-bottom: 8px;
            font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
        }
        .placeholder-instruction {
            font-size: 11px;
            color: #6c757d;
            line-height: 1.4;
            margin-top: 4px;
        }
    </style>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Handle broken images
            const images = document.querySelectorAll('img');
            images.forEach(function(img) {
                img.addEventListener('error', function() {
                    // Check if src is empty or just a filename (not a data URL or HTTP URL)
                    const src = img.src || img.getAttribute('src') || '';
                    if (src === '' || src.indexOf('.') > -1) {
                        const filename = img.src.split('/').pop() || img.getAttribute('src') || 'Unknown';
                        const placeholder = document.createElement('div');
                        placeholder.className = 'missing-image-placeholder';
                        placeholder.innerHTML = 
                            '<div class="placeholder-title">Image Pending Upload</div>' +
                            '<div class="placeholder-filename">' + filename + '</div>' +
                            '<div class="placeholder-instruction">This image will appear here once<br>you upload it using the control panel</div>';
                        img.parentNode.replaceChild(placeholder, img);
                    };
                });
            });
            
            // Handle internal links to prevent navigation
            const links = document.querySelectorAll('a[href^="#"]');
            links.forEach(function(link) {
                link.addEventListener('click', function(e) {
                    e.preventDefault();
                    const targetId = link.getAttribute('href').substring(1);
                    const target = document.getElementById(targetId);
                    if (target) {
                        target.scrollIntoView({ behavior: 'smooth' });
                    }
                });
            });
        });
    </script>
</head>
<body>
    ${widget.content}
</body>
</html>
    ''';
    
    // Use srcdoc instead of blob URL for better compatibility
    _iframeElement!.srcdoc = wrappedContent as JSAny;
  } else if (_iframeElement != null) {
    // Show empty state
    _iframeElement!.srcdoc = '''
<html>
<body style="font-family:Arial;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;color:#666;text-align:center;background:#fafafa;">
  <div>
    <div style="font-size:48px;margin-bottom:16px;">📄</div>
    <h3 style="margin:0 0 8px 0;color:#495057;">No HTML Content</h3>
    <p style="margin:0;color:#6c757d;">Upload an HTML file to see the preview</p>
  </div>
</body>
</html>
    ''' as JSAny;
  }
}

  @override
  void didUpdateWidget(PreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _updateIframeContent();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Preview Controls
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Content Preview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 16),
                if (widget.content.isNotEmpty) _buildStatsChip(),
              ],
            ),
          ),
          
          // Content Area
          Expanded(
            child: widget.content.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.preview,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Upload an HTML file to see preview',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildRenderedView(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsChip() {
    final contentLength = widget.content.length;
    final base64Count = widget.content.split('data:image/').length - 1;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: base64Count > 0 ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: base64Count > 0 ? Colors.green.shade300 : Colors.orange.shade300,
        ),
      ),
      child: Text(
        '${_formatBytes(contentLength)} • $base64Count embedded',
        style: TextStyle(
          fontSize: 11,
          color: base64Count > 0 ? Colors.green.shade700 : Colors.orange.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRenderedView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: HtmlElementView(viewType: _iframeId),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}