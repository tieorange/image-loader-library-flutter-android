import 'package:flutter_test/flutter_test.dart';
import 'package:image_cache_plugin_example/main.dart';

void main() {
  testWidgets('shows the foundation screen', (tester) async {
    await tester.pumpWidget(const ImageCacheExampleApp());

    expect(find.text('Image Cache Plugin'), findsOneWidget);
    expect(
      find.text('Gallery features will be added in a later milestone.'),
      findsOneWidget,
    );
  });
}
