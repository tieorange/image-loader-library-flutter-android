# Image Cache Plugin Example

This Android example app includes a responsive Material 3 gallery. It fetches
the gallery manifest with Dart `HttpClient`, maps expected errors to typed
domain failures, and clears native image files through `ImageCacheClient`.

Dependencies are assembled in `lib/core/di/service_locator.dart`. Feature
classes use constructor injection and do not access the service locator.
`ImageGalleryCubit` acts as the MVVM ViewModel and coordinates loading, retry,
and cache clearing while the grid renders files through `NativeCachedImage`.

Run it from this directory with:

```bash
flutter pub get
flutter run
```
