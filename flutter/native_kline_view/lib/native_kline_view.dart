import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

typedef DrawItemDidTouchCallback = void Function(Map<String, dynamic> payload);
typedef DrawItemCompleteCallback = void Function();
typedef DrawPointCompleteCallback = void Function(int pointCount);

class NativeKLineViewController {
  NativeKLineViewController._(this._viewId) {
    _methodChannel = MethodChannel('native_kline_view/methods_$_viewId');
    _eventChannel = EventChannel('native_kline_view/events_$_viewId');
  }

  final int _viewId;
  late final MethodChannel _methodChannel;
  late final EventChannel _eventChannel;
  StreamSubscription? _eventSub;

  void _startListening({
    DrawItemDidTouchCallback? onDrawItemDidTouch,
    DrawItemCompleteCallback? onDrawItemComplete,
    DrawPointCompleteCallback? onDrawPointComplete,
  }) {
    _eventSub = _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is! Map) return;
      final type = event['type'];
      final payload = event['payload'];
      if (type == 'onDrawItemDidTouch' && payload is Map) {
        onDrawItemDidTouch?.call(Map<String, dynamic>.from(payload));
      } else if (type == 'onDrawItemComplete') {
        onDrawItemComplete?.call();
      } else if (type == 'onDrawPointComplete' && payload is Map) {
        final count = payload['pointCount'];
        if (count is int) {
          onDrawPointComplete?.call(count);
        }
      }
    });
  }

  Future<void> setOptionList(String optionList) {
    return _methodChannel.invokeMethod('setOptionList', {
      'optionList': optionList,
    });
  }

  Future<void> dispose() async {
    await _eventSub?.cancel();
    _eventSub = null;
  }
}

class NativeKLineView extends StatefulWidget {
  const NativeKLineView({
    Key? key,
    this.optionList,
    this.onDrawItemDidTouch,
    this.onDrawItemComplete,
    this.onDrawPointComplete,
    this.onViewCreated,
  }) : super(key: key);

  final String? optionList;
  final DrawItemDidTouchCallback? onDrawItemDidTouch;
  final DrawItemCompleteCallback? onDrawItemComplete;
  final DrawPointCompleteCallback? onDrawPointComplete;
  final void Function(NativeKLineViewController controller)? onViewCreated;

  @override
  State<NativeKLineView> createState() => _NativeKLineViewState();
}

class _NativeKLineViewState extends State<NativeKLineView> {
  NativeKLineViewController? _controller;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'native_kline_view',
        creationParams: {
          'optionList': widget.optionList,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'native_kline_view',
        creationParams: {
          'optionList': widget.optionList,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
    return const SizedBox.shrink();
  }

  void _onPlatformViewCreated(int id) {
    final controller = NativeKLineViewController._(id);
    controller._startListening(
      onDrawItemDidTouch: widget.onDrawItemDidTouch,
      onDrawItemComplete: widget.onDrawItemComplete,
      onDrawPointComplete: widget.onDrawPointComplete,
    );
    _controller = controller;
    if (widget.optionList != null) {
      controller.setOptionList(widget.optionList!);
    }
    widget.onViewCreated?.call(controller);
  }

  @override
  void didUpdateWidget(covariant NativeKLineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.optionList != null && widget.optionList != oldWidget.optionList) {
      _controller?.setOptionList(widget.optionList!);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
