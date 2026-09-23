import 'dart:async';

import 'package:aplicacion_mundo_otaku/features/auth/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchanges_provider.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/shared/infrastructure/services/socket_service.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vuelve a pedir a la API los intercambios y los productos que los acompañan.
///
/// Las tres listas (Enviadas, Recibidas y Chats) muestran intercambios, pero
/// resuelven el título y la portada contra `productsProvider`, así que un
/// refresco que solo trajera los intercambios dejaría las tarjetas con datos
/// viejos. Las dos peticiones salen en paralelo.
Future<void> refreshExchangeData(WidgetRef ref, String userId) async {
  if (userId.isEmpty) return;

  await Future.wait([
    ref.read(chatExchangesProvider.notifier).loadAllChatExchanges(userId),
    ref.read(productsProvider.notifier).reloadLoadedPages(),
  ]);
}

/// Refresco manual y automático de una lista de intercambios.
///
/// Reúne los tres disparadores que no son el gesto de arrastrar: reanudar la
/// aplicación, volver desde una pantalla hija y el reintento tras un error.
mixin ExchangeListRefresh<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  AppLifecycleListener? _lifecycleListener;
  StreamSubscription<ExchangeActivity>? _activitySubscription;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Al volver desde segundo plano puede haber respuestas nuevas de la otra
    // persona: es el momento natural para ponerse al día.
    _lifecycleListener = AppLifecycleListener(onResume: refreshExchanges);
    // Y mientras la lista está a la vista, el servidor avisa por su cuenta.
    //
    // Engancharlo aquí, en el mixin, cubre Chats, Enviadas y Recibidas de una
    // vez: las tres ya lo comparten para el resto de sus refrescos. El aviso
    // solo dice que algo pasó; los datos se vuelven a pedir por el camino
    // normal, que es el que comprueba permisos.
    _activitySubscription = SocketService.instance.exchangeActivity.listen(
      (_) => refreshExchanges(),
    );
  }

  @override
  void dispose() {
    _activitySubscription?.cancel();
    _lifecycleListener?.dispose();
    super.dispose();
  }

  String get currentUserId => ref.read(authProvider).user?.id ?? '';

  /// Recarga evitando que dos gestos seguidos disparen peticiones encimadas.
  Future<void> refreshExchanges() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      await refreshExchangeData(ref, currentUserId);
    } finally {
      _isRefreshing = false;
    }
  }

  /// Abre una pantalla hija y se pone al día al volver de ella.
  Future<void> pushAndRefresh(Future<Object?> navigation) async {
    await navigation;
    if (!mounted) return;
    await refreshExchanges();
  }
}

/// Envuelve el contenido de una lista con el gesto de arrastrar para refrescar.
///
/// El hijo tiene que poder desplazarse siempre, incluso cuando cabe entero en
/// pantalla; si no, el gesto no existe justo cuando más se necesita, que es con
/// la bandeja vacía.
class ExchangeRefreshIndicator extends StatelessWidget {
  const ExchangeRefreshIndicator({
    super.key,
    required this.tokens,
    required this.onRefresh,
    required this.child,
  });

  final InkTokens tokens;
  final Future<void> Function() onRefresh;
  final Widget child;

  static const ScrollPhysics physics =
      AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: tokens.halftone,
      backgroundColor: tokens.panel,
      child: child,
    );
  }
}

/// Deja un mensaje de estado dentro de un desplazamiento, para que el gesto de
/// refrescar siga disponible aunque la lista esté vacía o con error.
class ScrollableStatus extends StatelessWidget {
  const ScrollableStatus({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: ExchangeRefreshIndicator.physics,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }
}

Widget? buildExchangeListStatus({
  required WidgetRef ref,
  required String userId,
  required ChatExchangesState exchangesState,
  required ProductsState productsState,
  required bool isEmpty,
  bool waitingForProducts = false,
  required String emptyMessage,
}) {
  if ((exchangesState.isLoading ||
          productsState.isLoading ||
          waitingForProducts) &&
      isEmpty) {
    return const ListStatusView(
      message: 'Cargando intercambios...',
      isLoading: true,
    );
  }

  final errorMessage = exchangesState.errorMessage.isNotEmpty
      ? exchangesState.errorMessage
      : productsState.errorMessage;
  if (errorMessage.isNotEmpty && isEmpty) {
    return ListStatusView(
      message: errorMessage,
      onRetry: () {
        if (exchangesState.errorMessage.isNotEmpty) {
          ref.read(chatExchangesProvider.notifier).loadAllChatExchanges(userId);
        }
        if (productsState.errorMessage.isNotEmpty) {
          ref.read(productsProvider.notifier).reloadLoadedPages();
        }
      },
    );
  }

  if (isEmpty) return ListStatusView(message: emptyMessage);
  return null;
}

class ProductListAvatar extends StatelessWidget {
  final Product product;

  const ProductListAvatar({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundImage:
          product.images.isEmpty ? null : NetworkImage(product.images.first),
      child: product.images.isEmpty
          ? const Icon(Icons.inventory_2_outlined)
          : null,
    );
  }
}
