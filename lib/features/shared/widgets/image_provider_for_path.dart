import 'package:flutter/material.dart';

import 'image_provider_for_path_stub.dart'
    if (dart.library.io) 'image_provider_for_path_io.dart'
    if (dart.library.html) 'image_provider_for_path_web.dart';

ImageProvider<Object> imageProviderForPath(String path) {
  return platformImageProviderForPath(path);
}
