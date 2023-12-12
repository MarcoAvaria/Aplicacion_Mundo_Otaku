import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/framework.dart';
import '../../../shared/shared.dart';

final socketServiceProvider = Provider.family<SocketService, String>((ref, productId, conversacionId, sendBy) {
  return SocketService(tokencito: productId, chatExchangeId: conversacionId, sendBy: sendBy);
} as FamilyCreate<SocketService, ProviderRef<SocketService>, String>);