import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:native_kline_view/native_kline_view.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: KLineApp(),
  ));
}

class KLineApp extends StatefulWidget {
  const KLineApp({super.key});

  @override
  State<KLineApp> createState() => _KLineAppState();
}

class _KLineAppState extends State<KLineApp> {
  bool isDarkTheme = false;
  int selectedTimeType = 2;
  int selectedMainIndicator = 1;
  int selectedSubIndicator = 3;
  int selectedDrawTool = DrawTypeConstants.none;
  bool drawShouldContinue = true;
  List<Map<String, dynamic>> klineData = [];
  String optionList = '{"modelArray":[],"shouldScrollToEnd":true}';

  @override
  void initState() {
    super.initState();
    final window = WidgetsBinding.instance.window;
    final isHorizontal = window.physicalSize.width > window.physicalSize.height;
    selectedSubIndicator = isHorizontal ? 0 : 3;
    klineData = generateMockData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      reloadKLineData();
    });
  }

  void reloadKLineData() {
    _syncStore();
    final processed = processKLineData(klineData);
    final packed = packOptionList(processed);
    setState(() {
      optionList = jsonEncode(packed);
    });
  }

  void toggleTheme(bool value) {
    setState(() {
      isDarkTheme = value;
    });
    reloadKLineData();
  }

  void selectTimeType(int timeType) {
    setState(() {
      selectedTimeType = timeType;
      klineData = generateMockData();
    });
    reloadKLineData();
  }

  void selectIndicator({required bool isMain, required int indicator}) {
    setState(() {
      if (isMain) {
        selectedMainIndicator = indicator;
      } else {
        selectedSubIndicator = indicator;
      }
    });
    reloadKLineData();
  }

  void selectDrawTool(int tool) {
    setState(() {
      selectedDrawTool = tool;
    });
    final update = {
      'drawList': {
        'shouldReloadDrawItemIndex': tool == DrawTypeConstants.none
            ? DrawStateConstants.none
            : DrawStateConstants.showContext,
        'drawShouldContinue': drawShouldContinue,
        'drawType': tool,
        'shouldFixDraw': false,
      },
    };
    setState(() {
      optionList = jsonEncode(update);
    });
  }

  void clearDrawings() {
    setState(() {
      selectedDrawTool = DrawTypeConstants.none;
    });
    final update = {
      'drawList': {
        'shouldReloadDrawItemIndex': DrawStateConstants.none,
        'shouldClearDraw': true,
      },
    };
    setState(() {
      optionList = jsonEncode(update);
    });
  }

  @override
  Widget build(BuildContext context) {
    _syncStore(context: context);
    final theme = ThemeManager.currentTheme(isDarkTheme);

    return Scaffold(
      backgroundColor: Color(theme.backgroundColor),
      body: SafeArea(
        child: Column(
          children: [
            _buildToolbar(theme),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(theme.gridColor)),
                ),
                child: NativeKLineView(optionList: optionList),
              ),
            ),
            _buildControlBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Color(theme.headerColor),
        border: Border(
          bottom: BorderSide(color: Color(theme.gridColor), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'K线图表',
              style: TextStyle(
                color: Color(theme.textColor),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            isDarkTheme ? '夜间' : '日间',
            style: TextStyle(color: Color(theme.textColor), fontSize: 14),
          ),
          Switch(
            value: isDarkTheme,
            onChanged: toggleTheme,
            activeColor: Colors.white,
            activeTrackColor: Color(theme.buttonColor),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(ThemeData theme) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Color(theme.headerColor),
        border: Border(
          top: BorderSide(color: Color(theme.gridColor), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildButton(
              label: TimeTypes[selectedTimeType]!.label,
              color: theme.buttonColor,
              onPressed: () => _showTimeSelector(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildButton(
              label:
                  '${IndicatorTypes.main[selectedMainIndicator]!.label}/${IndicatorTypes.sub[selectedSubIndicator]!.label}',
              color: theme.buttonColor,
              onPressed: () => _showIndicatorSelector(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildButton(
              label: selectedDrawTool == DrawTypeConstants.none
                  ? '绘图'
                  : (DrawToolHelper.name(selectedDrawTool) ?? '绘图'),
              color: selectedDrawTool == DrawTypeConstants.none
                  ? theme.buttonColor
                  : theme.increaseColor,
              onPressed: () => _showDrawToolSelector(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildButton(
              label: '清除',
              color: theme.buttonColor,
              onPressed: clearDrawings,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required int color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(color),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      onPressed: onPressed,
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  Future<void> _showTimeSelector(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        final keys = TimeTypes.keys.toList()..sort();
        return ListView(
          children: [
            for (final key in keys)
              ListTile(
                title: Text(TimeTypes[key]!.label),
                onTap: () {
                  Navigator.pop(context);
                  selectTimeType(key);
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _showIndicatorSelector(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        final mainKeys = IndicatorTypes.main.keys.toList()..sort();
        final subKeys = IndicatorTypes.sub.keys.toList()..sort();
        return ListView(
          children: [
            const ListTile(title: Text('主图')),
            for (final key in mainKeys)
              ListTile(
                title: Text(IndicatorTypes.main[key]!.label),
                onTap: () {
                  Navigator.pop(context);
                  selectIndicator(isMain: true, indicator: key);
                },
              ),
            const Divider(),
            const ListTile(title: Text('副图')),
            for (final key in subKeys)
              ListTile(
                title: Text(IndicatorTypes.sub[key]!.label),
                onTap: () {
                  Navigator.pop(context);
                  selectIndicator(isMain: false, indicator: key);
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _showDrawToolSelector(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final key in DrawToolTypes.order)
              ListTile(
                title: Text(DrawToolTypes.list[key]!.label),
                onTap: () {
                  Navigator.pop(context);
                  selectDrawTool(key);
                },
              ),
            SwitchListTile(
              title: const Text('是否连续绘图'),
              value: drawShouldContinue,
              onChanged: (value) {
                setState(() {
                  drawShouldContinue = value;
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _syncStore({BuildContext? context}) {
    final store = _AppStateStore.instance;
    store.isDarkTheme = isDarkTheme;
    store.selectedMainIndicator = selectedMainIndicator;
    store.selectedSubIndicator = selectedSubIndicator;
    store.selectedTimeType = selectedTimeType;
    store.selectedDrawTool = selectedDrawTool;
    store.drawShouldContinue = drawShouldContinue;

    if (context != null) {
      final size = MediaQuery.of(context).size;
      store.isHorizontal = size.width > size.height;
      store.pixelRatio =
          defaultTargetPlatform == TargetPlatform.iOS ? 1.0 : MediaQuery.of(context).devicePixelRatio;
    } else {
      final window = WidgetsBinding.instance.window;
      store.isHorizontal = window.physicalSize.width > window.physicalSize.height;
      store.pixelRatio =
          defaultTargetPlatform == TargetPlatform.iOS ? 1.0 : window.devicePixelRatio;
    }
  }
}

// Data & Config

List<Map<String, dynamic>> generateMockData() {
  final data = <Map<String, dynamic>>[];
  double lastClose = 50000;
  final now = DateTime.now().millisecondsSinceEpoch;
  final random = Random();

  for (var i = 0; i < 200; i++) {
    final time = now - (200 - i) * 15 * 60 * 1000;
    final open = lastClose;
    const volatility = 0.02;
    final change = (random.nextDouble() - 0.5) * open * volatility;
    final close = max(open + change, open * 0.95);

    final maxPrice = max(open, close);
    final minPrice = min(open, close);
    final high = maxPrice + random.nextDouble() * open * 0.01;
    final low = minPrice - random.nextDouble() * open * 0.01;
    final volume = (0.5 + random.nextDouble()) * 1000000;

    data.add({
      'time': time,
      'open': _round(open, 2),
      'high': _round(high, 2),
      'low': _round(low, 2),
      'close': _round(close, 2),
      'volume': _round(volume, 2),
    });

    lastClose = close;
  }

  return data;
}

double _round(double value, int precision) {
  final factor = pow(10, precision).toDouble();
  return (value * factor).round() / factor;
}

List<Map<String, dynamic>> processKLineData(List<Map<String, dynamic>> rawData) {
  final priceCount = 2;
  final volumeCount = 0;
  final targetList = getTargetList();

  var processed = rawData.map((item) {
    final copy = Map<String, dynamic>.from(item);
    copy['id'] = item['time'];
    copy['vol'] = item['volume'];
    return copy;
  }).toList();

  processed = calculateIndicatorsFromTargetList(processed, targetList);

  return processed.map((item) {
    final timeString = formatTime(item['id'] as int, 'MM-DD HH:mm');
    final appendValue = (item['close'] as num) - (item['open'] as num);
    final appendPercent = appendValue / (item['open'] as num) * 100;
    final isAppend = appendValue >= 0;
    final prefix = isAppend ? '+' : '-';
    final appendValueString =
        prefix + fixRound(appendValue.abs(), priceCount, true, false);
    final appendPercentString =
        prefix + fixRound(appendPercent.abs(), 2, true, false) + '%';

    final theme = ThemeManager.currentTheme(isDarkThemeGlobal);
    final color = isAppend ? theme.increaseColor : theme.decreaseColor;

    item['dateString'] = timeString;
    item['selectedItemList'] = <Map<String, Object?>>[
      {'title': '时间', 'detail': timeString},
      {'title': '开', 'detail': fixRound(item['open'], priceCount, true, false)},
      {'title': '高', 'detail': fixRound(item['high'], priceCount, true, false)},
      {'title': '低', 'detail': fixRound(item['low'], priceCount, true, false)},
      {'title': '收', 'detail': fixRound(item['close'], priceCount, true, false)},
      {'title': '涨跌额', 'detail': appendValueString, 'color': color},
      {'title': '涨跌幅', 'detail': appendPercentString, 'color': color},
      {
        'title': '成交量',
        'detail': fixRound(item['vol'], volumeCount, true, false),
      },
    ];

    addIndicatorToSelectedList(item, targetList, priceCount);
    return item;
  }).toList();
}

Map<String, dynamic> packOptionList(List<Map<String, dynamic>> modelArray) {
  final theme = ThemeManager.currentTheme(isDarkThemeGlobal);
  final pixelRatio = currentPixelRatio;

  final configList = {
    'colorList': {
      'increaseColor': theme.increaseColor,
      'decreaseColor': theme.decreaseColor,
    },
    'targetColorList': [
      color(0.96, 0.86, 0.58),
      color(0.38, 0.82, 0.75),
      color(0.8, 0.57, 1),
      color(1, 0.23, 0.24),
      color(0.44, 0.82, 0.03),
      color(0.44, 0.13, 1),
    ],
    'minuteLineColor': theme.minuteLineColor,
    'minuteGradientColorList': [
      color(0.094117647, 0.341176471, 0.831372549, 0.149019608),
      color(0.266666667, 0.501960784, 0.972549020, 0.149019608),
      color(0.074509804, 0.121568627, 0.188235294, 0),
      color(0.074509804, 0.121568627, 0.188235294, 0),
    ],
    'minuteGradientLocationList': [0, 0.3, 0.6, 1],
    'backgroundColor': theme.backgroundColor,
    'textColor': theme.detailColor,
    'gridColor': theme.gridColor,
    'candleTextColor': theme.titleColor,
    'panelBackgroundColor':
        isDarkThemeGlobal ? color(0.03, 0.09, 0.14, 0.9) : color(1, 1, 1, 0.95),
    'panelBorderColor': theme.detailColor,
    'panelTextColor': theme.titleColor,
    'selectedPointContainerColor': color(0, 0, 0, 0),
    'selectedPointContentColor':
        isDarkThemeGlobal ? theme.titleColor : color(1, 1, 1),
    'closePriceCenterBackgroundColor': theme.backgroundColor9703,
    'closePriceCenterBorderColor': theme.textColor7724,
    'closePriceCenterTriangleColor': theme.textColor7724,
    'closePriceCenterSeparatorColor': theme.detailColor,
    'closePriceRightBackgroundColor': theme.backgroundColor,
    'closePriceRightSeparatorColor': theme.backgroundColorBlue,
    'closePriceRightLightLottieFloder': 'images',
    'closePriceRightLightLottieScale': 0.4,
    'panelGradientColorList': isDarkThemeGlobal
        ? [
            color(0.0588235, 0.101961, 0.160784, 0.2),
            color(0.811765, 0.827451, 0.913725, 0.101961),
            color(0.811765, 0.827451, 0.913725, 0.2),
            color(0.811765, 0.827451, 0.913725, 0.101961),
            color(0.0784314, 0.141176, 0.223529, 0.2),
          ]
        : [
            color(1, 1, 1, 0),
            color(0.54902, 0.623529, 0.678431, 0.101961),
            color(0.54902, 0.623529, 0.678431, 0.25098),
            color(0.54902, 0.623529, 0.678431, 0.101961),
            color(1, 1, 1, 0),
          ],
    'panelGradientLocationList': [0, 0.25, 0.5, 0.75, 1],
    'mainFlex': selectedSubIndicatorGlobal == 0
        ? (isHorizontalGlobal ? 0.75 : 0.85)
        : 0.6,
    'volumeFlex': isHorizontalGlobal ? 0.25 : 0.15,
    'paddingTop': 20 * pixelRatio,
    'paddingBottom': 20 * pixelRatio,
    'paddingRight': 50 * pixelRatio,
    'itemWidth': 8 * pixelRatio,
    'candleWidth': 6 * pixelRatio,
    'minuteVolumeCandleColor': color(0.0941176, 0.509804, 0.831373, 0.501961),
    'minuteVolumeCandleWidth': 2 * pixelRatio,
    'macdCandleWidth': 1 * pixelRatio,
    'headerTextFontSize': 10 * pixelRatio,
    'rightTextFontSize': 10 * pixelRatio,
    'candleTextFontSize': 10 * pixelRatio,
    'panelTextFontSize': 10 * pixelRatio,
    'panelMinWidth': 130 * pixelRatio,
    'fontFamily': '',
    'closePriceRightLightLottieSource': '',
  };

  final drawList = {
    'shotBackgroundColor': theme.backgroundColor,
    'drawType': selectedDrawToolGlobal,
    'shouldReloadDrawItemIndex': DrawStateConstants.none,
    'drawShouldContinue': drawShouldContinueGlobal,
    'drawColor': color(1, 0.46, 0.05),
    'drawLineHeight': 2,
    'drawDashWidth': 4,
    'drawDashSpace': 4,
    'drawIsLock': false,
    'shouldFixDraw': false,
    'shouldClearDraw': false,
  };

  return {
    'modelArray': modelArray,
    'shouldScrollToEnd': true,
    'targetList': targetListToMap(getTargetList()),
    'price': 2,
    'volume': 0,
    'primary': selectedMainIndicatorGlobal,
    'second': selectedSubIndicatorGlobal,
    'time': TimeTypes[selectedTimeTypeGlobal]!.value,
    'configList': configList,
    'drawList': drawList,
  };
}

List<Map<String, dynamic>> calculateIndicatorsFromTargetList(
  List<Map<String, dynamic>> data,
  TargetList targetList,
) {
  var processed = data;

  final selectedMAPeriods = targetList.maList
      .where((item) => item.selected)
      .map((item) => PeriodConfig(item.period, item.index))
      .toList();
  if (selectedMAPeriods.isNotEmpty) {
    processed = calculateMAWithConfig(processed, selectedMAPeriods);
  }

  final selectedVolumeMAPeriods = targetList.maVolumeList
      .where((item) => item.selected)
      .map((item) => PeriodConfig(item.period, item.index))
      .toList();
  if (selectedVolumeMAPeriods.isNotEmpty) {
    processed = calculateVolumeMAWithConfig(processed, selectedVolumeMAPeriods);
  }

  if (isBOLLSelectedGlobal) {
    processed = calculateBOLL(processed, targetList.bollN, targetList.bollP);
  }

  if (isMACDSelectedGlobal) {
    processed = calculateMACD(processed, targetList.macdS, targetList.macdL, targetList.macdM);
  }

  if (isKDJSelectedGlobal) {
    processed = calculateKDJ(processed, targetList.kdjN, targetList.kdjM1, targetList.kdjM2);
  }

  final selectedRSIPeriods = targetList.rsiList
      .where((item) => item.selected)
      .map((item) => PeriodConfig(item.period, item.index))
      .toList();
  if (selectedRSIPeriods.isNotEmpty) {
    processed = calculateRSIWithConfig(processed, selectedRSIPeriods);
  }

  final selectedWRPeriods = targetList.wrList
      .where((item) => item.selected)
      .map((item) => PeriodConfig(item.period, item.index))
      .toList();
  if (selectedWRPeriods.isNotEmpty) {
    processed = calculateWRWithConfig(processed, selectedWRPeriods);
  }

  return processed;
}

List<Map<String, dynamic>> calculateMAWithConfig(
  List<Map<String, dynamic>> data,
  List<PeriodConfig> periodConfigs,
) {
  return List.generate(data.length, (index) {
    final item = Map<String, dynamic>.from(data[index]);
    final maList = List<Map<String, dynamic>?>.filled(3, null);

    for (final config in periodConfigs) {
      if (index < config.period - 1) {
        maList[config.index] = {
          'value': item['close'],
          'title': '${config.period}',
        };
      } else {
        double sum = 0;
        for (int i = index - config.period + 1; i <= index; i++) {
          sum += data[i]['close'] as num;
        }
        maList[config.index] = {
          'value': sum / config.period,
          'title': '${config.period}',
        };
      }
    }

    item['maList'] = maList;
    return item;
  });
}

List<Map<String, dynamic>> calculateVolumeMAWithConfig(
  List<Map<String, dynamic>> data,
  List<PeriodConfig> periodConfigs,
) {
  return List.generate(data.length, (index) {
    final item = Map<String, dynamic>.from(data[index]);
    final maVolumeList = List<Map<String, dynamic>?>.filled(2, null);

    for (final config in periodConfigs) {
      if (index < config.period - 1) {
        maVolumeList[config.index] = {
          'value': item['volume'],
          'title': '${config.period}',
        };
      } else {
        double sum = 0;
        for (int i = index - config.period + 1; i <= index; i++) {
          sum += data[i]['volume'] as num;
        }
        maVolumeList[config.index] = {
          'value': sum / config.period,
          'title': '${config.period}',
        };
      }
    }

    item['maVolumeList'] = maVolumeList;
    return item;
  });
}

List<Map<String, dynamic>> calculateBOLL(
  List<Map<String, dynamic>> data,
  int n,
  int p,
) {
  return List.generate(data.length, (index) {
    final item = Map<String, dynamic>.from(data[index]);
    if (index < n - 1) {
      item['bollMb'] = item['close'];
      item['bollUp'] = item['close'];
      item['bollDn'] = item['close'];
      return item;
    }

    double sum = 0;
    for (int i = index - n + 1; i <= index; i++) {
      sum += data[i]['close'] as num;
    }
    final ma = sum / n;

    double variance = 0;
    for (int i = index - n + 1; i <= index; i++) {
      variance += pow((data[i]['close'] as num) - ma, 2).toDouble();
    }
    final std = sqrt(variance / (n - 1));

    item['bollMb'] = ma;
    item['bollUp'] = ma + p * std;
    item['bollDn'] = ma - p * std;
    return item;
  });
}

List<Map<String, dynamic>> calculateMACD(
  List<Map<String, dynamic>> data,
  int s,
  int l,
  int m,
) {
  double ema12 = (data.first['close'] as num).toDouble();
  double ema26 = (data.first['close'] as num).toDouble();
  double dea = 0;

  return List.generate(data.length, (index) {
    final item = Map<String, dynamic>.from(data[index]);
    if (index == 0) {
      item['macdValue'] = 0;
      item['macdDea'] = 0;
      item['macdDif'] = 0;
      return item;
    }

    ema12 = (2 * (item['close'] as num) + (s - 1) * ema12) / (s + 1);
    ema26 = (2 * (item['close'] as num) + (l - 1) * ema26) / (l + 1);
    final dif = ema12 - ema26;
    dea = (2 * dif + (m - 1) * dea) / (m + 1);
    final macd = 2 * (dif - dea);

    item['macdValue'] = macd;
    item['macdDea'] = dea;
    item['macdDif'] = dif;
    return item;
  });
}

List<Map<String, dynamic>> calculateKDJ(
  List<Map<String, dynamic>> data,
  int n,
  int m1,
  int m2,
) {
  double k = 50;
  double d = 50;

  return List.generate(data.length, (index) {
    final item = Map<String, dynamic>.from(data[index]);
    if (index == 0) {
      item['kdjK'] = k;
      item['kdjD'] = d;
      item['kdjJ'] = 3 * k - 2 * d;
      return item;
    }

    final startIndex = max(0, index - n + 1);
    double highest = -double.infinity;
    double lowest = double.infinity;
    for (int i = startIndex; i <= index; i++) {
      highest = max(highest, (data[i]['high'] as num).toDouble());
      lowest = min(lowest, (data[i]['low'] as num).toDouble());
    }

    final rsv = highest == lowest
        ? 50
        : ((item['close'] as num) - lowest) / (highest - lowest) * 100;
    k = (rsv + (m1 - 1) * k) / m1;
    d = (k + (m1 - 1) * d) / m1;
    final j = m2 * k - 2 * d;

    item['kdjK'] = k;
    item['kdjD'] = d;
    item['kdjJ'] = j;
    return item;
  });
}

List<Map<String, dynamic>> calculateRSIWithConfig(
  List<Map<String, dynamic>> data,
  List<PeriodConfig> periodConfigs,
) {
  return List.generate(data.length, (index) {
    final item = Map<String, dynamic>.from(data[index]);
    final rsiList = List<Map<String, dynamic>?>.filled(3, null);

    if (index == 0) {
      for (final config in periodConfigs) {
        rsiList[config.index] = {
          'value': 50,
          'index': config.index,
          'title': '${config.period}',
        };
      }
      item['rsiList'] = rsiList;
      return item;
    }

    for (final config in periodConfigs) {
      if (index < config.period) {
        rsiList[config.index] = {
          'value': 50,
          'index': config.index,
          'title': '${config.period}',
        };
        continue;
      }

      double gains = 0;
      double losses = 0;
      for (int i = index - config.period + 1; i <= index; i++) {
        final change = (data[i]['close'] as num) - (data[i - 1]['close'] as num);
        if (change > 0) {
          gains += change;
        } else {
          losses += change.abs();
        }
      }

      final avgGain = gains / config.period;
      final avgLoss = losses / config.period;
      final rs = avgLoss == 0 ? 100 : avgGain / avgLoss;
      final rsi = 100 - (100 / (1 + rs));
      rsiList[config.index] = {
        'value': rsi,
        'index': config.index,
        'title': '${config.period}',
      };
    }

    item['rsiList'] = rsiList;
    return item;
  });
}

List<Map<String, dynamic>> calculateWRWithConfig(
  List<Map<String, dynamic>> data,
  List<PeriodConfig> periodConfigs,
) {
  return List.generate(data.length, (index) {
    final item = Map<String, dynamic>.from(data[index]);
    final wrList = List<Map<String, dynamic>?>.filled(1, null);

    for (final config in periodConfigs) {
      if (index < config.period - 1) {
        wrList[config.index] = {
          'value': -50,
          'index': config.index,
          'title': '${config.period}',
        };
        continue;
      }

      double highest = -double.infinity;
      double lowest = double.infinity;
      for (int i = index - config.period + 1; i <= index; i++) {
        highest = max(highest, (data[i]['high'] as num).toDouble());
        lowest = min(lowest, (data[i]['low'] as num).toDouble());
      }

      final wr = highest == lowest
          ? -50
          : -((highest - (item['close'] as num)) / (highest - lowest)) * 100;
      wrList[config.index] = {
        'value': wr,
        'index': config.index,
        'title': '${config.period}',
      };
    }

    item['wrList'] = wrList;
    return item;
  });
}

void addIndicatorToSelectedList(
  Map<String, dynamic> item,
  TargetList targetList,
  int priceCount,
) {
  final selectedList =
      (item['selectedItemList'] as List).cast<Map<String, Object?>>();

  if (isMASelectedGlobal && item['maList'] != null) {
    for (final maItem in item['maList'] as List) {
      if (maItem != null && maItem['title'] != null) {
        selectedList.add({
          'title': 'MA${maItem['title']}',
          'detail': fixRound(maItem['value'], priceCount, false, false),
        });
      }
    }
  }

  if (isBOLLSelectedGlobal && item['bollMb'] != null) {
    selectedList.addAll(<Map<String, Object?>>[
      {
        'title': 'BOLL上',
        'detail': fixRound(item['bollUp'], priceCount, false, false),
      },
      {
        'title': 'BOLL中',
        'detail': fixRound(item['bollMb'], priceCount, false, false),
      },
      {
        'title': 'BOLL下',
        'detail': fixRound(item['bollDn'], priceCount, false, false),
      },
    ]);
  }

  if (isMACDSelectedGlobal && item['macdDif'] != null) {
    selectedList.addAll(<Map<String, Object?>>[
      {
        'title': 'DIF',
        'detail': fixRound(item['macdDif'], 4, false, false),
      },
      {
        'title': 'DEA',
        'detail': fixRound(item['macdDea'], 4, false, false),
      },
      {
        'title': 'MACD',
        'detail': fixRound(item['macdValue'], 4, false, false),
      },
    ]);
  }

  if (isKDJSelectedGlobal && item['kdjK'] != null) {
    selectedList.addAll(<Map<String, Object?>>[
      {'title': 'K', 'detail': fixRound(item['kdjK'], 2, false, false)},
      {'title': 'D', 'detail': fixRound(item['kdjD'], 2, false, false)},
      {'title': 'J', 'detail': fixRound(item['kdjJ'], 2, false, false)},
    ]);
  }

  if (isRSISelectedGlobal && item['rsiList'] != null) {
    for (final rsiItem in item['rsiList'] as List) {
      if (rsiItem != null) {
        selectedList.add({
          'title': 'RSI${rsiItem['title']}',
          'detail': fixRound(rsiItem['value'], 2, false, false),
        });
      }
    }
  }

  if (isWRSelectedGlobal && item['wrList'] != null) {
    for (final wrItem in item['wrList'] as List) {
      if (wrItem != null) {
        selectedList.add({
          'title': 'WR${wrItem['title']}',
          'detail': fixRound(wrItem['value'], 2, false, false),
        });
      }
    }
  }
}

TargetList getTargetList() {
  return TargetList(
    maList: [
      TargetItem(title: '5', selected: isMASelectedGlobal, index: 0),
      TargetItem(title: '10', selected: isMASelectedGlobal, index: 1),
      TargetItem(title: '20', selected: isMASelectedGlobal, index: 2),
    ],
    maVolumeList: [
      TargetItem(title: '5', selected: true, index: 0),
      TargetItem(title: '10', selected: true, index: 1),
    ],
    bollN: 20,
    bollP: 2,
    macdS: 12,
    macdL: 26,
    macdM: 9,
    kdjN: 9,
    kdjM1: 3,
    kdjM2: 3,
    rsiList: [
      TargetItem(title: '6', selected: isRSISelectedGlobal, index: 0),
      TargetItem(title: '12', selected: isRSISelectedGlobal, index: 1),
      TargetItem(title: '24', selected: isRSISelectedGlobal, index: 2),
    ],
    wrList: [
      TargetItem(title: '14', selected: isWRSelectedGlobal, index: 0),
    ],
  );
}

Map<String, dynamic> targetListToMap(TargetList list) {
  return {
    'maList': list.maList.map((e) => e.toMap()).toList(),
    'maVolumeList': list.maVolumeList.map((e) => e.toMap()).toList(),
    'bollN': list.bollN.toString(),
    'bollP': list.bollP.toString(),
    'macdS': list.macdS.toString(),
    'macdL': list.macdL.toString(),
    'macdM': list.macdM.toString(),
    'kdjN': list.kdjN.toString(),
    'kdjM1': list.kdjM1.toString(),
    'kdjM2': list.kdjM2.toString(),
    'rsiList': list.rsiList.map((e) => e.toMap()).toList(),
    'wrList': list.wrList.map((e) => e.toMap()).toList(),
  };
}

String fixRound(dynamic value, int precision, bool showSign, bool showGrouping) {
  if (value == null) return '--';
  final numVal = value is num ? value : num.tryParse(value.toString());
  if (numVal == null) return '--';
  String result = numVal.toStringAsFixed(precision);
  if (showSign && numVal > 0) {
    result = '+$result';
  }
  return result;
}

String formatTime(int timestamp, String format) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  final second = date.second.toString().padLeft(2, '0');
  return format
      .replaceAll('MM', month)
      .replaceAll('DD', day)
      .replaceAll('HH', hour)
      .replaceAll('mm', minute)
      .replaceAll('ss', second);
}

int color(double r, double g, double b, [double a = 1]) {
  final red = (r * 255).round();
  final green = (g * 255).round();
  final blue = (b * 255).round();
  final alpha = (a * 255).round();
  return (alpha << 24) | (red << 16) | (green << 8) | blue;
}

bool get isMASelectedGlobal => selectedMainIndicatorGlobal == 1;
bool get isBOLLSelectedGlobal => selectedMainIndicatorGlobal == 2;
bool get isMACDSelectedGlobal => selectedSubIndicatorGlobal == 3;
bool get isKDJSelectedGlobal => selectedSubIndicatorGlobal == 4;
bool get isRSISelectedGlobal => selectedSubIndicatorGlobal == 5;
bool get isWRSelectedGlobal => selectedSubIndicatorGlobal == 6;

bool get isDarkThemeGlobal => _AppStateStore.instance.isDarkTheme;
int get selectedMainIndicatorGlobal => _AppStateStore.instance.selectedMainIndicator;
int get selectedSubIndicatorGlobal => _AppStateStore.instance.selectedSubIndicator;
int get selectedTimeTypeGlobal => _AppStateStore.instance.selectedTimeType;
int get selectedDrawToolGlobal => _AppStateStore.instance.selectedDrawTool;
bool get drawShouldContinueGlobal => _AppStateStore.instance.drawShouldContinue;

bool get isHorizontalGlobal => _AppStateStore.instance.isHorizontal;
double get currentPixelRatio => _AppStateStore.instance.pixelRatio;

class _AppStateStore {
  static final _AppStateStore instance = _AppStateStore._();
  _AppStateStore._();

  bool isDarkTheme = false;
  int selectedMainIndicator = 1;
  int selectedSubIndicator = 3;
  int selectedTimeType = 2;
  int selectedDrawTool = DrawTypeConstants.none;
  bool drawShouldContinue = true;
  bool isHorizontal = false;
  double pixelRatio = 1;
}

class PeriodConfig {
  final int period;
  final int index;
  PeriodConfig(this.period, this.index);
}

class TargetItem {
  final String title;
  final bool selected;
  final int index;
  TargetItem({required this.title, required this.selected, required this.index});

  int get period => int.parse(title);

  Map<String, dynamic> toMap() => {
        'title': title,
        'selected': selected,
        'index': index,
      };
}

class TargetList {
  final List<TargetItem> maList;
  final List<TargetItem> maVolumeList;
  final int bollN;
  final int bollP;
  final int macdS;
  final int macdL;
  final int macdM;
  final int kdjN;
  final int kdjM1;
  final int kdjM2;
  final List<TargetItem> rsiList;
  final List<TargetItem> wrList;

  TargetList({
    required this.maList,
    required this.maVolumeList,
    required this.bollN,
    required this.bollP,
    required this.macdS,
    required this.macdL,
    required this.macdM,
    required this.kdjN,
    required this.kdjM1,
    required this.kdjM2,
    required this.rsiList,
    required this.wrList,
  });
}

class TimeType {
  final String label;
  final int value;
  const TimeType(this.label, this.value);
}

class IndicatorType {
  final String label;
  final String value;
  const IndicatorType(this.label, this.value);
}

class ThemeData {
  final int backgroundColor;
  final int titleColor;
  final int detailColor;
  final int textColor7724;
  final int headerColor;
  final int tabBarBackgroundColor;
  final int backgroundColor9103;
  final int backgroundColor9703;
  final int backgroundColor9113;
  final int backgroundColor9709;
  final int backgroundColor9603;
  final int backgroundColor9411;
  final int backgroundColor9607;
  final int backgroundColor9609;
  final int backgroundColor9509;
  final int backgroundColorBlue;
  final int buttonColor;
  final int borderColor;
  final int backgroundOpacity;
  final int increaseColor;
  final int decreaseColor;
  final int minuteLineColor;
  final int gridColor;
  final int separatorColor;
  final int textColor;

  const ThemeData({
    required this.backgroundColor,
    required this.titleColor,
    required this.detailColor,
    required this.textColor7724,
    required this.headerColor,
    required this.tabBarBackgroundColor,
    required this.backgroundColor9103,
    required this.backgroundColor9703,
    required this.backgroundColor9113,
    required this.backgroundColor9709,
    required this.backgroundColor9603,
    required this.backgroundColor9411,
    required this.backgroundColor9607,
    required this.backgroundColor9609,
    required this.backgroundColor9509,
    required this.backgroundColorBlue,
    required this.buttonColor,
    required this.borderColor,
    required this.backgroundOpacity,
    required this.increaseColor,
    required this.decreaseColor,
    required this.minuteLineColor,
    required this.gridColor,
    required this.separatorColor,
    required this.textColor,
  });
}

class ThemeManager {
  static ThemeData currentTheme(bool isDark) {
    if (isDark) {
      return ThemeData(
        backgroundColor: color(0.07, 0.12, 0.19),
        titleColor: color(0.81, 0.83, 0.91),
        detailColor: color(0.43, 0.53, 0.66),
        textColor7724: color(0.24, 0.33, 0.42),
        headerColor: color(0.09, 0.16, 0.25),
        tabBarBackgroundColor: color(0.09, 0.16, 0.25),
        backgroundColor9103: color(0.03, 0.09, 0.14),
        backgroundColor9703: color(0.03, 0.09, 0.14),
        backgroundColor9113: color(0.13, 0.2, 0.29),
        backgroundColor9709: color(0.09, 0.16, 0.25),
        backgroundColor9603: color(0.03, 0.09, 0.14),
        backgroundColor9411: color(0.11, 0.17, 0.25),
        backgroundColor9607: color(0.07, 0.15, 0.23),
        backgroundColor9609: color(0.09, 0.15, 0.23),
        backgroundColor9509: color(0.09, 0.16, 0.25),
        backgroundColorBlue: color(0.14, 0.51, 1),
        buttonColor: color(0.14, 0.51, 1),
        borderColor: color(0.13, 0.2, 0.29),
        backgroundOpacity: color(0, 0, 0, 0.8),
        increaseColor: color(0.0, 1.0, 0.53),
        decreaseColor: color(1.0, 0.4, 0.4),
        minuteLineColor: color(0.14, 0.51, 1),
        gridColor: color(0.13, 0.2, 0.29),
        separatorColor: color(0.13, 0.2, 0.29),
        textColor: color(0.81, 0.83, 0.91),
      );
    }

    return ThemeData(
      backgroundColor: color(1, 1, 1),
      titleColor: color(0.08, 0.09, 0.12),
      detailColor: color(0.55, 0.62, 0.68),
      textColor7724: color(0.77, 0.81, 0.84),
      headerColor: color(0.97, 0.97, 0.98),
      tabBarBackgroundColor: color(1, 1, 1),
      backgroundColor9103: color(0.91, 0.92, 0.93),
      backgroundColor9703: color(0.97, 0.97, 0.98),
      backgroundColor9113: color(0.91, 0.92, 0.93),
      backgroundColor9709: color(0.97, 0.97, 0.98),
      backgroundColor9603: color(0.96, 0.97, 0.98),
      backgroundColor9411: color(0.94, 0.95, 0.96),
      backgroundColor9607: color(0.96, 0.97, 0.99),
      backgroundColor9609: color(1, 1, 1),
      backgroundColor9509: color(0.95, 0.97, 0.99),
      backgroundColorBlue: color(0, 0.4, 0.93),
      buttonColor: color(0, 0.4, 0.93),
      borderColor: color(0.91, 0.92, 0.93),
      backgroundOpacity: color(0, 0, 0, 0.5),
      increaseColor: color(0.0, 0.78, 0.32),
      decreaseColor: color(1.0, 0.27, 0.27),
      minuteLineColor: color(0, 0.4, 0.93),
      gridColor: color(0.91, 0.92, 0.93),
      separatorColor: color(0.91, 0.92, 0.93),
      textColor: color(0.08, 0.09, 0.12),
    );
  }
}

class TimeConstants {
  static const oneMinute = 1;
  static const threeMinute = 2;
  static const fiveMinute = 3;
  static const fifteenMinute = 4;
  static const thirtyMinute = 5;
  static const oneHour = 6;
  static const fourHour = 7;
  static const sixHour = 8;
  static const oneDay = 9;
  static const oneWeek = 10;
  static const oneMonth = 11;
  static const minuteHour = -1;
}

class DrawTypeConstants {
  static const none = 0;
  static const show = -1;
  static const line = 1;
  static const horizontalLine = 2;
  static const verticalLine = 3;
  static const halfLine = 4;
  static const parallelLine = 5;
  static const rectangle = 101;
  static const parallelogram = 102;
}

class DrawStateConstants {
  static const none = -3;
  static const showPencil = -2;
  static const showContext = -1;
}

class DrawToolType {
  final String label;
  final int value;
  const DrawToolType(this.label, this.value);
}

class DrawToolTypes {
  static const list = {
    DrawTypeConstants.none: DrawToolType('关闭绘图', DrawTypeConstants.none),
    DrawTypeConstants.line: DrawToolType('线段', DrawTypeConstants.line),
    DrawTypeConstants.horizontalLine:
        DrawToolType('水平线', DrawTypeConstants.horizontalLine),
    DrawTypeConstants.verticalLine:
        DrawToolType('垂直线', DrawTypeConstants.verticalLine),
    DrawTypeConstants.halfLine: DrawToolType('射线', DrawTypeConstants.halfLine),
    DrawTypeConstants.parallelLine:
        DrawToolType('平行通道', DrawTypeConstants.parallelLine),
    DrawTypeConstants.rectangle: DrawToolType('矩形', DrawTypeConstants.rectangle),
    DrawTypeConstants.parallelogram:
        DrawToolType('平行四边形', DrawTypeConstants.parallelogram),
  };

  static const order = [
    DrawTypeConstants.none,
    DrawTypeConstants.line,
    DrawTypeConstants.horizontalLine,
    DrawTypeConstants.verticalLine,
    DrawTypeConstants.halfLine,
    DrawTypeConstants.parallelLine,
    DrawTypeConstants.rectangle,
    DrawTypeConstants.parallelogram,
  ];
}

class DrawToolHelper {
  static String? name(int type) {
    switch (type) {
      case DrawTypeConstants.line:
        return '线段';
      case DrawTypeConstants.horizontalLine:
        return '水平线';
      case DrawTypeConstants.verticalLine:
        return '垂直线';
      case DrawTypeConstants.halfLine:
        return '射线';
      case DrawTypeConstants.parallelLine:
        return '平行通道';
      case DrawTypeConstants.rectangle:
        return '矩形';
      case DrawTypeConstants.parallelogram:
        return '平行四边形';
      default:
        return null;
    }
  }
}

const TimeTypes = {
  1: TimeType('分时', TimeConstants.minuteHour),
  2: TimeType('1分钟', TimeConstants.oneMinute),
  3: TimeType('3分钟', TimeConstants.threeMinute),
  4: TimeType('5分钟', TimeConstants.fiveMinute),
  5: TimeType('15分钟', TimeConstants.fifteenMinute),
  6: TimeType('30分钟', TimeConstants.thirtyMinute),
  7: TimeType('1小时', TimeConstants.oneHour),
  8: TimeType('4小时', TimeConstants.fourHour),
  9: TimeType('6小时', TimeConstants.sixHour),
  10: TimeType('1天', TimeConstants.oneDay),
  11: TimeType('1周', TimeConstants.oneWeek),
  12: TimeType('1月', TimeConstants.oneMonth),
};

class IndicatorTypes {
  static const main = {
    1: IndicatorType('MA', 'ma'),
    2: IndicatorType('BOLL', 'boll'),
    0: IndicatorType('NONE', 'none'),
  };

  static const sub = {
    3: IndicatorType('MACD', 'macd'),
    4: IndicatorType('KDJ', 'kdj'),
    5: IndicatorType('RSI', 'rsi'),
    6: IndicatorType('WR', 'wr'),
    0: IndicatorType('NONE', 'none'),
  };
}
