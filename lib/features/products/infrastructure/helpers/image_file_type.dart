import 'dart:typed_data';

class ImageFileType {
  final String extension;
  final String mimeSubtype;

  const ImageFileType(this.extension, this.mimeSubtype);
}

bool isPendingImageUploadPath(String path) {
  final normalizedPath = path.toLowerCase();
  if (normalizedPath.startsWith('http://') ||
      normalizedPath.startsWith('https://')) {
    return false;
  }

  return normalizedPath.startsWith('blob:') ||
      normalizedPath.startsWith('file:') ||
      path.contains('/') ||
      path.contains('\\');
}

String imageReferenceForApi(String path) {
  final uri = Uri.tryParse(path);
  if (uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.last;
  }

  return path;
}

ImageFileType detectImageFileType(Uint8List bytes) {
  if (_startsWith(bytes, const [0xFF, 0xD8, 0xFF])) {
    return const ImageFileType('jpg', 'jpeg');
  }
  if (_startsWith(bytes, const [0x89, 0x50, 0x4E, 0x47])) {
    return const ImageFileType('png', 'png');
  }
  if (_startsWith(bytes, const [0x47, 0x49, 0x46, 0x38])) {
    return const ImageFileType('gif', 'gif');
  }
  if (bytes.length >= 12 &&
      _matchesAt(bytes, 0, const [0x52, 0x49, 0x46, 0x46]) &&
      _matchesAt(bytes, 8, const [0x57, 0x45, 0x42, 0x50])) {
    return const ImageFileType('webp', 'webp');
  }

  throw const FormatException(
      'El archivo seleccionado no es una imagen válida.');
}

bool _startsWith(Uint8List bytes, List<int> signature) {
  return _matchesAt(bytes, 0, signature);
}

bool _matchesAt(Uint8List bytes, int offset, List<int> signature) {
  if (bytes.length < offset + signature.length) return false;
  for (var index = 0; index < signature.length; index++) {
    if (bytes[offset + index] != signature[index]) return false;
  }
  return true;
}
