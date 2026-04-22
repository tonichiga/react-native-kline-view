package com.github.fujianlian.native_kline_view;

import android.content.Context;
import androidx.annotation.NonNull;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;
import java.util.Map;

public class NativeKlineViewFactory extends PlatformViewFactory {
    private final BinaryMessenger messenger;

    public NativeKlineViewFactory(BinaryMessenger messenger) {
        super(StandardMessageCodec.INSTANCE);
        this.messenger = messenger;
    }

    @NonNull
    @Override
    public PlatformView create(@NonNull Context context, int viewId, Object args) {
        Map<String, Object> creationParams = null;
        if (args instanceof Map) {
            creationParams = (Map<String, Object>) args;
        }
        return new NativeKlinePlatformView(context, messenger, viewId, creationParams);
    }
}

