import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aplicacion_mundo_otaku/features/chats/domain/repositories/chat_exchanges_repository.dart';
import 'package:aplicacion_mundo_otaku/features/chats/infrastructure/datasources/chat_exchanges_datasource_impl.dart';
import 'package:aplicacion_mundo_otaku/features/chats/infrastructure/repositories/chat_exchange_repository_impl.dart';
import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';

final chatExchangesRepositoryProvider = Provider<ChatExchangesRepository>((ref) {

  final accessToken = ref.watch( authProvider ).user?.token ?? '';

  final chatExchangesRepository = ChatExchangesRepositoryImpl(
    ChatExchangesDatasourceImpl( accessToken: accessToken )
  );
  return chatExchangesRepository;
});