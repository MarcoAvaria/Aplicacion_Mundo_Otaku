import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static const _compiledApiUrl = String.fromEnvironment('API_URL');
  static const _compiledSocketUrl = String.fromEnvironment('SOCKET_URL');

  static Future<void> initEnvironment() async {
    await dotenv.load(fileName: '.env');
  }

  static String get apiUrl => _requiredUrl('API_URL');

  static String get socketUrl {
    final configuredUrl = _compiledSocketUrl.trim().isNotEmpty
        ? _compiledSocketUrl.trim()
        : dotenv.env['SOCKET_URL']?.trim();
    if (configuredUrl != null && configuredUrl.isNotEmpty) return configuredUrl;

    // Se construye el origen desde cero en vez de recortar con `replace`.
    // `Uri.replace(query: null)` **no borra** la consulta: en Dart, pasar
    // `null` significa "conserva lo que había", así que un `API_URL` con
    // parámetros dejaba el socket apuntando a `https://servidor?clave=1`.
    final apiUri = Uri.parse(apiUrl);
    return Uri(
      scheme: apiUri.scheme,
      host: apiUri.host,
      port: apiUri.hasPort ? apiUri.port : null,
    ).toString();
  }

  static String _requiredUrl(String name) {
    final compiledValue = name == 'API_URL' ? _compiledApiUrl.trim() : '';
    final value =
        compiledValue.isNotEmpty ? compiledValue : dotenv.env[name]?.trim();
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
