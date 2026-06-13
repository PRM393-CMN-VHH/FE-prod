import 'package:flutter/foundation.dart';

final paidOrdersRefreshSignal = ValueNotifier<int>(0);

void requestPaidOrdersView() {
  paidOrdersRefreshSignal.value++;
}
