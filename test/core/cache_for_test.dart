import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifter/core/providers/cache_for.dart';

void main() {
  late int builds;
  late Provider<int> provider;

  setUp(() {
    builds = 0;
    provider = Provider.autoDispose<int>((ref) {
      ref.cacheFor(const Duration(seconds: 30));
      return ++builds;
    });
  });

  test('coming back within the window reuses the value', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      container.listen(provider, (_, _) {}).close();
      async.elapse(const Duration(seconds: 10));

      container.listen(provider, (_, _) {});
      expect(builds, 1);

      // Still listened to, so the original timer must not dispose it.
      async.elapse(const Duration(seconds: 60));
      expect(container.read(provider), 1);
      container.dispose();
    });
  });

  test('the value is dropped once the window passes', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      container.listen(provider, (_, _) {}).close();
      async.elapse(const Duration(seconds: 31));

      container.listen(provider, (_, _) {});
      expect(builds, 2);
      container.dispose();
    });
  });
}
