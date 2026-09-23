import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchange_provider.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/widgets/widgets.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ink_exchange_list_screen.dart' show ExchangeInbox;

/// La propuesta de intercambio, contada como la doble página de un tomo:
/// lo que entregas arriba, lo que recibes abajo.
///
/// Conserva el comportamiento de `PreviewReceivedScreen` y
/// `PreviewRequestedScreen`, incluidos los estados que se envían a la API:
/// `rejected` e `inProgress` al responder, `abort` al cancelar la propia.
class InkExchangePreviewScreen extends ConsumerWidget {
  const InkExchangePreviewScreen({
    super.key,
    required this.chatExchangeId,
    required this.inbox,
  });

  final String chatExchangeId;
  final ExchangeInbox inbox;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = InkTokens.of(context);
    final state = ref.watch(chatExchangeProvider(chatExchangeId));
    final chatExchange = state.chatExchange;

    return Scaffold(
      backgroundColor: tokens.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(tokens: tokens, inbox: inbox),
            Expanded(
              child: state.isLoading
                  ? const FullScreenLoader()
                  : state.errorMessage.isNotEmpty && chatExchange == null
                      ? ListStatusView(
                          message: state.errorMessage,
                          onRetry: () => ref
                              .read(
                                  chatExchangeProvider(chatExchangeId).notifier)
                              .loadChatExchange(),
                        )
                      : chatExchange == null
                          ? const ListStatusView(
                              message: 'La solicitud ya no está disponible.',
                            )
                          : _Spread(
                              tokens: tokens,
                              inbox: inbox,
                              chatExchange: chatExchange,
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.tokens, required this.inbox});

  final InkTokens tokens;
  final ExchangeInbox inbox;

  @override
  Widget build(BuildContext context) {
    final isReceived = inbox == ExchangeInbox.received;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Volver',
            child: Material(
              color: tokens.panel,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: tokens.ink, width: 2.5),
                  ),
                  child: Icon(Icons.arrow_back, size: 19, color: tokens.text),
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReceived ? 'TE PROPONEN' : 'PROPUSISTE',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: tokens.halftone,
                  ),
                ),
                Text(
                  'Un intercambio',
                  style: AppFonts.displayStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    color: tokens.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Spread extends ConsumerStatefulWidget {
  const _Spread({
    required this.tokens,
    required this.inbox,
    required this.chatExchange,
  });

  final InkTokens tokens;
  final ExchangeInbox inbox;
  final ChatExchange chatExchange;

  @override
  ConsumerState<_Spread> createState() => _SpreadState();
}

class _SpreadState extends ConsumerState<_Spread> {
  late Future<List<Product>> _productsFuture;

  InkTokens get tokens => widget.tokens;
  ChatExchange get chatExchange => widget.chatExchange;

  @override
  void initState() {
    super.initState();
    _productsFuture = _loadProducts();
  }

  Future<List<Product>> _loadProducts() async {
    final repository = ref.read(productsRepositoryProvider);
    final product1 = await repository.getProductById(chatExchange.product1);
    final product2 = await repository.getProductById(chatExchange.product2);
    return [product1, product2];
  }

  void _retry() => setState(() => _productsFuture = _loadProducts());

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProvider).user?.id ?? '';

    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const FullScreenLoader();
        }
        if (snapshot.hasError) {
          return ListStatusView(
            message: 'No fue posible cargar los productos de la solicitud.',
            onRetry: _retry,
          );
        }
        if (!snapshot.hasData) {
          return const ListStatusView(
            message: 'Los productos de la solicitud ya no están disponibles.',
          );
        }

        final products = snapshot.data!;
        final first = products.first;
        final mine = first.user?.id == userId ? first : products.last;
        final theirs = first.user?.id == userId ? products.last : first;

        return Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
                children: [
                  _Panel(
                    tokens: tokens,
                    product: mine,
                    caption: 'TÚ ENTREGAS',
                    number: '01',
                    tiltDegrees: -0.7,
                  ),
                  _Seam(tokens: tokens),
                  _Panel(
                    tokens: tokens,
                    product: theirs,
                    caption: 'TÚ RECIBES',
                    number: '02',
                    tiltDegrees: 0.8,
                    highlighted: true,
                  ),
                ],
              ),
            ),
            _Actions(
              tokens: tokens,
              inbox: widget.inbox,
              exchangeId: chatExchange.id,
            ),
          ],
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.tokens,
    required this.product,
    required this.caption,
    required this.number,
    required this.tiltDegrees,
    this.highlighted = false,
  });

  final InkTokens tokens;
  final Product product;
  final String caption;
  final String number;
  final double tiltDegrees;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (product.tomo > 0) 'Tomo ${product.tomo}',
      for (final value in [product.demographic, product.gender])
        if (value.trim().isNotEmpty && value.trim().toLowerCase() != 'ninguno')
          productOptionLabel(value.trim()),
    ];

    return Transform.rotate(
      angle: tiltDegrees * 0.0174532925,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: tokens.shadow, offset: const Offset(4, 4)),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: tokens.panel,
            border: Border.all(color: tokens.ink, width: tokens.borderWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: highlighted ? tokens.chipSelected : tokens.ink,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      caption,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        // `onInk`, no `paper`: esta barra usa `ink` de fondo,
                        // que es oscuro en los dos modos. `paper` servía en
                        // claro y en oscuro dejaba el rótulo casi invisible.
                        color: highlighted
                            ? tokens.chipSelectedText
                            : tokens.onInk,
                      ),
                    ),
                    Text(
                      number,
                      style: AppFonts.displayStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        // Mismo caso que el rótulo: va sobre la barra `ink`.
                        color: highlighted
                            ? tokens.chipSelectedText
                            : tokens.onInk,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 84,
                      height: 104,
                      decoration: BoxDecoration(
                        color: tokens.avatarWash,
                        border: Border.all(
                          color: tokens.ink,
                          width: tokens.borderWidth,
                        ),
                      ),
                      child: product.images.isEmpty
                          ? Image.asset(
                              'assets/images/no-image.jpg',
                              fit: BoxFit.cover,
                            )
                          : FadeInImage(
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 200),
                              image: imageProviderForPath(product.images.first),
                              placeholder: const AssetImage(
                                'assets/images/no-image.jpg',
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.displayStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              color: tokens.text,
                            ),
                          ),
                          if (details.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              details.join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: tokens.muted,
                              ),
                            ),
                          ],
                          if (product.user?.fullName.trim().isNotEmpty ??
                              false) ...[
                            const SizedBox(height: 9),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: tokens.ink, width: 2),
                              ),
                              child: Text(
                                product.user!.fullName.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: tokens.text,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El pliegue entre las dos viñetas.
class _Seam extends StatelessWidget {
  const _Seam({required this.tokens});

  final InkTokens tokens;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              for (var index = 0; index < 22; index++) ...[
                Expanded(
                  child: Container(height: 3, color: tokens.ink),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.chipSelected,
              shape: BoxShape.circle,
              border: Border.all(color: tokens.ink, width: 2.5),
            ),
            child: Icon(
              Icons.swap_horiz_rounded,
              size: 24,
              color: tokens.chipSelectedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({
    required this.tokens,
    required this.inbox,
    required this.exchangeId,
  });

  final InkTokens tokens;
  final ExchangeInbox inbox;
  final String exchangeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReceived = inbox == ExchangeInbox.received;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      decoration: BoxDecoration(
        color: tokens.paper,
        border: Border(top: BorderSide(color: tokens.ink, width: 2)),
      ),
      child: isReceived
          ? Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _ActionButton(
                    tokens: tokens,
                    label: 'Rechazar',
                    filled: false,
                    onTap: () => _update(
                      context,
                      ref,
                      'rejected',
                      'Se ha rechazado la solicitud',
                      'No fue posible rechazar la solicitud.',
                      confirmacion: const _Confirmacion(
                        titulo: '¿Rechazar la propuesta?',
                        mensaje: 'La otra persona tendrá que proponerte el '
                            'intercambio de nuevo si cambias de opinión.',
                        etiqueta: 'Sí, rechazar',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  flex: 3,
                  child: _ActionButton(
                    tokens: tokens,
                    label: 'Aceptar el cambio',
                    filled: true,
                    onTap: () => _update(
                      context,
                      ref,
                      'inProgress',
                      '¡Acción completada con éxito!',
                      'No fue posible aceptar la solicitud.',
                      confirmacion: const _Confirmacion(
                        titulo: '¿Aceptar el intercambio?',
                        mensaje: 'Se le avisará a la otra persona y se abrirá '
                            'el chat para que se pongan de acuerdo. Para '
                            'deshacerlo tendrías que cancelar el intercambio '
                            'desde ahí.',
                        etiqueta: 'Sí, aceptar',
                      ),
                    ),
                  ),
                ),
              ],
            )
          : _ActionButton(
              tokens: tokens,
              label: 'Cancelar la propuesta',
              filled: false,
              onTap: () => _update(
                context,
                ref,
                'abort',
                'Se ha cancelado la solicitud',
                'No fue posible cancelar la solicitud.',
                confirmacion: const _Confirmacion(
                  titulo: '¿Cancelar la propuesta?',
                  mensaje: 'Se retirará de las solicitudes de la otra persona. '
                      'Si te arrepientes, tendrás que proponerla otra vez.',
                  etiqueta: 'Sí, cancelar',
                ),
              ),
            ),
    );
  }

  /// Cambia el estado del intercambio, preguntando siempre antes.
  ///
  /// Las tres acciones mueven el `status` de la entidad `ChatExchange`, y ese
  /// cambio le llega a la otra persona. Ninguna se deshace retrocediendo: hay
  /// que emitir **otra** transición, que la otra persona también verá. Por eso
  /// las tres preguntan, incluida aceptar.
  ///
  /// Aceptar estuvo un rato sin preguntar, con el argumento de que era el
  /// camino constructivo y se podía cancelar después desde el chat. El
  /// argumento era flojo: estos botones quedan juntos y es fácil rozar el que
  /// no era, y "se puede deshacer" no es lo mismo que "sale gratis deshacerlo"
  /// cuando deshacerlo implica avisarle de nuevo a la otra persona.
  Future<void> _update(
    BuildContext context,
    WidgetRef ref,
    String status,
    String successMessage,
    String failureMessage, {
    _Confirmacion? confirmacion,
  }) async {
    if (confirmacion != null) {
      final sigue = await confirmarAccion(
        context,
        titulo: confirmacion.titulo,
        mensaje: confirmacion.mensaje,
        etiquetaConfirmar: confirmacion.etiqueta,
        etiquetaVolver: 'Volver',
      );
      if (!sigue || !context.mounted) return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final wasUpdated = await ref
        .read(chatExchangeProvider(exchangeId).notifier)
        .updateChatExchangeStatus(status);

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(content: Text(wasUpdated ? successMessage : failureMessage)),
    );

    if (!wasUpdated) return;

    // La solicitud dejó de estar pendiente, así que ya no pertenece a esta
    // pantalla. Se vuelve a la bandeja, que se recarga sola al recibir el
    // control (`ExchangeListRefresh.pushAndRefresh`).
    if (navigator.canPop()) navigator.pop();
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.tokens,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final InkTokens tokens;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = Material(
      color: filled ? tokens.accent : tokens.panel,
      shape: Border.all(color: tokens.ink, width: 2.5),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: filled ? tokens.onAccent : tokens.text,
            ),
          ),
        ),
      ),
    );

    // Sin esto el control queda como texto tocable y no como botón, que es lo
    // que anuncia un lector de pantalla y lo que busca el recorrido Playwright.
    // El nombre lo aporta el texto del propio botón.
    if (!filled) return Semantics(button: true, child: content);

    return Semantics(
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: tokens.shadow, offset: const Offset(4, 4)),
          ],
        ),
        child: content,
      ),
    );
  }
}

/// Los textos de una confirmación, para no pasar cuatro cadenas sueltas.
class _Confirmacion {
  const _Confirmacion({
    required this.titulo,
    required this.mensaje,
    required this.etiqueta,
  });

  final String titulo;
  final String mensaje;

  /// Texto del botón que confirma. Nombra la acción ("Rechazar") en vez de
  /// decir "Aceptar", que aquí se confundiría con aceptar el intercambio.
  final String etiqueta;
}
