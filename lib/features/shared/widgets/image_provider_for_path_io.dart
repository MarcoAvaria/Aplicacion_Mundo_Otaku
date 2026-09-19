import 'dart:io';

import 'package:flutter/material.dart';

ImageProvider<Object> platformImageProviderForPath(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }
  return FileImage(File(path));
}
