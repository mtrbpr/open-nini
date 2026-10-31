import 'dart:convert';

import 'package:http/http.dart' as http;

class NiniException implements Exception {
  NiniException(this.message);

  final String message;

  @override
  String toString() => message;
}

const niniUserAgent =
    'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36';

Uri niniPageUri(String path, int page) {
  final resolved = path.startsWith('http://') || path.startsWith('https://')
      ? Uri.parse(path)
      : Uri.parse('https://www.ninisite.com').resolve(path);
  if (page <= 1) return resolved;
  return resolved.replace(
    queryParameters: {
      ...resolved.queryParameters,
      'page': '$page',
    },
  );
}

class NiniClient {
  NiniClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<String> get(String path, {int page = 1}) async {
    final uri = niniPageUri(path, page);
    try {
      final response = await _http
          .get(
            uri,
            headers: const {
              'User-Agent': niniUserAgent,
              'Accept': 'text/html,application/xhtml+xml',
              'Accept-Language': 'fa-IR,fa;q=0.9,en;q=0.5',
            },
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw NiniException('پاسخ سرور نامعتبر بود.');
      }
      return utf8.decode(response.bodyBytes, allowMalformed: true);
    } on NiniException {
      rethrow;
    } catch (_) {
      throw NiniException('ارتباط با نی‌نی‌سایت برقرار نشد.');
    }
  }
}
