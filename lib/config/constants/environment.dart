import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static Future<void> initEnvironment() async {
    await dotenv.load(fileName: '.env');
  }

  static String get apiUrl => _requiredUrl('API_URL');

  static String get socketUrl {
    final configuredUrl = dotenv.env['SOCKET_URL']?.trim();
    if (configuredUrl != null && configuredUrl.isNotEmpty) return configuredUrl;

    final apiUri = Uri.parse(apiUrl);
    return apiUri.replace(path: '', query: null, fragment: null).toString();
  }

  static String _requiredUrl(String name) {
    final value = dotenv.env[name]?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('Falta configurar $name en el entorno.');
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('$name debe contener una URL absoluta válida.');
    }
    return value.replaceFirst(RegExp(r'/$'), '');
  }
}
