import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/shared.dart';

final socketServiceProvider = Provider.family<SocketService, String>((ref, productId) {
  return SocketService(tokencito: productId);
});