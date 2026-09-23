import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/entities/product.dart';
import 'package:aplicacion_mundo_otaku/features/products/infrastructure/mappers/product_mapper.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange_message.dart';

class ChatExchangeMapper {
  static ChatExchange jsonToEntity(Map<String, dynamic> json) {
    final owner1 = json['owner1'] ?? json['__owner1__'];
    final owner2 = json['owner2'] ?? json['__owner2__'];
    final product1 = json['product1'] ?? json['__product1__'];
    final product2 = json['product2'] ?? json['__product2__'];
    final requester1 = json['requester1'] ?? json['__requester1__'];

    return ChatExchange(
      id: json['id'] ?? '',
      owner1: owner1?['id'] ?? '',
      owner2: owner2?['id'] ?? '',
      product1: product1?['id'] ?? '',
      product2: product2?['id'] ?? '',
      requester1: requester1?['id'] ?? '',
      status: json['status'] ?? '',
      messages: _messagesFrom(json['messages']),
      product1Detail: _productoDe(product1),
      product2Detail: _productoDe(product2),
    );
  }

  /// Construye el producto solo si vino completo.
  ///
  /// Si la API mandara únicamente el identificador —o si algún campo faltara—
  /// se devuelve `null` y quien lo use recurre al catálogo, como antes. Vale más
  /// una tarjeta que tarda que una pantalla que revienta.
  static Product? _productoDe(dynamic bruto) {
    if (bruto is! Map) return null;
    if (bruto['title'] == null) return null;
    try {
      return ProductMapper.jsonToEntity(Map<String, dynamic>.from(bruto))
          as Product;
    } catch (_) {
      return null;
    }
  }

  static List<ChatExchangeMessage> _messagesFrom(dynamic rawMessages) {
    if (rawMessages is! List) return const [];

    return rawMessages
        .whereType<Map>()
        .map((message) =>
            ChatExchangeMessage.fromJson(Map<String, dynamic>.from(message)))
        .toList();
  }
}
