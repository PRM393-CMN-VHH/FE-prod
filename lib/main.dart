import 'package:flutter/material.dart';
import 'package:prm393/app/app.dart';
import 'package:prm393/core/network/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().initializeSupabase(url: '', anonKey: '');

  runApp(const FlowerShopApp());
}
