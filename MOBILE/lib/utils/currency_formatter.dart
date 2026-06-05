String formatVnd(num amount) {
  final value = amount.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    final remaining = value.length - i;
    buffer.write(value[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${buffer.toString()} đ';
}
