# image_cache_plugin

`image_cache_plugin` is an Android-only Flutter plugin under development. Its
native Kotlin image loader is implemented; the Flutter MethodChannel and widget
API are not implemented yet.

The project will provide a native Kotlin image loader connected to Flutter
through a platform bridge. It is designed around a persistent on-device image
cache with a four-hour freshness period.

## Status

The native `ImageLoader` supports Kotlin suspend calls, Java callbacks, and
`ImageView` targets. It uses `HttpURLConnection` and Kotlin Coroutines without
an image, network, or persistence SDK.

## Native usage

Kotlin:

```kotlin
val loader = ImageLoader(context)
val cached = loader.load("https://example.com/image.jpg")
loader.loadInto(
    url = "https://example.com/image.jpg",
    target = imageView,
    placeholderResource = R.drawable.placeholder,
)
loader.evict("https://example.com/image.jpg")
loader.clear()
loader.close()
```

Java:

```java
ImageLoader loader = new ImageLoader(context);
ImageRequest request = loader.load(url, new ImageLoaderCallback() {
  @Override public void onSuccess(CachedImageFile result) {}

  @Override public void onError(Exception error) {}
});
loader.loadInto(url, imageView, R.drawable.placeholder);
request.cancel();
loader.close();
```

Hosts should retain and close each loader according to their lifecycle.
Synchronous `loadInto` registration and `close` must be called on Android's
main thread; misuse throws `IllegalStateException`. Asynchronous target and
callback delivery also occurs on the main thread.

## Cache behavior

Files are stored below `noBackupFilesDir/image_cache_plugin`. A validated URL is
hashed exactly with SHA-256 and fresh entries remain valid for four hours.
Downloads stream into bounded same-directory temporary files, image dimensions
are checked before commit, and successful files use unique
`<epoch>-<uuid>.img` names.

Coordination is shared process-wide for a canonical cache root. Same-URL loads
coalesce, different URLs may proceed concurrently, and generation checks stop
older work from undoing eviction or clear operations. Crash recovery chooses
the newest valid committed identity and removes older committed files. Inactive
recognized temporary files are cleaned on best effort after they are one hour
old. Coordination is intentionally not cross-process; applications using
multiple Android processes must provide an external locking strategy.

The native decoded bitmap cache is bounded. `ImageView` reuse supersedes older
requests, and target updates and callbacks are delivered on the main thread.

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
as the Flutter-facing implementation becomes available.
