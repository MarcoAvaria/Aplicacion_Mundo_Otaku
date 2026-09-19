import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'camera_gallery_service.dart';

class CameraGalleryServiceImpl extends CameraGalleryService {
  final ImagePicker _picker = ImagePicker();
  static final Map<String, Uint8List> _selectedPhotoBytes = {};

  static Future<Uint8List> readPhotoBytes(String path) async {
    final selectedBytes = _selectedPhotoBytes[path];
    if (selectedBytes != null) return selectedBytes;

    return XFile(path).readAsBytes();
  }

  static void forgetPhotoBytes(String path) {
    _selectedPhotoBytes.remove(path);
  }

  Future<String?> _rememberPhoto(XFile? photo) async {
    if (photo == null) return null;

    _selectedPhotoBytes[photo.path] = await photo.readAsBytes();
    return photo.path;
  }

  @override
  Future<String?> selectPhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      //preferredCameraDevice: CameraDevice.rear
    );

    return _rememberPhoto(photo);
  }

  @override
  Future<String?> takePhoto() async {
    final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear);

    return _rememberPhoto(photo);
  }
}
