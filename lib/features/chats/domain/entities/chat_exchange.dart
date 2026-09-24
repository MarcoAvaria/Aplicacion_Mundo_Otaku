import 'package:aplicacion_mundo_otaku/features/products/domain/entities/product.dart';

import 'chat_exchange_message.dart';

class ChatExchange {
  late String id;
  late String owner1;
  late String owner2;
  late String product1;
  late String product2;
  late String requester1;
  late List<ChatExchangeMessage> messages;
  late String status;

  /// Los dos productos del intercambio, tal como los manda la API.
  ///
  /// La API ya devuelve el objeto completo —con sus imágenes, que son una
  /// relación ansiosa—, pero el cliente solo se quedaba con el identificador y
  /// después buscaba el producto en el catálogo paginado de Descubrir. Eso hacía
  /// que una conversación no se pudiera dibujar hasta que el catálogo hubiera
  /// cargado la página donde estuviera ese producto, y que no se dibujara nunca
  /// si nadie visitaba Descubrir. Guardarlos aquí quita esa dependencia.
  final Product? product1Detail;
  final Product? product2Detail;
  /// Hasta cuándo leyó esta conversación quien pidió los datos.
  ///
  /// Viene del servidor, que lleva una marca por persona y conversación. Es
  /// `null` si nunca la abrió. Sustituye a la marca local que T-035 tuvo que
  /// usar cuando el servidor no tenía dónde anotarla, y por eso ahora los no
  /// leídos siguen a la persona entre dispositivos.
  final DateTime? lastReadAt;

  ChatExchange({
    required this.id,
    required this.owner1,
    required this.owner2,
    required this.product1,
    required this.product2,
    required this.requester1,
    required this.messages,
    required this.status,
    this.product1Detail,
    this.product2Detail,
    this.lastReadAt,
  });

  /// El producto con ese identificador, si la API lo trajo con el intercambio.
  Product? productoPorId(String productId) {
    if (productId == product1) return product1Detail;
    if (productId == product2) return product2Detail;
    return null;
  }

  /// El producto que aporta la persona indicada, si la API lo trajo.
  Product? productoDe(String userId) =>
      owner1 == userId ? product1Detail : product2Detail;

  /// El producto que aporta la otra persona, si la API lo trajo.
  Product? productoDeLaOtraPersona(String userId) =>
      owner1 == userId ? product2Detail : product1Detail;
}
