package com.github.fujianlian.native_kline_view;

import android.content.Context;
import android.view.View;
import androidx.annotation.NonNull;
import com.github.fujianlian.klinechart.container.NativeKLineContainerView;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;
import java.util.HashMap;
import java.util.Map;

public class NativeKlinePlatformView implements PlatformView {
    private final NativeKLineContainerView nativeView;
    private final MethodChannel methodChannel;
    private final EventChannel eventChannel;
    private EventChannel.EventSink eventSink;

    NativeKlinePlatformView(Context context, BinaryMessenger messenger, int viewId, Map<String, Object> params) {
        nativeView = new NativeKLineContainerView(context);

        if (params != null) {
            Object optionList = params.get("optionList");
            if (optionList instanceof String) {
                nativeView.setOptionList((String) optionList);
            }
        }

        methodChannel = new MethodChannel(messenger, "native_kline_view/methods_" + viewId);
        methodChannel.setMethodCallHandler(this::onMethodCall);

        eventChannel = new EventChannel(messenger, "native_kline_view/events_" + viewId);
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                eventSink = events;
            }

            @Override
            public void onCancel(Object arguments) {
                eventSink = null;
            }
        });

        nativeView.onDrawItemDidTouch = payload -> sendEvent("onDrawItemDidTouch", payload);
        nativeView.onDrawItemComplete = this::sendCompleteEvent;
        nativeView.onDrawPointComplete = pointCount -> {
            Map<String, Object> payload = new HashMap<>();
            payload.put("pointCount", pointCount);
            sendEvent("onDrawPointComplete", payload);
        };
    }

    private void sendCompleteEvent() {
        sendEvent("onDrawItemComplete", new HashMap<>());
    }

    private void sendEvent(String type, Map<String, Object> payload) {
        if (eventSink == null) {
            return;
        }
        Map<String, Object> event = new HashMap<>();
        event.put("type", type);
        event.put("payload", payload);
        eventSink.success(event);
    }

    private void onMethodCall(MethodCall call, MethodChannel.Result result) {
        if ("setOptionList".equals(call.method)) {
            Object optionList = call.argument("optionList");
            if (optionList instanceof String) {
                nativeView.setOptionList((String) optionList);
            }
            result.success(null);
        } else {
            result.notImplemented();
        }
    }

    @NonNull
    @Override
    public View getView() {
        return nativeView;
    }

    @Override
    public void dispose() {
        methodChannel.setMethodCallHandler(null);
        eventChannel.setStreamHandler(null);
        eventSink = null;
    }
}

