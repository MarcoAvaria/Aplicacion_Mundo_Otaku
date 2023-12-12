//import 'package:aplicacion_mundo_otaku/features/products/infrastructure/errors/product_errors.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/datasources/chat_exchanges_datasource.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/infrastructure/errors/chat_exchange_errors.dart';
import 'package:aplicacion_mundo_otaku/features/chats/infrastructure/mappers/chat_exchange_mapper.dart';
import 'package:dio/dio.dart';
import 'package:aplicacion_mundo_otaku/config/config.dart';

class ChatExchangesDatasourceImpl extends ChatExchangeDatasource {
  late final Dio dio;
  final String accessToken;

  ChatExchangesDatasourceImpl({required this.accessToken})
      : dio = Dio(BaseOptions(
            baseUrl: Environment.apiUrl,
            headers: {'Authorization': 'Bearer $accessToken'}));

  @override
  Future<ChatExchange> createUpdateChatExchange(
      Map<String, dynamic> chatExchangeLike) async {
    try {
      final String? chatExchangeId = chatExchangeLike['id'];
      //print(productId);
      final String method = (chatExchangeId == null) ? 'POST' : 'PATCH';
      //print(method);
      final String url = (chatExchangeId == null)
          ? '/chat-exchanges'
          : '/chat-exchanges/$chatExchangeId';
      //print(url);

      chatExchangeLike.remove('id');
      chatExchangeLike.remove('status');
      //print('Request to API: $url, Method: $method, Data: $chatExchangeLike');

      final response = await dio.request(url,
          data: chatExchangeLike, options: Options(method: method));
      //print('API Response: $response');
      final chatExchange = ChatExchangeMapper.jsonToEntity(response.data);
      return chatExchange;
    } catch (e) {
      //print('Error in createUpdateChatExchange: $e');
      if (e is DioException && e.response != null) {
        //print('API Response Data: ${e.response!.data}');
        //print('API Response Headers: ${e.response!.headers}');
      }
      throw Exception();
    }
  }

  @override
  Future<ChatExchange> changeChatExchangeStatus(
      String id, String status) async {
    try {
      final response = await dio
          .patch('/chat-exchanges/$id/status', data: {'status': status});
      final chatExchange = ChatExchangeMapper.jsonToEntity(response.data);
      return chatExchange;
    } on DioException catch (e) {
      //print('DioException caught in changeChatExchangeStatus: ${e}');
      throw Exception(e);
    } catch (e) {
      //print('Error no capturado en changeChatExchangeStatus dentro de\ncreateUpdateChatExchange en\nChatExchangesDatasourceImpl');  
      throw Exception();
    }
  }

  @override
  Future<ChatExchange> getChatExchangeById(String id) async {
    try {
      final response = await dio.get('/chat-exchanges/$id');
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
    final response =
        await dio.get<List>('/chat-exchanges?limit=$limit&offset=$offset');
    final List<ChatExchange> chatExchanges = [];
    for (final chatExchange in response.data ?? []) {
      chatExchanges
          .add(ChatExchangeMapper.jsonToEntity(chatExchange)); // mapper
    }
    return chatExchanges;
  }

  @override
  Future<List<ChatExchange>> getAllChatExchanges() async {
    try {
      final response = await dio.get<List<dynamic>>('/chat-exchanges');

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

  @override
  Future<List<ChatExchange>> searchChatExchangeByTerm(String term) {
    throw UnimplementedError();
  }
}
