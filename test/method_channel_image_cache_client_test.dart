import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_cache_plugin/image_cache_plugin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.tieorange.image_cache_plugin/methods');
  const client = MethodChannelImageCacheClient(channel: channel);

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('parses a successful native load result', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'loadImage');
          expect(call.arguments, {'url': 'https://example.com/a.png'});
          return {
            'path': '/cache/a.img',
            'source': 'network',
            'cachedAtMilliseconds': 123,
          };
        });

    final result = await client.loadImage('https://example.com/a.png');

    expect(result.path, '/cache/a.img');
    expect(result.source, ImageCacheSource.network);
    expect(result.cachedAtMilliseconds, 123);
  });

  test('rejects a malformed result', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => {'path': ''});

    await expectLater(
      client.loadImage('https://example.com/a.png'),
      throwsA(
        isA<ImageCacheException>().having(
          (error) => error.code,
          'code',
          ImageCacheErrorCode.internalError,
        ),
      ),
    );
  });

  test('maps a native error to a typed exception', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => throw PlatformException(
            code: 'network_error',
            message: 'Download failed',
          ),
        );

    await expectLater(
      client.loadImage('https://example.com/a.png'),
      throwsA(
        isA<ImageCacheException>().having(
          (error) => error.code,
          'code',
          ImageCacheErrorCode.networkError,
        ),
      ),
    );
  });
}
