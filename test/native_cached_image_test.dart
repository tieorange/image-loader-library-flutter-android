import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_cache_plugin/image_cache_plugin.dart';
import 'package:mocktail/mocktail.dart';

class _MockClient extends Mock implements ImageCacheClient {}

const _file = CachedImageFile(
  path: '/cache/image.img',
  source: ImageCacheSource.disk,
  cachedAtMilliseconds: 1,
);

void main() {
  testWidgets('shows placeholder then builds the loaded file provider', (
    tester,
  ) async {
    final client = _MockClient();
    final completion = Completer<CachedImageFile>();
    when(() => client.loadImage('one')).thenAnswer((_) => completion.future);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: NativeCachedImage(
          url: 'one',
          client: client,
          placeholder: const Text('loading'),
          imageBuilder: (_, provider) => Text(provider.runtimeType.toString()),
        ),
      ),
    );
    expect(find.text('loading'), findsOneWidget);

    completion.complete(_file);
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('FileImage'), findsOneWidget);
  });

  testWidgets('uses the error builder on failure', (tester) async {
    final client = _MockClient();
    when(() => client.loadImage(any())).thenThrow(StateError('failed'));

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: NativeCachedImage(
          url: 'one',
          client: client,
          errorBuilder: (_, error) => Text(error.toString()),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('failed'), findsOneWidget);
  });

  testWidgets('ignores a stale completion after the URL changes', (
    tester,
  ) async {
    final client = _MockClient();
    final first = Completer<CachedImageFile>();
    final second = Completer<CachedImageFile>();
    when(() => client.loadImage('one')).thenAnswer((_) => first.future);
    when(() => client.loadImage('two')).thenAnswer((_) => second.future);

    Widget image(String url) => Directionality(
      textDirection: TextDirection.ltr,
      child: NativeCachedImage(
        url: url,
        client: client,
        placeholder: const Text('loading'),
        imageBuilder: (_, provider) => Text((provider as FileImage).file.path),
      ),
    );

    await tester.pumpWidget(image('one'));
    await tester.pumpWidget(image('two'));
    first.complete(_file);
    await tester.pump();
    await tester.pump();
    expect(find.text('loading'), findsOneWidget);

    second.complete(
      const CachedImageFile(
        path: '/cache/two.img',
        source: ImageCacheSource.network,
        cachedAtMilliseconds: 2,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('/cache/two.img'), findsOneWidget);
  });
}
