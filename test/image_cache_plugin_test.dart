import 'package:flutter_test/flutter_test.dart';
import 'package:image_cache_plugin/image_cache_plugin.dart';

void main() {
  test('public facade can be constructed', () {
    const plugin = ImageCachePlugin();

    expect(plugin, isA<ImageCachePlugin>());
  });
}
