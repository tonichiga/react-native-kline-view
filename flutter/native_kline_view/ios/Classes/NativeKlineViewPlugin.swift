import Flutter
import UIKit
import NativeKLineView

public class NativeKlineViewPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let factory = NativeKlineViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "native_kline_view")
    }
}

final class NativeKlineViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return NativeKlinePlatformView(
            frame: frame,
            viewId: viewId,
            args: args,
            messenger: messenger
        )
    }
}

final class NativeKlineStreamHandler: NSObject, FlutterStreamHandler {
    var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}

final class NativeKlinePlatformView: NSObject, FlutterPlatformView {
    private let nativeView: NativeKLineView
    private let methodChannel: FlutterMethodChannel
    private let eventChannel: FlutterEventChannel
    private let streamHandler = NativeKlineStreamHandler()

    init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
        nativeView = NativeKLineView(frame: frame)
        methodChannel = FlutterMethodChannel(name: "native_kline_view/methods_\(viewId)", binaryMessenger: messenger)
        eventChannel = FlutterEventChannel(name: "native_kline_view/events_\(viewId)", binaryMessenger: messenger)
        super.init()

        if let dict = args as? [String: Any], let optionList = dict["optionList"] as? String {
            nativeView.optionList = optionList
        }

        methodChannel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            if call.method == "setOptionList",
               let args = call.arguments as? [String: Any],
               let optionList = args["optionList"] as? String {
                self.nativeView.optionList = optionList
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        eventChannel.setStreamHandler(streamHandler)

        nativeView.onDrawItemDidTouch = { [weak self] payload in
            self?.sendEvent(type: "onDrawItemDidTouch", payload: payload)
        }
        nativeView.onDrawItemComplete = { [weak self] payload in
            self?.sendEvent(type: "onDrawItemComplete", payload: payload)
        }
        nativeView.onDrawPointComplete = { [weak self] payload in
            self?.sendEvent(type: "onDrawPointComplete", payload: payload)
        }
    }

    func view() -> UIView {
        return nativeView
    }

    private func sendEvent(type: String, payload: [String: Any]) {
        guard let sink = streamHandler.eventSink else { return }
        sink([
            "type": type,
            "payload": payload
        ])
    }
}
