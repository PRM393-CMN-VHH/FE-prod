import 'dart:async';
import 'package:flutter/material.dart';

class ToastProvider extends ChangeNotifier {
  String? _message;
  bool _isError = false;
  Timer? _timer;

  String? get message => _message;
  bool get isError => _isError;

  void show(String message, {bool isError = false, int durationSeconds = 3}) {
    _timer?.cancel();
    _message = message;
    _isError = isError;
    notifyListeners();

    _timer = Timer(Duration(seconds: durationSeconds), () {
      _message = null;
      notifyListeners();
    });
  }

  void clear() {
    _timer?.cancel();
    _message = null;
    notifyListeners();
  }
}
