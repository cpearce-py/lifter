import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

extension CacheFor on Ref {
  /// Keeps an autoDispose provider alive for [duration] after its last
  /// listener goes away, so flicking back to it is instant instead of a
  /// reload. Listening again within that window cancels the countdown.
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Timer? timer;

    onCancel(() => timer = Timer(duration, link.close));
    onResume(() => timer?.cancel());
    onDispose(() => timer?.cancel());
  }
}
