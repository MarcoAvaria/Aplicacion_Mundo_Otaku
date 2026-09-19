import 'package:flutter/material.dart';

ImageProvider<Object> platformImageProviderForPath(String path) {
  return NetworkImage(path);
}
