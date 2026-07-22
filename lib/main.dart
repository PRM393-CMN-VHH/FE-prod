import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:prm393/app/app.dart';
import 'package:prm393/core/network/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load();
  } catch (_) {
    // .env is optional (gitignored, per-developer) — fall back silently.
  }
  debugPrint('[API] Connecting to the backend: ${ApiService.backendBaseUrl}');
  await ApiService().initializeSupabase(url: '', anonKey: '');

  runApp(const FlowerShopApp());
}
