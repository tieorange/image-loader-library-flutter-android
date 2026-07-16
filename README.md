# image_cache_plugin

`image_cache_plugin` is an Android-only Flutter plugin currently under
development.

The project will provide a native Kotlin image loader connected to Flutter
through a platform bridge. It is designed around a persistent on-device image
cache with a four-hour freshness period.

## Status

The Android plugin and example application foundations are in place. Native
image loading and cache behavior are not implemented yet.

## Expected development workflow

Plugin checks run from the repository root:

```bash
flutter pub get
flutter analyze
flutter test
```

The example Android build runs from `example/`:

```bash
flutter pub get
flutter build apk --debug
```

Exact prerequisites, usage, architecture, and build instructions will be added
as the implementation becomes available.
