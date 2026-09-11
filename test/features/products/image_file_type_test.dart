import 'dart:typed_data';

import 'package:aplicacion_mundo_otaku/features/products/infrastructure/helpers/image_file_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('detectImageFileType', () {
    test('recognizes image content instead of trusting the file name', () {
      final jpeg = detectImageFileType(
        Uint8List.fromList([0xFF, 0xD8, 0xFF, 0x00]),
      );
      final png = detectImageFileType(
        Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]),
      );
      final webp = detectImageFileType(
        Uint8List.fromList([
          0x52,
          0x49,
          0x46,
          0x46,
          0,
          0,
          0,
          0,
          0x57,
          0x45,
          0x42,
          0x50,
        ]),
      );

      expect((jpeg.extension, jpeg.mimeSubtype), ('jpg', 'jpeg'));
      expect((png.extension, png.mimeSubtype), ('png', 'png'));
      expect((webp.extension, webp.mimeSubtype), ('webp', 'webp'));
    });

    test('rejects bytes that do not match a supported image signature', () {
      expect(
        () => detectImageFileType(Uint8List.fromList('plain text'.codeUnits)),
        throwsFormatException,
      );
    });
  });

  group('stored product images', () {
    test('keeps server URLs and only uploads local or browser paths', () {
      expect(
        isPendingImageUploadPath(
          'https://demo.test/api/files/product/existing.jpg',
        ),
        isFalse,
      );
      expect(isPendingImageUploadPath(r'C:\images\new.jpg'), isTrue);
      expect(isPendingImageUploadPath('blob:https://demo.test/new'), isTrue);
    });

    test('sends the stored filename back to the API when editing', () {
      expect(
        imageReferenceForApi(
          'https://demo.test/api/files/product/existing.jpg',
        ),
        'existing.jpg',
      );
      expect(imageReferenceForApi('existing.jpg'), 'existing.jpg');
    });
  });
}
