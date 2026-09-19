import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/shared.dart';

// final socketServiceProvider = Provider.family<SocketService, String>((ref, productId, conversacionId, sendBy) {
//   // return SocketService(tokencito: productId, chatExchangeId: conversacionId, sendBy: sendBy);
//   // return SocketService(chatExchangeId: conversacionId, sendBy: sendBy);
//   return SocketService();
// } as FamilyCreate<SocketService, ProviderRef<SocketService>, String>);
final socketServiceProvider =
    Provider<SocketService>((ref) => SocketService.instance);
