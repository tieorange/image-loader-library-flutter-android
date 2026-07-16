# image_cache_plugin

`image_cache_plugin` is an Android-only Flutter plugin currently under
development.

The project will provide a native Kotlin image loader connected to Flutter
through a platform bridge. It is designed around a persistent on-device image
cache with a four-hour freshness period.

## Status

Implementation and project scaffolding are still being developed. The plugin
is not yet ready for use, and no runtime behavior described above should be
considered complete.

## Expected development workflow

After the Flutter plugin and example application are scaffolded, development
and verification are expected to use standard Flutter commands such as:

```bash
flutter pub get
flutter analyze
flutter test
cd example
flutter build apk --debug
```

Exact prerequisites, usage, architecture, and build instructions will be added
as the implementation becomes available.
