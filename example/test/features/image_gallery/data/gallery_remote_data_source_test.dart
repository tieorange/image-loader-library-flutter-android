import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_cache_plugin_example/features/image_gallery/data/sources/gallery_data_exception.dart';
import 'package:image_cache_plugin_example/features/image_gallery/data/sources/gallery_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

final class MockHttpClient extends Mock implements HttpClient {}

void main() {
  late HttpClient client;
  late HttpGalleryRemoteDataSource dataSource;

  setUp(() {
    client = MockHttpClient();
    dataSource = HttpGalleryRemoteDataSource(client);
  });

  test('parses DTOs in response order including duplicates', () {
    final result = dataSource.parseResponse(
      '[{"id":1,"imageUrl":"https://example.com/a.jpg"},'
      '{"id":1,"imageUrl":"https://example.com/a.jpg"}]',
    );

    expect(result, hasLength(2));
    expect(result.first.id, 1);
    expect(result.first.imageUrl, 'https://example.com/a.jpg');
    expect(result.last.toEntity(), result.first.toEntity());
  });

  test('rejects a malformed top-level response', () {
    expect(
      () => dataSource.parseResponse('{"images":[]}'),
      throwsA(isA<GalleryParsingException>()),
    );
  });
}
