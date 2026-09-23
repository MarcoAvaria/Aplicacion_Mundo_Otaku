import 'package:aplicacion_mundo_otaku/features/chats/domain/datasources/chat_exchanges_datasource.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/infrastructure/errors/chat_exchange_errors.dart';
import 'package:aplicacion_mundo_otaku/features/chats/infrastructure/mappers/chat_exchange_mapper.dart';
import 'package:dio/dio.dart';
import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/shared/infrastructure/services/token_interceptor.dart';

class ChatExchangesDatasourceImpl extends ChatExchangeDatasource {
  late final Dio dio;
  final String accessToken;

  ChatExchangesDatasourceImpl({
    required this.accessToken,
    UnauthorizedCallback? onUnauthorized,
  }) : dio = Dio(BaseOptions(
            baseUrl: Environment.apiUrl,
            headers: {'Authorization': 'Bearer $accessToken'})) {
    if (accessToken.isNotEmpty && onUnauthorized != null) {
      dio.interceptors.add(UnauthorizedInterceptor(onUnauthorized));
    }
  }

  @override
  Future<ChatExchange> createChatExchange(
      Map<String, dynamic> chatExchangeLike) async {
    try {
      final response = await dio.post(
        ApiEndpoints.chatExchanges,
        data: chatExchangeLike,
      );
      return ChatExchangeMapper.jsonToEntity(response.data);
    } catch (_) {
      throw Exception();
    }
  }

  @override
  Future<ChatExchange> changeChatExchangeStatus(
      String id, String status) async {
    try {
      final response = await dio.patch(
        ApiEndpoints.chatExchangeStatus(id),
        data: {'status': status},
      );
      final chatExchange = ChatExchangeMapper.jsonToEntity(response.data);
      return chatExchange;
    } on DioException catch (e) {
      throw Exception(e);
    } catch (_) {
      throw Exception();
    }
  }

  @override
  Future<void> markChatExchangeAsRead(String id) async {
    try {
      await dio.patch(ApiEndpoints.chatExchangeRead(id));
    } on DioException catch (_) {
      // A propósito, en silencio. La marca local ya dejó el contador en cero y
      // el servidor se pone al día la próxima vez que se abra la conversación.
      // Interrumpir a alguien porque no se pudo anotar que leyó sería peor que
      // el problema.
    }
  }

  @override
  Future<ChatExchange> getChatExchangeById(String id) async {
    try {
      final response = await dio.get(ApiEndpoints.chatExchange(id));
      final chatExchange = ChatExchangeMapper.jsonToEntity(response.data);
      return chatExchange;
    } on DioException catch (e) {
      if (e.response!.statusCode == 404) throw ChatExchangeNotFound();
      throw Exception();
    } catch (e) {
      throw Exception();
    }
  }

  @override
  Future<List<ChatExchange>> getChatExchangeByPage(
      {int limit = 10, int offset = 0}) async {
    final response = await dio.get<List>(
      ApiEndpoints.chatExchanges,
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final List<ChatExchange> chatExchanges = [];
    for (final chatExchange in response.data ?? []) {
      chatExchanges.add(ChatExchangeMapper.jsonToEntity(chatExchange));
    }
    return chatExchanges;
  }

  @override
  Future<List<ChatExchange>> getAllChatExchanges(String id) async {
    try {
      final response =
          await dio.get<List<dynamic>>(ApiEndpoints.chatExchangesForUser(id));
      final List<ChatExchange> allChatExchanges = List<ChatExchange>.from(
        (response.data ?? []).map((dynamic productJson) {
          return ChatExchangeMapper.jsonToEntity(
              productJson as Map<String, dynamic>);
        }),
      );
      return allChatExchanges;
    } catch (e) {
      throw Exception();
    }
  }
}
