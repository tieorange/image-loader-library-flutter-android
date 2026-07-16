package com.tieorange.image_cache_plugin.api;

import android.content.Context;
import android.widget.ImageView;
import com.tieorange.image_cache_plugin.domain.CachedImageFile;

final class ImageLoaderJavaCompileTest {
  void exercise(Context context, ImageView target) {
    ImageLoader loader = new ImageLoader(context);
    ImageRequest request = loader.load("https://example.com/image.jpg", new ImageLoaderCallback() {
      @Override public void onSuccess(CachedImageFile result) {}
      @Override public void onError(Exception error) {}
    });
    loader.loadInto("https://example.com/image.jpg", target, 0, new ImageTargetCallback() {
      @Override public void onSuccess(CachedImageFile result) {}
      @Override public void onError(Exception error) {}
    });
    loader.evict("https://example.com/image.jpg", operation());
    loader.clear(operation());
    request.cancel();
    loader.close();
  }

  private CacheOperationCallback operation() {
    return new CacheOperationCallback() {
      @Override public void onSuccess() {}
      @Override public void onError(Exception error) {}
    };
  }
}
