import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ligaduck/app/service/cache_service.dart';

void main() {
  test('joins concurrent requests with the same key', () async {
    final cache = CacheService();
    final completer = Completer<String>();
    var loadCount = 0;

    final first = cache.getOrJoin('concurrent-test', () {
      loadCount++;
      return completer.future;
    });
    final second = cache.getOrJoin('concurrent-test', () {
      loadCount++;
      return Future.value('unexpected');
    });

    expect(loadCount, 1);
    completer.complete('result');

    expect(await first, 'result');
    expect(await second, 'result');
  });

  test('removes failed requests so a later request can retry', () async {
    final cache = CacheService();

    await expectLater(
      cache.getOrJoin<String>(
        'retry-test',
        () => Future.error(StateError('failed')),
      ),
      throwsA(isA<StateError>()),
    );

    expect(
      await cache.getOrJoin('retry-test', () async => 'recovered'),
      'recovered',
    );
  });
}
