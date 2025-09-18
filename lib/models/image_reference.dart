class ImageReference {
  final String src;
  final String fileName;
  final String fullTag;
  String? base64Data;
  bool isUploaded;

  ImageReference({
    required this.src,
    required this.fileName,
    required this.fullTag,
    this.base64Data,
    this.isUploaded = false,
  });

  @override
  String toString() {
    return 'ImageReference(src: $src, fileName: $fileName, isUploaded: $isUploaded)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageReference &&
          runtimeType == other.runtimeType &&
          src == other.src;

  @override
  int get hashCode => src.hashCode;
}