import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'cookie_jar.dart';

class NiniException implements Exception {
  NiniException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NiniFetch {
  const NiniFetch({required this.statusCode, required this.url, required this.bodyBytes});

  final int statusCode;
  final Uri url;
  final Uint8List bodyBytes;

  String get body => utf8.decode(bodyBytes, allowMalformed: true);
}

const niniUserAgent =
    'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36';

const niniOrigin = 'https://www.ninisite.com';

Uri niniPageUri(String path, int page) {
  final resolved = path.startsWith('http://') || path.startsWith('https://')
      ? Uri.parse(path)
      : Uri.parse(niniOrigin).resolve(path);
  if (page <= 1) return resolved;
  return resolved.replace(
    queryParameters: {
      ...resolved.queryParameters,
      'page': '$page',
    },
  );
}

class NiniClient {
  NiniClient({http.Client? httpClient, Map<String, String>? cookies})
    : _http = httpClient ?? http.Client(),
      _cookies = Map<String, String>.of(cookies ?? {});

  final http.Client _http;
  final Map<String, String> _cookies;
  void Function()? onCookiesChanged;

  Map<String, String> get cookies => Map.unmodifiable(_cookies);

  void restoreCookies(Map<String, String> cookies) {
    _cookies
      ..clear()
      ..addAll(cookies);
  }

  void clearCookies() => _cookies.clear();

  Future<String> get(String path, {int page = 1}) async {
    final response = await _send('GET', niniPageUri(path, page));
    if (response.statusCode != 200) throw NiniException('پاسخ سرور نامعتبر بود.');
    return response.body;
  }

  Future<Uint8List> getBytes(String path) async {
    final response = await _send('GET', niniPageUri(path, 1), accept: '*/*');
    if (response.statusCode != 200) throw NiniException('پاسخ سرور نامعتبر بود.');
    return response.bodyBytes;
  }

  Future<NiniFetch> postForm(String path, Map<String, String> fields, {String? referer}) {
    final uri = niniPageUri(path, 1);
    return _send(
      'POST',
      uri,
      form: fields,
      referer: referer ?? uri.toString(),
      accept: 'text/html,application/json,application/xhtml+xml',
    );
  }

  Future<NiniFetch> postJson(String path, {Object? jsonBody, String? referer}) {
    final uri = niniPageUri(path, 1);
    return _send(
      'POST',
      uri,
      rawBody: jsonBody == null ? null : utf8.encode(jsonEncode(jsonBody)),
      contentType: jsonBody == null ? null : 'application/json; charset=utf-8',
      referer: referer ?? '$niniOrigin/profile',
      accept: 'application/json, text/plain, */*',
    );
  }

  Future<NiniFetch> postMultipart(
    String path, {
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
    String? referer,
  }) async {
    final uri = niniPageUri(path, 1);
    final request = http.MultipartRequest('POST', uri)
      ..fields.addAll(fields)
      ..files.addAll(files);
    final bytes = await request.finalize().fold<List<int>>(<int>[], (previous, chunk) => previous..addAll(chunk));
    return _send(
      'POST',
      uri,
      rawBody: Uint8List.fromList(bytes),
      contentType: request.headers['content-type'],
      referer: referer ?? uri.toString(),
      accept: 'text/html,application/json,application/xhtml+xml',
    );
  }

  Future<NiniFetch> _send(
    String method,
    Uri uri, {
    Map<String, String>? form,
    Uint8List? rawBody,
    String? contentType,
    String? referer,
    String accept = 'text/html,application/xhtml+xml',
  }) async {
    try {
      final before = cookieHeader(_cookies);
      var currentMethod = method;
      var currentUri = uri;
      Map<String, String>? currentForm = form;
      Uint8List? currentRaw = rawBody;
      String? currentType = contentType;
      http.StreamedResponse response;
      Uint8List bytes = Uint8List(0);
      for (var hop = 0; hop < 6; hop++) {
        final request = http.Request(currentMethod, currentUri)
          ..followRedirects = false
          ..headers.addAll(
            _headers(
              accept: accept,
              referer: referer,
              origin: currentForm != null || currentRaw != null || currentMethod == 'POST',
            ),
          );
        if (currentForm != null) {
          request.bodyFields = currentForm;
        } else if (currentRaw != null) {
          request.bodyBytes = currentRaw;
          if (currentType != null) request.headers['Content-Type'] = currentType;
        }
        response = await _http.send(request).timeout(const Duration(seconds: 20));
        bytes = await response.stream.toBytes();
        final setCookie = response.headers['set-cookie'];
        storeSetCookieHeader(_cookies, setCookie);
        final location = response.headers['location'];
        // dart:io reports isRedirect false for a POST 302. A successful sign-in
        // is exactly that: 302 to /discussion.
        final redirecting =
            const {301, 302, 303, 307, 308}.contains(response.statusCode) &&
            location != null &&
            location.isNotEmpty;
        if (!redirecting) {
          if (cookieHeader(_cookies) != before) onCookiesChanged?.call();
          if (method == 'POST' && response.statusCode >= 500) {
            throw NiniException('پاسخ سرور نامعتبر بود.');
          }
          return NiniFetch(statusCode: response.statusCode, url: currentUri, bodyBytes: bytes);
        }
        final next = currentUri.resolve(location);
        final host = next.host;
        if (host.isNotEmpty && host != 'ninisite.com' && !host.endsWith('.ninisite.com')) break;
        final preserve = response.statusCode == 307 || response.statusCode == 308;
        currentUri = next;
        currentMethod = preserve ? currentMethod : 'GET';
        currentForm = preserve ? currentForm : null;
        currentRaw = preserve ? currentRaw : null;
        currentType = preserve ? currentType : null;
      }
      if (cookieHeader(_cookies) != before) onCookiesChanged?.call();
      return NiniFetch(statusCode: 302, url: currentUri, bodyBytes: bytes);
    } on NiniException {
      rethrow;
    } catch (_) {
      throw NiniException('ارتباط با نی‌نی‌سایت برقرار نشد.');
    }
  }

  Map<String, String> _headers({required String accept, String? referer, bool origin = false}) {
    return {
      'User-Agent': niniUserAgent,
      'Accept': accept,
      'Accept-Language': 'fa-IR,fa;q=0.9,en;q=0.5',
      if (_cookies.isNotEmpty) 'Cookie': cookieHeader(_cookies),
      'Referer': ?referer,
      if (origin) 'Origin': niniOrigin,
    };
  }
}
