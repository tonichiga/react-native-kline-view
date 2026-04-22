package com.github.fujianlian.klineexample;

import android.app.Activity;
import android.app.AlertDialog;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.view.View;
import android.widget.Button;
import android.widget.CompoundButton;
import android.widget.Switch;
import android.widget.TextView;
import android.graphics.drawable.GradientDrawable;

import com.github.fujianlian.klinechart.NativeKLineView;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Random;

public class MainActivity extends Activity {
    private NativeKLineView klineView;
    private TextView themeLabel;
    private Switch themeSwitch;
    private Button timeButton;
    private Button indicatorButton;
    private Button drawButton;
    private Button clearButton;
    private View chartContainer;

    private boolean isDarkTheme = false;
    private int selectedTimeType = 2;
    private int selectedMainIndicator = 1;
    private int selectedSubIndicator = 3;
    private int selectedDrawTool = DrawTypeConstants.none;
    private boolean drawShouldContinue = true;
    private List<KLineItem> klineData = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        klineView = findViewById(R.id.klineView);
        themeLabel = findViewById(R.id.themeLabel);
        themeSwitch = findViewById(R.id.themeSwitch);
        timeButton = findViewById(R.id.timeButton);
        indicatorButton = findViewById(R.id.indicatorButton);
        drawButton = findViewById(R.id.drawButton);
        clearButton = findViewById(R.id.clearButton);
        chartContainer = findViewById(R.id.chartContainer);

        boolean isHorizontalScreen = isHorizontal();
        selectedSubIndicator = isHorizontalScreen ? 0 : 3;
        klineData = generateMockData();

        themeSwitch.setOnCheckedChangeListener((CompoundButton buttonView, boolean isChecked) -> {
            isDarkTheme = isChecked;
            applyTheme();
            reloadKLineData();
        });

        timeButton.setOnClickListener(v -> showTimeSelector());
        indicatorButton.setOnClickListener(v -> showIndicatorSelector());
        drawButton.setOnClickListener(v -> showDrawToolSelector());
        clearButton.setOnClickListener(v -> clearDrawings());

        applyTheme();
        updateControlButtonTitles();
        reloadKLineData();
    }

    private void applyTheme() {
        Theme theme = ThemeManager.currentTheme(isDarkTheme);
        View root = findViewById(R.id.rootLayout);
        View toolbar = findViewById(R.id.toolbar);
        View controlBar = findViewById(R.id.controlBar);

        root.setBackgroundColor(theme.backgroundColor);
        toolbar.setBackgroundColor(theme.headerColor);
        controlBar.setBackgroundColor(theme.headerColor);
        if (chartContainer != null) {
            GradientDrawable drawable = new GradientDrawable();
            drawable.setColor(0x00000000);
            drawable.setCornerRadius(dp(8));
            drawable.setStroke(1, theme.gridColor);
            chartContainer.setBackground(drawable);
        }

        TextView title = findViewById(R.id.titleLabel);
        title.setTextColor(theme.textColor);
        themeLabel.setTextColor(theme.textColor);
        themeLabel.setText(isDarkTheme ? "夜间" : "日间");

        Button[] buttons = new Button[]{timeButton, indicatorButton, drawButton, clearButton};
        for (Button button : buttons) {
            button.setTextColor(0xFFFFFFFF);
            button.setBackgroundColor(theme.buttonColor);
        }
        if (selectedDrawTool != DrawTypeConstants.none) {
            drawButton.setBackgroundColor(theme.increaseColor);
        }
    }

    private void updateControlButtonTitles() {
        timeButton.setText(TimeTypes.get(selectedTimeType).label);
        String mainLabel = IndicatorTypes.main.get(selectedMainIndicator).label;
        String subLabel = IndicatorTypes.sub.get(selectedSubIndicator).label;
        indicatorButton.setText(mainLabel + "/" + subLabel);
        String drawTitle = selectedDrawTool == DrawTypeConstants.none ? "绘图" : DrawToolHelper.name(selectedDrawTool);
        drawButton.setText(drawTitle);
        clearButton.setText("清除");
    }

    private void showTimeSelector() {
        List<Integer> keys = new ArrayList<>(TimeTypes.keySet());
        Collections.sort(keys);
        String[] labels = new String[keys.size()];
        for (int i = 0; i < keys.size(); i++) {
            labels[i] = TimeTypes.get(keys.get(i)).label;
        }
        new AlertDialog.Builder(this)
            .setTitle("选择时间周期")
            .setItems(labels, (dialog, which) -> {
                selectedTimeType = keys.get(which);
                klineData = generateMockData();
                updateControlButtonTitles();
                reloadKLineData();
            })
            .setNegativeButton("关闭", null)
            .show();
    }

    private void showIndicatorSelector() {
        List<Integer> mainKeys = new ArrayList<>(IndicatorTypes.main.keySet());
        List<Integer> subKeys = new ArrayList<>(IndicatorTypes.sub.keySet());
        Collections.sort(mainKeys);
        Collections.sort(subKeys);
        List<String> labels = new ArrayList<>();
        List<Integer> mapType = new ArrayList<>();

        for (Integer key : mainKeys) {
            labels.add("主图: " + IndicatorTypes.main.get(key).label);
            mapType.add(key);
        }
        for (Integer key : subKeys) {
            labels.add("副图: " + IndicatorTypes.sub.get(key).label);
            mapType.add(-key - 1);
        }

        new AlertDialog.Builder(this)
            .setTitle("选择指标")
            .setItems(labels.toArray(new String[0]), (dialog, which) -> {
                int value = mapType.get(which);
                if (value >= 0) {
                    selectedMainIndicator = value;
                } else {
                    selectedSubIndicator = -value - 1;
                }
                updateControlButtonTitles();
                reloadKLineData();
            })
            .setNegativeButton("关闭", null)
            .show();
    }

    private void showDrawToolSelector() {
        List<Integer> keys = DrawToolTypes.order;
        List<String> labels = new ArrayList<>();
        for (Integer key : keys) {
            labels.add(DrawToolTypes.list.get(key).label);
        }
        labels.add(drawShouldContinue ? "连续绘图: 开" : "连续绘图: 关");

        new AlertDialog.Builder(this)
            .setTitle("绘图工具")
            .setItems(labels.toArray(new String[0]), (dialog, which) -> {
                if (which == labels.size() - 1) {
                    drawShouldContinue = !drawShouldContinue;
                    return;
                }
                selectDrawTool(keys.get(which));
            })
            .setNegativeButton("关闭", null)
            .show();
    }

    private void selectDrawTool(int tool) {
        selectedDrawTool = tool;
        updateControlButtonTitles();
        setOptionList(createDrawUpdateOption(tool));
        applyTheme();
    }

    private void clearDrawings() {
        selectedDrawTool = DrawTypeConstants.none;
        updateControlButtonTitles();
        try {
            JSONObject drawList = new JSONObject();
            drawList.put("shouldReloadDrawItemIndex", DrawStateConstants.none);
            drawList.put("shouldClearDraw", true);
            JSONObject option = new JSONObject();
            option.put("drawList", drawList);
            setOptionList(option.toString());
        } catch (JSONException e) {
            // ignore
        }
        applyTheme();
    }

    private void reloadKLineData() {
        List<KLineItem> processed = processKLineData(klineData);
        String optionList = packOptionList(processed);
        setOptionList(optionList);
    }

    private void setOptionList(String optionList) {
        if (klineView != null) {
            klineView.setOptionList(optionList);
        }
    }

    private String createDrawUpdateOption(int tool) {
        try {
            JSONObject drawList = new JSONObject();
            drawList.put("shouldReloadDrawItemIndex", tool == DrawTypeConstants.none ? DrawStateConstants.none : DrawStateConstants.showContext);
            drawList.put("drawShouldContinue", drawShouldContinue);
            drawList.put("drawType", tool);
            drawList.put("shouldFixDraw", false);
            JSONObject option = new JSONObject();
            option.put("drawList", drawList);
            return option.toString();
        } catch (JSONException e) {
            return "{\"modelArray\":[],\"shouldScrollToEnd\":true}";
        }
    }

    private List<KLineItem> generateMockData() {
        List<KLineItem> data = new ArrayList<>();
        double lastClose = 50000;
        long now = System.currentTimeMillis();
        Random random = new Random();

        for (int i = 0; i < 200; i++) {
            long time = now - (long) (200 - i) * 15 * 60 * 1000;
            double open = lastClose;
            double volatility = 0.02;
            double change = (random.nextDouble() - 0.5) * open * volatility;
            double close = Math.max(open + change, open * 0.95);

            double maxPrice = Math.max(open, close);
            double minPrice = Math.min(open, close);
            double high = maxPrice + random.nextDouble() * open * 0.01;
            double low = minPrice - random.nextDouble() * open * 0.01;
            double volume = (0.5 + random.nextDouble()) * 1_000_000;

            KLineItem item = new KLineItem(time, round(open, 2), round(high, 2), round(low, 2), round(close, 2), round(volume, 2));
            data.add(item);
            lastClose = close;
        }

        return data;
    }

    private List<KLineItem> processKLineData(List<KLineItem> rawData) {
        int priceCount = 2;
        int volumeCount = 0;
        TargetList targetList = getTargetList();

        List<KLineItem> processed = new ArrayList<>();
        for (KLineItem item : rawData) {
            KLineItem copy = item.copy();
            copy.id = item.time;
            copy.vol = item.volume;
            processed.add(copy);
        }

        processed = calculateIndicatorsFromTargetList(processed, targetList);

        List<KLineItem> result = new ArrayList<>();
        for (KLineItem item : processed) {
            KLineItem copy = item.copy();
            String time = formatTime(item.id);
            double appendValue = item.close - item.open;
            double appendPercent = appendValue / item.open * 100;
            boolean isAppend = appendValue >= 0;
            String prefix = isAppend ? "+" : "-";
            String appendValueString = prefix + fixRound(Math.abs(appendValue), priceCount, true, false);
            String appendPercentString = prefix + fixRound(Math.abs(appendPercent), 2, true, false) + "%";

            Theme theme = ThemeManager.currentTheme(isDarkTheme);
            int color = isAppend ? theme.increaseColor : theme.decreaseColor;

            copy.dateString = time;
            copy.selectedItemList = new ArrayList<>();
            copy.selectedItemList.add(selectedItem("时间", time, null));
            copy.selectedItemList.add(selectedItem("开", fixRound(item.open, priceCount, true, false), null));
            copy.selectedItemList.add(selectedItem("高", fixRound(item.high, priceCount, true, false), null));
            copy.selectedItemList.add(selectedItem("低", fixRound(item.low, priceCount, true, false), null));
            copy.selectedItemList.add(selectedItem("收", fixRound(item.close, priceCount, true, false), null));
            copy.selectedItemList.add(selectedItem("涨跌额", appendValueString, color));
            copy.selectedItemList.add(selectedItem("涨跌幅", appendPercentString, color));
            copy.selectedItemList.add(selectedItem("成交量", fixRound(item.vol, volumeCount, true, false), null));

            addIndicatorToSelectedList(copy, targetList, priceCount);
            result.add(copy);
        }

        return result;
    }

    private Map<String, Object> selectedItem(String title, String detail, Integer color) {
        Map<String, Object> map = new HashMap<>();
        map.put("title", title);
        map.put("detail", detail);
        if (color != null) {
            map.put("color", color);
        }
        return map;
    }

    private String packOptionList(List<KLineItem> modelArray) {
        Theme theme = ThemeManager.currentTheme(isDarkTheme);
        double pixelRatio = getResources().getDisplayMetrics().density;
        TargetList targetList = getTargetList();

        try {
            JSONObject option = new JSONObject();
            JSONArray modelList = new JSONArray();
            for (KLineItem item : modelArray) {
                modelList.put(item.toJson());
            }

            JSONObject configList = new JSONObject();
            JSONObject colorList = new JSONObject();
            colorList.put("increaseColor", theme.increaseColor);
            colorList.put("decreaseColor", theme.decreaseColor);
            configList.put("colorList", colorList);

            JSONArray targetColorList = new JSONArray();
            targetColorList.put(color(0.96, 0.86, 0.58, 1));
            targetColorList.put(color(0.38, 0.82, 0.75, 1));
            targetColorList.put(color(0.8, 0.57, 1, 1));
            targetColorList.put(color(1, 0.23, 0.24, 1));
            targetColorList.put(color(0.44, 0.82, 0.03, 1));
            targetColorList.put(color(0.44, 0.13, 1, 1));
            configList.put("targetColorList", targetColorList);

            configList.put("minuteLineColor", theme.minuteLineColor);

            JSONArray minuteGradientColorList = new JSONArray();
            minuteGradientColorList.put(color(0.094117647, 0.341176471, 0.831372549, 0.149019608));
            minuteGradientColorList.put(color(0.266666667, 0.501960784, 0.972549020, 0.149019608));
            minuteGradientColorList.put(color(0.074509804, 0.121568627, 0.188235294, 0));
            minuteGradientColorList.put(color(0.074509804, 0.121568627, 0.188235294, 0));
            configList.put("minuteGradientColorList", minuteGradientColorList);

            JSONArray minuteGradientLocationList = new JSONArray();
            minuteGradientLocationList.put(0);
            minuteGradientLocationList.put(0.3);
            minuteGradientLocationList.put(0.6);
            minuteGradientLocationList.put(1);
            configList.put("minuteGradientLocationList", minuteGradientLocationList);

            configList.put("backgroundColor", theme.backgroundColor);
            configList.put("textColor", theme.detailColor);
            configList.put("gridColor", theme.gridColor);
            configList.put("candleTextColor", theme.titleColor);
            configList.put("panelBackgroundColor", isDarkTheme ? color(0.03, 0.09, 0.14, 0.9) : color(1, 1, 1, 0.95));
            configList.put("panelBorderColor", theme.detailColor);
            configList.put("panelTextColor", theme.titleColor);
            configList.put("selectedPointContainerColor", color(0, 0, 0, 0));
            configList.put("selectedPointContentColor", isDarkTheme ? theme.titleColor : color(1, 1, 1, 1));
            configList.put("closePriceCenterBackgroundColor", theme.backgroundColor9703);
            configList.put("closePriceCenterBorderColor", theme.textColor7724);
            configList.put("closePriceCenterTriangleColor", theme.textColor7724);
            configList.put("closePriceCenterSeparatorColor", theme.detailColor);
            configList.put("closePriceRightBackgroundColor", theme.backgroundColor);
            configList.put("closePriceRightSeparatorColor", theme.backgroundColorBlue);
            configList.put("closePriceRightLightLottieFloder", "images");
            configList.put("closePriceRightLightLottieScale", 0.4);

            JSONArray panelGradientColorList = new JSONArray();
            if (isDarkTheme) {
                panelGradientColorList.put(color(0.0588235, 0.101961, 0.160784, 0.2));
                panelGradientColorList.put(color(0.811765, 0.827451, 0.913725, 0.101961));
                panelGradientColorList.put(color(0.811765, 0.827451, 0.913725, 0.2));
                panelGradientColorList.put(color(0.811765, 0.827451, 0.913725, 0.101961));
                panelGradientColorList.put(color(0.0784314, 0.141176, 0.223529, 0.2));
            } else {
                panelGradientColorList.put(color(1, 1, 1, 0));
                panelGradientColorList.put(color(0.54902, 0.623529, 0.678431, 0.101961));
                panelGradientColorList.put(color(0.54902, 0.623529, 0.678431, 0.25098));
                panelGradientColorList.put(color(0.54902, 0.623529, 0.678431, 0.101961));
                panelGradientColorList.put(color(1, 1, 1, 0));
            }
            configList.put("panelGradientColorList", panelGradientColorList);

            JSONArray panelGradientLocationList = new JSONArray();
            panelGradientLocationList.put(0);
            panelGradientLocationList.put(0.25);
            panelGradientLocationList.put(0.5);
            panelGradientLocationList.put(0.75);
            panelGradientLocationList.put(1);
            configList.put("panelGradientLocationList", panelGradientLocationList);

            configList.put("mainFlex", selectedSubIndicator == 0 ? (isHorizontal() ? 0.75 : 0.85) : 0.6);
            configList.put("volumeFlex", isHorizontal() ? 0.25 : 0.15);
            configList.put("paddingTop", 20 * pixelRatio);
            configList.put("paddingBottom", 20 * pixelRatio);
            configList.put("paddingRight", 50 * pixelRatio);
            configList.put("itemWidth", 8 * pixelRatio);
            configList.put("candleWidth", 6 * pixelRatio);
            configList.put("minuteVolumeCandleColor", color(0.0941176, 0.509804, 0.831373, 0.501961));
            configList.put("minuteVolumeCandleWidth", 2 * pixelRatio);
            configList.put("macdCandleWidth", 1 * pixelRatio);
            configList.put("headerTextFontSize", 10 * pixelRatio);
            configList.put("rightTextFontSize", 10 * pixelRatio);
            configList.put("candleTextFontSize", 10 * pixelRatio);
            configList.put("panelTextFontSize", 10 * pixelRatio);
            configList.put("panelMinWidth", 130 * pixelRatio);
            configList.put("fontFamily", "");
            configList.put("closePriceRightLightLottieSource", "");

            JSONObject drawList = new JSONObject();
            drawList.put("shotBackgroundColor", theme.backgroundColor);
            drawList.put("drawType", selectedDrawTool);
            drawList.put("shouldReloadDrawItemIndex", DrawStateConstants.none);
            drawList.put("drawShouldContinue", drawShouldContinue);
            drawList.put("drawColor", color(1, 0.46, 0.05, 1));
            drawList.put("drawLineHeight", 2);
            drawList.put("drawDashWidth", 4);
            drawList.put("drawDashSpace", 4);
            drawList.put("drawIsLock", false);
            drawList.put("shouldFixDraw", false);
            drawList.put("shouldClearDraw", false);

            option.put("modelArray", modelList);
            option.put("shouldScrollToEnd", true);
            option.put("targetList", targetList.toJson());
            option.put("price", 2);
            option.put("volume", 0);
            option.put("primary", selectedMainIndicator);
            option.put("second", selectedSubIndicator);
            option.put("time", TimeTypes.get(selectedTimeType).value);
            option.put("configList", configList);
            option.put("drawList", drawList);

            return option.toString();
        } catch (JSONException e) {
            return "{\"modelArray\":[],\"shouldScrollToEnd\":true}";
        }
    }

    private List<KLineItem> calculateIndicatorsFromTargetList(List<KLineItem> data, TargetList targetList) {
        List<KLineItem> processed = data;

        List<PeriodConfig> maPeriods = new ArrayList<>();
        for (TargetItem item : targetList.maList) {
            if (item.selected) maPeriods.add(new PeriodConfig(item.period(), item.index));
        }
        if (!maPeriods.isEmpty()) {
            processed = calculateMAWithConfig(processed, maPeriods);
        }

        List<PeriodConfig> maVolumePeriods = new ArrayList<>();
        for (TargetItem item : targetList.maVolumeList) {
            if (item.selected) maVolumePeriods.add(new PeriodConfig(item.period(), item.index));
        }
        if (!maVolumePeriods.isEmpty()) {
            processed = calculateVolumeMAWithConfig(processed, maVolumePeriods);
        }

        if (isBOLLSelected()) {
            processed = calculateBOLL(processed, targetList.bollN, targetList.bollP);
        }

        if (isMACDSelected()) {
            processed = calculateMACD(processed, targetList.macdS, targetList.macdL, targetList.macdM);
        }

        if (isKDJSelected()) {
            processed = calculateKDJ(processed, targetList.kdjN, targetList.kdjM1, targetList.kdjM2);
        }

        List<PeriodConfig> rsiPeriods = new ArrayList<>();
        for (TargetItem item : targetList.rsiList) {
            if (item.selected) rsiPeriods.add(new PeriodConfig(item.period(), item.index));
        }
        if (!rsiPeriods.isEmpty()) {
            processed = calculateRSIWithConfig(processed, rsiPeriods);
        }

        List<PeriodConfig> wrPeriods = new ArrayList<>();
        for (TargetItem item : targetList.wrList) {
            if (item.selected) wrPeriods.add(new PeriodConfig(item.period(), item.index));
        }
        if (!wrPeriods.isEmpty()) {
            processed = calculateWRWithConfig(processed, wrPeriods);
        }

        return processed;
    }

    private List<KLineItem> calculateMAWithConfig(List<KLineItem> data, List<PeriodConfig> periodConfigs) {
        List<KLineItem> result = new ArrayList<>();
        for (int index = 0; index < data.size(); index++) {
            KLineItem item = data.get(index).copy();
            List<MAItem> maList = new ArrayList<>(Collections.nCopies(3, null));

            for (PeriodConfig config : periodConfigs) {
                if (index < config.period - 1) {
                    maList.set(config.index, new MAItem(item.close, String.valueOf(config.period)));
                } else {
                    double sum = 0;
                    for (int i = index - config.period + 1; i <= index; i++) {
                        sum += data.get(i).close;
                    }
                    maList.set(config.index, new MAItem(sum / config.period, String.valueOf(config.period)));
                }
            }
            item.maList = maList;
            result.add(item);
        }
        return result;
    }

    private List<KLineItem> calculateVolumeMAWithConfig(List<KLineItem> data, List<PeriodConfig> periodConfigs) {
        List<KLineItem> result = new ArrayList<>();
        for (int index = 0; index < data.size(); index++) {
            KLineItem item = data.get(index).copy();
            List<MAItem> maList = new ArrayList<>(Collections.nCopies(2, null));

            for (PeriodConfig config : periodConfigs) {
                if (index < config.period - 1) {
                    maList.set(config.index, new MAItem(item.volume, String.valueOf(config.period)));
                } else {
                    double sum = 0;
                    for (int i = index - config.period + 1; i <= index; i++) {
                        sum += data.get(i).volume;
                    }
                    maList.set(config.index, new MAItem(sum / config.period, String.valueOf(config.period)));
                }
            }
            item.maVolumeList = maList;
            result.add(item);
        }
        return result;
    }

    private List<KLineItem> calculateBOLL(List<KLineItem> data, int n, int p) {
        List<KLineItem> result = new ArrayList<>();
        for (int index = 0; index < data.size(); index++) {
            KLineItem item = data.get(index).copy();
            if (index < n - 1) {
                item.bollMb = item.close;
                item.bollUp = item.close;
                item.bollDn = item.close;
                result.add(item);
                continue;
            }

            double sum = 0;
            for (int i = index - n + 1; i <= index; i++) {
                sum += data.get(i).close;
            }
            double ma = sum / n;

            double variance = 0;
            for (int i = index - n + 1; i <= index; i++) {
                variance += Math.pow(data.get(i).close - ma, 2);
            }
            double std = Math.sqrt(variance / (n - 1));

            item.bollMb = ma;
            item.bollUp = ma + p * std;
            item.bollDn = ma - p * std;
            result.add(item);
        }
        return result;
    }

    private List<KLineItem> calculateMACD(List<KLineItem> data, int s, int l, int m) {
        double ema12 = data.get(0).close;
        double ema26 = data.get(0).close;
        double dea = 0;

        List<KLineItem> result = new ArrayList<>();
        for (int index = 0; index < data.size(); index++) {
            KLineItem item = data.get(index).copy();
            if (index == 0) {
                item.macdValue = 0.0;
                item.macdDea = 0.0;
                item.macdDif = 0.0;
                result.add(item);
                continue;
            }

            ema12 = (2 * item.close + (s - 1) * ema12) / (s + 1.0);
            ema26 = (2 * item.close + (l - 1) * ema26) / (l + 1.0);
            double dif = ema12 - ema26;
            dea = (2 * dif + (m - 1) * dea) / (m + 1.0);
            double macd = 2 * (dif - dea);

            item.macdValue = macd;
            item.macdDea = dea;
            item.macdDif = dif;
            result.add(item);
        }
        return result;
    }

    private List<KLineItem> calculateKDJ(List<KLineItem> data, int n, int m1, int m2) {
        double k = 50;
        double d = 50;

        List<KLineItem> result = new ArrayList<>();
        for (int index = 0; index < data.size(); index++) {
            KLineItem item = data.get(index).copy();
            if (index == 0) {
                item.kdjK = k;
                item.kdjD = d;
                item.kdjJ = 3 * k - 2 * d;
                result.add(item);
                continue;
            }

            int startIndex = Math.max(0, index - n + 1);
            double highest = -Double.MAX_VALUE;
            double lowest = Double.MAX_VALUE;
            for (int i = startIndex; i <= index; i++) {
                highest = Math.max(highest, data.get(i).high);
                lowest = Math.min(lowest, data.get(i).low);
            }

            double rsv = highest == lowest ? 50 : ((item.close - lowest) / (highest - lowest)) * 100;
            k = (rsv + (m1 - 1) * k) / m1;
            d = (k + (m1 - 1) * d) / m1;
            double j = m2 * k - 2 * d;

            item.kdjK = k;
            item.kdjD = d;
            item.kdjJ = j;
            result.add(item);
        }
        return result;
    }

    private List<KLineItem> calculateRSIWithConfig(List<KLineItem> data, List<PeriodConfig> periodConfigs) {
        List<KLineItem> result = new ArrayList<>();
        for (int index = 0; index < data.size(); index++) {
            KLineItem item = data.get(index).copy();
            List<IndicatorItem> rsiList = new ArrayList<>(Collections.nCopies(3, null));

            if (index == 0) {
                for (PeriodConfig config : periodConfigs) {
                    rsiList.set(config.index, new IndicatorItem(50, config.index, String.valueOf(config.period)));
                }
                item.rsiList = rsiList;
                result.add(item);
                continue;
            }

            for (PeriodConfig config : periodConfigs) {
                if (index < config.period) {
                    rsiList.set(config.index, new IndicatorItem(50, config.index, String.valueOf(config.period)));
                    continue;
                }

                double gains = 0;
                double losses = 0;
                for (int i = index - config.period + 1; i <= index; i++) {
                    double change = data.get(i).close - data.get(i - 1).close;
                    if (change > 0) gains += change;
                    else losses += Math.abs(change);
                }

                double avgGain = gains / config.period;
                double avgLoss = losses / config.period;
                double rs = avgLoss == 0 ? 100 : avgGain / avgLoss;
                double rsi = 100 - (100 / (1 + rs));
                rsiList.set(config.index, new IndicatorItem(rsi, config.index, String.valueOf(config.period)));
            }

            item.rsiList = rsiList;
            result.add(item);
        }
        return result;
    }

    private List<KLineItem> calculateWRWithConfig(List<KLineItem> data, List<PeriodConfig> periodConfigs) {
        List<KLineItem> result = new ArrayList<>();
        for (int index = 0; index < data.size(); index++) {
            KLineItem item = data.get(index).copy();
            List<IndicatorItem> wrList = new ArrayList<>(Collections.nCopies(1, null));

            for (PeriodConfig config : periodConfigs) {
                if (index < config.period - 1) {
                    wrList.set(config.index, new IndicatorItem(-50, config.index, String.valueOf(config.period)));
                    continue;
                }

                double highest = -Double.MAX_VALUE;
                double lowest = Double.MAX_VALUE;
                for (int i = index - config.period + 1; i <= index; i++) {
                    highest = Math.max(highest, data.get(i).high);
                    lowest = Math.min(lowest, data.get(i).low);
                }

                double wr = highest == lowest ? -50 : -((highest - item.close) / (highest - lowest)) * 100;
                wrList.set(config.index, new IndicatorItem(wr, config.index, String.valueOf(config.period)));
            }

            item.wrList = wrList;
            result.add(item);
        }
        return result;
    }

    private void addIndicatorToSelectedList(KLineItem item, TargetList targetList, int priceCount) {
        if (isMASelected() && item.maList != null) {
            for (MAItem maItem : item.maList) {
                if (maItem != null && maItem.title != null) {
                    item.selectedItemList.add(selectedItem("MA" + maItem.title, fixRound(maItem.value, priceCount, false, false), null));
                }
            }
        }

        if (isBOLLSelected() && item.bollMb != null) {
            item.selectedItemList.add(selectedItem("BOLL上", fixRound(item.bollUp, priceCount, false, false), null));
            item.selectedItemList.add(selectedItem("BOLL中", fixRound(item.bollMb, priceCount, false, false), null));
            item.selectedItemList.add(selectedItem("BOLL下", fixRound(item.bollDn, priceCount, false, false), null));
        }

        if (isMACDSelected() && item.macdDif != null) {
            item.selectedItemList.add(selectedItem("DIF", fixRound(item.macdDif, 4, false, false), null));
            item.selectedItemList.add(selectedItem("DEA", fixRound(item.macdDea, 4, false, false), null));
            item.selectedItemList.add(selectedItem("MACD", fixRound(item.macdValue, 4, false, false), null));
        }

        if (isKDJSelected() && item.kdjK != null) {
            item.selectedItemList.add(selectedItem("K", fixRound(item.kdjK, 2, false, false), null));
            item.selectedItemList.add(selectedItem("D", fixRound(item.kdjD, 2, false, false), null));
            item.selectedItemList.add(selectedItem("J", fixRound(item.kdjJ, 2, false, false), null));
        }

        if (isRSISelected() && item.rsiList != null) {
            for (IndicatorItem rsiItem : item.rsiList) {
                if (rsiItem != null) {
                    item.selectedItemList.add(selectedItem("RSI" + rsiItem.title, fixRound(rsiItem.value, 2, false, false), null));
                }
            }
        }

        if (isWRSelected() && item.wrList != null) {
            for (IndicatorItem wrItem : item.wrList) {
                if (wrItem != null) {
                    item.selectedItemList.add(selectedItem("WR" + wrItem.title, fixRound(wrItem.value, 2, false, false), null));
                }
            }
        }
    }

    private boolean isMASelected() { return selectedMainIndicator == IndicatorTypes.mainMa; }
    private boolean isBOLLSelected() { return selectedMainIndicator == IndicatorTypes.mainBoll; }
    private boolean isMACDSelected() { return selectedSubIndicator == IndicatorTypes.subMacd; }
    private boolean isKDJSelected() { return selectedSubIndicator == IndicatorTypes.subKdj; }
    private boolean isRSISelected() { return selectedSubIndicator == IndicatorTypes.subRsi; }
    private boolean isWRSelected() { return selectedSubIndicator == IndicatorTypes.subWr; }

    private TargetList getTargetList() {
        List<TargetItem> maList = new ArrayList<>();
        maList.add(new TargetItem("5", isMASelected(), 0));
        maList.add(new TargetItem("10", isMASelected(), 1));
        maList.add(new TargetItem("20", isMASelected(), 2));

        List<TargetItem> maVolumeList = new ArrayList<>();
        maVolumeList.add(new TargetItem("5", true, 0));
        maVolumeList.add(new TargetItem("10", true, 1));

        List<TargetItem> rsiList = new ArrayList<>();
        rsiList.add(new TargetItem("6", isRSISelected(), 0));
        rsiList.add(new TargetItem("12", isRSISelected(), 1));
        rsiList.add(new TargetItem("24", isRSISelected(), 2));

        List<TargetItem> wrList = new ArrayList<>();
        wrList.add(new TargetItem("14", isWRSelected(), 0));

        return new TargetList(maList, maVolumeList, 20, 2, 12, 26, 9, 9, 3, 3, rsiList, wrList);
    }

    private String fixRound(Object value, int precision, boolean showSign, boolean showGrouping) {
        if (value == null) return "--";
        Double numVal = null;
        if (value instanceof Number) {
            numVal = ((Number) value).doubleValue();
        } else {
            try {
                numVal = Double.parseDouble(value.toString());
            } catch (Exception ignored) {
            }
        }
        if (numVal == null) return "--";

        DecimalFormatSymbols symbols = new DecimalFormatSymbols(Locale.getDefault());
        DecimalFormat df = new DecimalFormat();
        df.setDecimalFormatSymbols(symbols);
        df.setMaximumFractionDigits(precision);
        df.setMinimumFractionDigits(precision);
        df.setGroupingUsed(showGrouping);
        String result = df.format(numVal);
        if (showSign && numVal > 0) {
            result = "+" + result;
        }
        return result;
    }

    private String formatTime(double timestamp) {
        SimpleDateFormat sdf = new SimpleDateFormat("MM-dd HH:mm", Locale.getDefault());
        return sdf.format(new Date((long) timestamp));
    }

    private boolean isHorizontal() {
        DisplayMetrics dm = getResources().getDisplayMetrics();
        return dm.widthPixels > dm.heightPixels;
    }

    private double round(double value, int precision) {
        double factor = Math.pow(10, precision);
        return Math.round(value * factor) / factor;
    }

    private float dp(float value) {
        return value * getResources().getDisplayMetrics().density;
    }

    private int color(double r, double g, double b, double a) {
        int red = (int) Math.round(r * 255);
        int green = (int) Math.round(g * 255);
        int blue = (int) Math.round(b * 255);
        int alpha = (int) Math.round(a * 255);
        return (alpha << 24) | (red << 16) | (green << 8) | blue;
    }

    private static class KLineItem {
        double time;
        double open;
        double high;
        double low;
        double close;
        double volume;
        double id;
        double vol;
        String dateString = "";
        List<Map<String, Object>> selectedItemList = new ArrayList<>();

        List<MAItem> maList;
        List<MAItem> maVolumeList;
        Double bollMb;
        Double bollUp;
        Double bollDn;
        Double macdValue;
        Double macdDea;
        Double macdDif;
        Double kdjK;
        Double kdjD;
        Double kdjJ;
        List<IndicatorItem> rsiList;
        List<IndicatorItem> wrList;

        KLineItem(double time, double open, double high, double low, double close, double volume) {
            this.time = time;
            this.open = open;
            this.high = high;
            this.low = low;
            this.close = close;
            this.volume = volume;
        }

        KLineItem copy() {
            KLineItem copy = new KLineItem(time, open, high, low, close, volume);
            copy.id = id;
            copy.vol = vol;
            copy.dateString = dateString;
            copy.selectedItemList = new ArrayList<>(selectedItemList);
            copy.maList = maList;
            copy.maVolumeList = maVolumeList;
            copy.bollMb = bollMb;
            copy.bollUp = bollUp;
            copy.bollDn = bollDn;
            copy.macdValue = macdValue;
            copy.macdDea = macdDea;
            copy.macdDif = macdDif;
            copy.kdjK = kdjK;
            copy.kdjD = kdjD;
            copy.kdjJ = kdjJ;
            copy.rsiList = rsiList;
            copy.wrList = wrList;
            return copy;
        }

        JSONObject toJson() throws JSONException {
            JSONObject obj = new JSONObject();
            obj.put("time", time);
            obj.put("open", open);
            obj.put("high", high);
            obj.put("low", low);
            obj.put("close", close);
            obj.put("volume", volume);
            obj.put("id", id);
            obj.put("vol", vol);
            obj.put("dateString", dateString);

            JSONArray selectedItems = new JSONArray();
            for (Map<String, Object> item : selectedItemList) {
                selectedItems.put(new JSONObject(item));
            }
            obj.put("selectedItemList", selectedItems);

            if (maList != null) {
                JSONArray list = new JSONArray();
                for (MAItem item : maList) list.put(item == null ? JSONObject.NULL : item.toJson());
                obj.put("maList", list);
            }
            if (maVolumeList != null) {
                JSONArray list = new JSONArray();
                for (MAItem item : maVolumeList) list.put(item == null ? JSONObject.NULL : item.toJson());
                obj.put("maVolumeList", list);
            }
            if (bollMb != null) obj.put("bollMb", bollMb);
            if (bollUp != null) obj.put("bollUp", bollUp);
            if (bollDn != null) obj.put("bollDn", bollDn);
            if (macdValue != null) obj.put("macdValue", macdValue);
            if (macdDea != null) obj.put("macdDea", macdDea);
            if (macdDif != null) obj.put("macdDif", macdDif);
            if (kdjK != null) obj.put("kdjK", kdjK);
            if (kdjD != null) obj.put("kdjD", kdjD);
            if (kdjJ != null) obj.put("kdjJ", kdjJ);

            if (rsiList != null) {
                JSONArray list = new JSONArray();
                for (IndicatorItem item : rsiList) list.put(item == null ? JSONObject.NULL : item.toJson());
                obj.put("rsiList", list);
            }
            if (wrList != null) {
                JSONArray list = new JSONArray();
                for (IndicatorItem item : wrList) list.put(item == null ? JSONObject.NULL : item.toJson());
                obj.put("wrList", list);
            }
            return obj;
        }
    }

    private static class MAItem {
        double value;
        String title;

        MAItem(double value, String title) {
            this.value = value;
            this.title = title;
        }

        JSONObject toJson() throws JSONException {
            JSONObject obj = new JSONObject();
            obj.put("value", value);
            obj.put("title", title);
            return obj;
        }
    }

    private static class IndicatorItem {
        double value;
        int index;
        String title;

        IndicatorItem(double value, int index, String title) {
            this.value = value;
            this.index = index;
            this.title = title;
        }

        JSONObject toJson() throws JSONException {
            JSONObject obj = new JSONObject();
            obj.put("value", value);
            obj.put("index", index);
            obj.put("title", title);
            return obj;
        }
    }

    private static class TargetItem {
        String title;
        boolean selected;
        int index;

        TargetItem(String title, boolean selected, int index) {
            this.title = title;
            this.selected = selected;
            this.index = index;
        }

        int period() { return Integer.parseInt(title); }

        JSONObject toJson() throws JSONException {
            JSONObject obj = new JSONObject();
            obj.put("title", title);
            obj.put("selected", selected);
            obj.put("index", index);
            return obj;
        }
    }

    private static class TargetList {
        List<TargetItem> maList;
        List<TargetItem> maVolumeList;
        int bollN;
        int bollP;
        int macdS;
        int macdL;
        int macdM;
        int kdjN;
        int kdjM1;
        int kdjM2;
        List<TargetItem> rsiList;
        List<TargetItem> wrList;

        TargetList(List<TargetItem> maList, List<TargetItem> maVolumeList, int bollN, int bollP, int macdS, int macdL, int macdM,
                   int kdjN, int kdjM1, int kdjM2, List<TargetItem> rsiList, List<TargetItem> wrList) {
            this.maList = maList;
            this.maVolumeList = maVolumeList;
            this.bollN = bollN;
            this.bollP = bollP;
            this.macdS = macdS;
            this.macdL = macdL;
            this.macdM = macdM;
            this.kdjN = kdjN;
            this.kdjM1 = kdjM1;
            this.kdjM2 = kdjM2;
            this.rsiList = rsiList;
            this.wrList = wrList;
        }

        JSONObject toJson() throws JSONException {
            JSONObject obj = new JSONObject();
            JSONArray maListJson = new JSONArray();
            for (TargetItem item : maList) maListJson.put(item.toJson());
            JSONArray maVolumeListJson = new JSONArray();
            for (TargetItem item : maVolumeList) maVolumeListJson.put(item.toJson());
            JSONArray rsiListJson = new JSONArray();
            for (TargetItem item : rsiList) rsiListJson.put(item.toJson());
            JSONArray wrListJson = new JSONArray();
            for (TargetItem item : wrList) wrListJson.put(item.toJson());

            obj.put("maList", maListJson);
            obj.put("maVolumeList", maVolumeListJson);
            obj.put("bollN", String.valueOf(bollN));
            obj.put("bollP", String.valueOf(bollP));
            obj.put("macdS", String.valueOf(macdS));
            obj.put("macdL", String.valueOf(macdL));
            obj.put("macdM", String.valueOf(macdM));
            obj.put("kdjN", String.valueOf(kdjN));
            obj.put("kdjM1", String.valueOf(kdjM1));
            obj.put("kdjM2", String.valueOf(kdjM2));
            obj.put("rsiList", rsiListJson);
            obj.put("wrList", wrListJson);
            return obj;
        }
    }

    private static class PeriodConfig {
        int period;
        int index;
        PeriodConfig(int period, int index) {
            this.period = period;
            this.index = index;
        }
    }

    private static class TimeType {
        String label;
        int value;
        TimeType(String label, int value) {
            this.label = label;
            this.value = value;
        }
    }

    private static class IndicatorType {
        String label;
        String value;
        IndicatorType(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    private static class DrawToolType {
        String label;
        int value;
        DrawToolType(String label, int value) {
            this.label = label;
            this.value = value;
        }
    }

    private static class Theme {
        int backgroundColor;
        int titleColor;
        int detailColor;
        int textColor7724;
        int headerColor;
        int tabBarBackgroundColor;
        int backgroundColor9103;
        int backgroundColor9703;
        int backgroundColor9113;
        int backgroundColor9709;
        int backgroundColor9603;
        int backgroundColor9411;
        int backgroundColor9607;
        int backgroundColor9609;
        int backgroundColor9509;
        int backgroundColorBlue;
        int buttonColor;
        int borderColor;
        int backgroundOpacity;
        int increaseColor;
        int decreaseColor;
        int minuteLineColor;
        int gridColor;
        int separatorColor;
        int textColor;
    }

    private static class ThemeManager {
        static Theme currentTheme(boolean isDark) {
            Theme theme = new Theme();
            if (isDark) {
                theme.backgroundColor = colorStatic(0.07, 0.12, 0.19, 1);
                theme.titleColor = colorStatic(0.81, 0.83, 0.91, 1);
                theme.detailColor = colorStatic(0.43, 0.53, 0.66, 1);
                theme.textColor7724 = colorStatic(0.24, 0.33, 0.42, 1);
                theme.headerColor = colorStatic(0.09, 0.16, 0.25, 1);
                theme.tabBarBackgroundColor = colorStatic(0.09, 0.16, 0.25, 1);
                theme.backgroundColor9103 = colorStatic(0.03, 0.09, 0.14, 1);
                theme.backgroundColor9703 = colorStatic(0.03, 0.09, 0.14, 1);
                theme.backgroundColor9113 = colorStatic(0.13, 0.2, 0.29, 1);
                theme.backgroundColor9709 = colorStatic(0.09, 0.16, 0.25, 1);
                theme.backgroundColor9603 = colorStatic(0.03, 0.09, 0.14, 1);
                theme.backgroundColor9411 = colorStatic(0.11, 0.17, 0.25, 1);
                theme.backgroundColor9607 = colorStatic(0.07, 0.15, 0.23, 1);
                theme.backgroundColor9609 = colorStatic(0.09, 0.15, 0.23, 1);
                theme.backgroundColor9509 = colorStatic(0.09, 0.16, 0.25, 1);
                theme.backgroundColorBlue = colorStatic(0.14, 0.51, 1, 1);
                theme.buttonColor = colorStatic(0.14, 0.51, 1, 1);
                theme.borderColor = colorStatic(0.13, 0.2, 0.29, 1);
                theme.backgroundOpacity = colorStatic(0, 0, 0, 0.8);
                theme.increaseColor = colorStatic(0.0, 1.0, 0.53, 1);
                theme.decreaseColor = colorStatic(1.0, 0.4, 0.4, 1);
                theme.minuteLineColor = colorStatic(0.14, 0.51, 1, 1);
                theme.gridColor = colorStatic(0.13, 0.2, 0.29, 1);
                theme.separatorColor = colorStatic(0.13, 0.2, 0.29, 1);
                theme.textColor = colorStatic(0.81, 0.83, 0.91, 1);
                return theme;
            }

            theme.backgroundColor = colorStatic(1, 1, 1, 1);
            theme.titleColor = colorStatic(0.08, 0.09, 0.12, 1);
            theme.detailColor = colorStatic(0.55, 0.62, 0.68, 1);
            theme.textColor7724 = colorStatic(0.77, 0.81, 0.84, 1);
            theme.headerColor = colorStatic(0.97, 0.97, 0.98, 1);
            theme.tabBarBackgroundColor = colorStatic(1, 1, 1, 1);
            theme.backgroundColor9103 = colorStatic(0.91, 0.92, 0.93, 1);
            theme.backgroundColor9703 = colorStatic(0.97, 0.97, 0.98, 1);
            theme.backgroundColor9113 = colorStatic(0.91, 0.92, 0.93, 1);
            theme.backgroundColor9709 = colorStatic(0.97, 0.97, 0.98, 1);
            theme.backgroundColor9603 = colorStatic(0.96, 0.97, 0.98, 1);
            theme.backgroundColor9411 = colorStatic(0.94, 0.95, 0.96, 1);
            theme.backgroundColor9607 = colorStatic(0.96, 0.97, 0.99, 1);
            theme.backgroundColor9609 = colorStatic(1, 1, 1, 1);
            theme.backgroundColor9509 = colorStatic(0.95, 0.97, 0.99, 1);
            theme.backgroundColorBlue = colorStatic(0, 0.4, 0.93, 1);
            theme.buttonColor = colorStatic(0, 0.4, 0.93, 1);
            theme.borderColor = colorStatic(0.91, 0.92, 0.93, 1);
            theme.backgroundOpacity = colorStatic(0, 0, 0, 0.5);
            theme.increaseColor = colorStatic(0.0, 0.78, 0.32, 1);
            theme.decreaseColor = colorStatic(1.0, 0.27, 0.27, 1);
            theme.minuteLineColor = colorStatic(0, 0.4, 0.93, 1);
            theme.gridColor = colorStatic(0.91, 0.92, 0.93, 1);
            theme.separatorColor = colorStatic(0.91, 0.92, 0.93, 1);
            theme.textColor = colorStatic(0.08, 0.09, 0.12, 1);
            return theme;
        }

        private static int colorStatic(double r, double g, double b, double a) {
            int red = (int) Math.round(r * 255);
            int green = (int) Math.round(g * 255);
            int blue = (int) Math.round(b * 255);
            int alpha = (int) Math.round(a * 255);
            return (alpha << 24) | (red << 16) | (green << 8) | blue;
        }
    }

    private static class TimeConstants {
        static final int oneMinute = 1;
        static final int threeMinute = 2;
        static final int fiveMinute = 3;
        static final int fifteenMinute = 4;
        static final int thirtyMinute = 5;
        static final int oneHour = 6;
        static final int fourHour = 7;
        static final int sixHour = 8;
        static final int oneDay = 9;
        static final int oneWeek = 10;
        static final int oneMonth = 11;
        static final int minuteHour = -1;
    }

    private static class DrawTypeConstants {
        static final int none = 0;
        static final int show = -1;
        static final int line = 1;
        static final int horizontalLine = 2;
        static final int verticalLine = 3;
        static final int halfLine = 4;
        static final int parallelLine = 5;
        static final int rectangle = 101;
        static final int parallelogram = 102;
    }

    private static class DrawStateConstants {
        static final int none = -3;
        static final int showPencil = -2;
        static final int showContext = -1;
    }

    private static class DrawToolTypes {
        static final Map<Integer, DrawToolType> list = new HashMap<>();
        static final List<Integer> order = new ArrayList<>();

        static {
            list.put(DrawTypeConstants.none, new DrawToolType("关闭绘图", DrawTypeConstants.none));
            list.put(DrawTypeConstants.line, new DrawToolType("线段", DrawTypeConstants.line));
            list.put(DrawTypeConstants.horizontalLine, new DrawToolType("水平线", DrawTypeConstants.horizontalLine));
            list.put(DrawTypeConstants.verticalLine, new DrawToolType("垂直线", DrawTypeConstants.verticalLine));
            list.put(DrawTypeConstants.halfLine, new DrawToolType("射线", DrawTypeConstants.halfLine));
            list.put(DrawTypeConstants.parallelLine, new DrawToolType("平行通道", DrawTypeConstants.parallelLine));
            list.put(DrawTypeConstants.rectangle, new DrawToolType("矩形", DrawTypeConstants.rectangle));
            list.put(DrawTypeConstants.parallelogram, new DrawToolType("平行四边形", DrawTypeConstants.parallelogram));

            order.add(DrawTypeConstants.none);
            order.add(DrawTypeConstants.line);
            order.add(DrawTypeConstants.horizontalLine);
            order.add(DrawTypeConstants.verticalLine);
            order.add(DrawTypeConstants.halfLine);
            order.add(DrawTypeConstants.parallelLine);
            order.add(DrawTypeConstants.rectangle);
            order.add(DrawTypeConstants.parallelogram);
        }
    }

    private static class DrawToolHelper {
        static String name(int type) {
            switch (type) {
                case DrawTypeConstants.line:
                    return "线段";
                case DrawTypeConstants.horizontalLine:
                    return "水平线";
                case DrawTypeConstants.verticalLine:
                    return "垂直线";
                case DrawTypeConstants.halfLine:
                    return "射线";
                case DrawTypeConstants.parallelLine:
                    return "平行通道";
                case DrawTypeConstants.rectangle:
                    return "矩形";
                case DrawTypeConstants.parallelogram:
                    return "平行四边形";
                default:
                    return "绘图";
            }
        }
    }

    private static class IndicatorTypes {
        static final int mainNone = 0;
        static final int mainMa = 1;
        static final int mainBoll = 2;
        static final int subNone = 0;
        static final int subMacd = 3;
        static final int subKdj = 4;
        static final int subRsi = 5;
        static final int subWr = 6;

        static final Map<Integer, IndicatorType> main = new HashMap<>();
        static final Map<Integer, IndicatorType> sub = new HashMap<>();

        static {
            main.put(mainMa, new IndicatorType("MA", "ma"));
            main.put(mainBoll, new IndicatorType("BOLL", "boll"));
            main.put(mainNone, new IndicatorType("NONE", "none"));

            sub.put(subMacd, new IndicatorType("MACD", "macd"));
            sub.put(subKdj, new IndicatorType("KDJ", "kdj"));
            sub.put(subRsi, new IndicatorType("RSI", "rsi"));
            sub.put(subWr, new IndicatorType("WR", "wr"));
            sub.put(subNone, new IndicatorType("NONE", "none"));
        }
    }

    private static final Map<Integer, TimeType> TimeTypes = new HashMap<>();
    static {
        TimeTypes.put(1, new TimeType("分时", TimeConstants.minuteHour));
        TimeTypes.put(2, new TimeType("1分钟", TimeConstants.oneMinute));
        TimeTypes.put(3, new TimeType("3分钟", TimeConstants.threeMinute));
        TimeTypes.put(4, new TimeType("5分钟", TimeConstants.fiveMinute));
        TimeTypes.put(5, new TimeType("15分钟", TimeConstants.fifteenMinute));
        TimeTypes.put(6, new TimeType("30分钟", TimeConstants.thirtyMinute));
        TimeTypes.put(7, new TimeType("1小时", TimeConstants.oneHour));
        TimeTypes.put(8, new TimeType("4小时", TimeConstants.fourHour));
        TimeTypes.put(9, new TimeType("6小时", TimeConstants.sixHour));
        TimeTypes.put(10, new TimeType("1天", TimeConstants.oneDay));
        TimeTypes.put(11, new TimeType("1周", TimeConstants.oneWeek));
        TimeTypes.put(12, new TimeType("1月", TimeConstants.oneMonth));
    }
}
