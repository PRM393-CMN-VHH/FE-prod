import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prm393/core/utils/error_translator.dart';
import 'package:prm393/core/network/api_endpoints.dart';

export 'package:prm393/core/network/api_endpoints.dart';

/// Shared HTTP plumbing: base URL, session cookie, generic verbs and error
/// handling. Feature-specific endpoints/methods live in sibling `*_api.dart`
/// mixins (auth_api.dart, catalog_api.dart, ...) that build on top of this.
class ApiClientBase {
  static const Duration apiTimeout = Duration(seconds: 10);

  // ==========================================
  // API CONFIG — single place to configure the backend host.
  //
  // Backend host comes from (in priority order):
  //   1. --dart-define=API_BASE_URL=... passed to `flutter run`/`flutter build`
  //   2. API_BASE_URL in the gitignored .env file at the project root
  //      (copy .env.example -> .env and put your own machine's LAN IP there —
  //      each developer keeps their own, so this never needs a source edit)
  //   3. _fallbackLanIp below, if neither of the above is set
  // ==========================================

  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  static const String _fallbackLanIp = '192.168.1.10';
  static const int _port = 3636;

  static String get backendBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    final fromEnv = dotenv.maybeGet('API_BASE_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost:$_port';
    return 'http://$_fallbackLanIp:$_port';
  }

  static final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();
  static Stream<void> get onSessionExpired => _sessionExpiredController.stream;

  SupabaseClient? _supabase;
  bool get isSupabaseInitialized => _supabase != null;

  String? _sessionCookie;

  /// Resolves a path (e.g. "/order/pay/1") or a full URL against the
  /// backend base URL. Full URLs (already carrying a scheme) pass through.
  String backendUrl(String pathOrUrl) {
    final uri = Uri.tryParse(pathOrUrl);
    if (uri != null && uri.hasScheme) {
      return pathOrUrl;
    }
    final path = pathOrUrl.startsWith('/') ? pathOrUrl : '/$pathOrUrl';
    return "$backendBaseUrl$path";
  }

  // The session cookie carrying auth, needed by REST calls and to
  // authenticate the chat WebSocket handshake.
  Future<String?> getSessionCookie() async {
    if (_sessionCookie == null) {
      final prefs = await SharedPreferences.getInstance();
      _sessionCookie = prefs.getString('session_cookie');
    }
    return _sessionCookie;
  }

  Future<void> clearSessionCookie() async {
    _sessionCookie = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_cookie');
  }

  void _updateCookie(http.Response response) {
    final rawCookie =
        response.headers['set-cookie'] ?? response.headers['Set-Cookie'];
    if (rawCookie != null) {
      final index = rawCookie.indexOf(';');
      _sessionCookie = (index == -1)
          ? rawCookie
          : rawCookie.substring(0, index);
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('session_cookie', _sessionCookie!);
      });
    }
  }

  // Initialize Supabase. If credentials fail or are empty, fall back silently.
  Future<void> initializeSupabase({String? url, String? anonKey}) async {
    if (url != null &&
        anonKey != null &&
        url.isNotEmpty &&
        anonKey.isNotEmpty) {
      try {
        await Supabase.initialize(url: url, anonKey: anonKey);
        _supabase = Supabase.instance.client;
      } catch (e) {
        _supabase = null;
      }
    }
  }

  /// Builds the full URL for an [Endpoint]: substitutes `{param}` tokens in
  /// its path from [params], then appends [query] as a query string.
  String urlFor(Endpoint endpoint, {Map<String, dynamic>? params, Map<String, String>? query}) {
    var path = endpoint.path;
    params?.forEach((key, value) {
      path = path.replaceAll('{$key}', Uri.encodeComponent(value.toString()));
    });
    var url = backendUrl(path);
    if (query != null && query.isNotEmpty) {
      url = Uri.parse(url).replace(queryParameters: query).toString();
    }
    return url;
  }

  /// Dispatches an [Endpoint] using its declared HTTP method, so callers
  /// don't have to know/repeat which verb each backend route expects — that
  /// pairing lives once, in api_endpoints.dart.
  Future<dynamic> request(
    Endpoint endpoint, {
    Map<String, dynamic>? params,
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) {
    final url = urlFor(endpoint, params: params, query: query);
    switch (endpoint.method) {
      case ApiVerb.get:
        return getRequest(url);
      case ApiVerb.post:
        return body != null ? postRequest(url, body) : postEmptyRequest(url);
      case ApiVerb.put:
        return putRequest(url, body ?? const {});
      case ApiVerb.delete:
        return deleteRequest(url);
    }
  }

  // ==========================================
  // GENERIC HTTP CRUD UTILITIES
  // ==========================================

  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_sessionCookie == null) {
      final prefs = await SharedPreferences.getInstance();
      _sessionCookie = prefs.getString('session_cookie');
    }
    if (_sessionCookie != null) {
      headers['Cookie'] = _sessionCookie!;
    }
    return headers;
  }

  Future<http.Response> _rawGetRequest(String url) async {
    final headers = await _getHeaders();
    return await http.get(Uri.parse(url), headers: headers).timeout(apiTimeout);
  }

  Future<dynamic> getRequest(String url) async {
    try {
      final response = await _rawGetRequest(url);
      return _processResponse(response);
    } catch (e) {
      throw Exception(friendlyRequestError(e));
    }
  }

  Future<dynamic> postRequest(String url, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(apiTimeout);
      return _processResponse(response);
    } catch (e) {
      throw Exception(friendlyRequestError(e));
    }
  }

  Future<dynamic> postEmptyRequest(String url) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(Uri.parse(url), headers: headers).timeout(apiTimeout);
      return _processResponse(response);
    } catch (e) {
      throw Exception(friendlyRequestError(e));
    }
  }

  Future<dynamic> putRequest(String url, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(apiTimeout);
      return _processResponse(response);
    } catch (e) {
      throw Exception(friendlyRequestError(e));
    }
  }

  Future<dynamic> deleteRequest(String url) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(Uri.parse(url), headers: headers).timeout(apiTimeout);
      return _processResponse(response);
    } catch (e) {
      throw Exception(friendlyRequestError(e));
    }
  }

  dynamic _processResponse(http.Response response) {
    _updateCookie(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      if (response.statusCode == 401) {
        final requestPath = response.request?.url.path;
        if (requestPath == null || !requestPath.endsWith('/logout')) {
          _sessionExpiredController.add(null);
        }
      }
      String msg = "HTTP Error ${response.statusCode}";
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          msg =
              decoded['message'] ??
              decoded['error'] ??
              decoded['phoneNumberExist'] ??
              msg;
        } else if (decoded is List && decoded.isNotEmpty) {
          msg = decoded.first.toString();
        }
      } catch (_) {}
      throw Exception(ErrorTranslator.userMessage(msg));
    }
  }

  String friendlyRequestError(Object error) {
    var raw = error.toString();
    raw = raw.replaceFirst(RegExp(r'^Exception:\s*'), '');
    raw = raw.replaceFirst(
      RegExp(r'^(GET|POST|PUT|DELETE) Request failed:\s*'),
      '',
    );
    raw = raw.replaceFirst(RegExp(r'^Exception:\s*'), '');
    if (raw.contains('SocketException') ||
        raw.contains('Connection refused') ||
        raw.contains('Failed host lookup') ||
        raw.contains('Network is unreachable')) {
      return ErrorTranslator.userMessage(raw);
    }
    if (raw.contains('ClientException')) {
      return ErrorTranslator.userMessage(raw);
    }
    return ErrorTranslator.userMessage(raw);
  }
}
