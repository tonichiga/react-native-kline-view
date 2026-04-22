package com.github.fujianlian.klinechart.container;

import android.content.Context;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.ViewGroup;
import android.widget.RelativeLayout;
import com.github.fujianlian.klinechart.HTKLineCallback;
import com.github.fujianlian.klinechart.HTKLineConfigManager;
import com.github.fujianlian.klinechart.KLineChartView;
import com.github.fujianlian.klinechart.formatter.DateFormatter;
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.parser.Feature;
import java.util.Map;

public class NativeKLineContainerView extends RelativeLayout {

    public interface OnDrawItemDidTouchListener {
        void onDrawItemDidTouch(Map<String, Object> payload);
    }

    public interface OnDrawItemCompleteListener {
        void onDrawItemComplete();
    }

    public interface OnDrawPointCompleteListener {
        void onDrawPointComplete(int pointCount);
    }

    public HTKLineConfigManager configManager = new HTKLineConfigManager();

    public KLineChartView klineView;

    public HTShotView shotView;

    public OnDrawItemDidTouchListener onDrawItemDidTouch;

    public OnDrawItemCompleteListener onDrawItemComplete;

    public OnDrawPointCompleteListener onDrawPointComplete;

    public NativeKLineContainerView(Context context) {
        super(context);
        init();
    }

    public NativeKLineContainerView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public NativeKLineContainerView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    private void init() {
        klineView = new KLineChartView(getContext(), configManager);
        klineView.setGridColumns(5);
        klineView.setGridRows(3);
        klineView.setChildDraw(0);
        klineView.setDateTimeFormatter(new DateFormatter());
        klineView.configManager = configManager;
        addView(klineView, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));

        shotView = new HTShotView(getContext(), this);
        shotView.setEnabled(false);
        shotView.dimension = 300;
        RelativeLayout.LayoutParams layoutParams = new RelativeLayout.LayoutParams(shotView.dimension, shotView.dimension);
        layoutParams.setMargins(50, 50, 0, 0);
        addView(shotView, layoutParams);
    }

    public void setOptionList(final String optionList) {
        if (optionList == null) {
            return;
        }
        new Thread(new Runnable() {
            @Override
            public void run() {
                int disableDecimalFeature = JSON.DEFAULT_PARSER_FEATURE & ~Feature.UseBigDecimal.getMask();
                Map optionMap = (Map) JSON.parse(optionList, disableDecimalFeature);
                configManager.reloadOptionList(optionMap);
                post(new Runnable() {
                    @Override
                    public void run() {
                        reloadConfigManager();
                    }
                });
            }
        }).start();
    }

    public void reloadConfigManager() {
        klineView.changeMainDrawType(klineView.configManager.primaryStatus);
        klineView.changeSecondDrawType(klineView.configManager.secondStatus);
        klineView.setMainDrawLine(klineView.configManager.isMinute);
        klineView.setPointWidth(klineView.configManager.itemWidth);
        klineView.setCandleWidth(klineView.configManager.candleWidth);

        if (klineView.configManager.fontFamily.length() > 0) {
            klineView.setTextFontFamily(klineView.configManager.fontFamily);
        }
        klineView.setTextColor(klineView.configManager.textColor);
        klineView.setTextSize(klineView.configManager.rightTextFontSize);
        klineView.setMTextSize(klineView.configManager.candleTextFontSize);
        klineView.setMTextColor(klineView.configManager.candleTextColor);
        klineView.reloadColor();
        Boolean isEnd = klineView.getScrollOffset() >= klineView.getMaxScrollX();
        klineView.notifyChanged();
        if (isEnd || klineView.configManager.shouldScrollToEnd) {
            klineView.setScrollX(klineView.getMaxScrollX());
        }

        configManager.onDrawItemDidTouch = new HTKLineCallback() {
            @Override
            public void invoke(Object... args) {
                HTDrawItem drawItem = (HTDrawItem) args[0];
                int drawItemIndex = (int) args[1];
                configManager.shouldReloadDrawItemIndex = drawItemIndex;

                java.util.HashMap<String, Object> map = new java.util.HashMap<>();
                if (drawItem != null) {
                    int drawColor = drawItem.drawColor;
                    int alpha = (drawColor >> 24) & 0xFF;
                    int red = (drawColor >> 16) & 0xFF;
                    int green = (drawColor >> 8) & 0xFF;
                    int blue = (drawColor) & 0xFF;
                    double[] colorList = new double[]{red / 255.0, green / 255.0, blue / 255.0, alpha / 255.0};
                    map.put("drawColor", colorList);
                    map.put("drawLineHeight", drawItem.drawLineHeight);
                    map.put("drawDashWidth", drawItem.drawDashWidth);
                    map.put("drawDashSpace", drawItem.drawDashSpace);
                    map.put("drawIsLock", drawItem.drawIsLock);
                }
                map.put("shouldReloadDrawItemIndex", drawItemIndex);
                if (onDrawItemDidTouch != null) {
                    onDrawItemDidTouch.onDrawItemDidTouch(map);
                }
            }
        };
        configManager.onDrawItemComplete = new HTKLineCallback() {
            @Override
            public void invoke(Object... args) {
                if (onDrawItemComplete != null) {
                    onDrawItemComplete.onDrawItemComplete();
                }
            }
        };
        configManager.onDrawPointComplete = new HTKLineCallback() {
            @Override
            public void invoke(Object... args) {
                HTDrawItem drawItem = (HTDrawItem) args[0];
                if (onDrawPointComplete != null && drawItem != null) {
                    onDrawPointComplete.onDrawPointComplete(drawItem.pointList.size());
                }
            }
        };

        int reloadIndex = configManager.shouldReloadDrawItemIndex;
        if (reloadIndex >= 0 && reloadIndex < klineView.drawContext.drawItemList.size()) {
            HTDrawItem drawItem = klineView.drawContext.drawItemList.get(reloadIndex);
            drawItem.drawColor = configManager.drawColor;
            drawItem.drawLineHeight = configManager.drawLineHeight;
            drawItem.drawDashWidth = configManager.drawDashWidth;
            drawItem.drawDashSpace = configManager.drawDashSpace;
            drawItem.drawIsLock = configManager.drawIsLock;
            if (configManager.drawShouldTrash) {
                configManager.shouldReloadDrawItemIndex = HTDrawState.showPencil;
                klineView.drawContext.drawItemList.remove(reloadIndex);
                configManager.drawShouldTrash = false;
            }
            klineView.drawContext.invalidate();
        }

        if (configManager.shouldFixDraw) {
            configManager.shouldFixDraw = false;
            klineView.drawContext.fixDrawItemList();
        }
        if (configManager.shouldClearDraw) {
            configManager.shouldReloadDrawItemIndex = HTDrawState.none;
            configManager.shouldClearDraw = false;
            klineView.drawContext.clearDrawItemList();
        }

    }

    private HTPoint convertLocation(HTPoint location) {
        HTPoint reloadLocation = new HTPoint(location.x, location.y);
        reloadLocation.x = Math.max(0, Math.min(reloadLocation.x, getWidth()));
        reloadLocation.y = Math.max(0, Math.min(reloadLocation.y, getHeight()));
        reloadLocation = klineView.valuePointFromViewPoint(reloadLocation);
        return reloadLocation;
    }

    @Override
    public boolean onInterceptTouchEvent(MotionEvent event) {
        int reloadIndex = configManager.shouldReloadDrawItemIndex;
        switch (reloadIndex) {
            case HTDrawState.none: {
                return false;
            }
            case HTDrawState.showPencil: {
                if (configManager.drawType == HTDrawType.none) {
                    HTPoint location = new HTPoint(event.getX(), event.getY());
                    location = convertLocation(location);
                    if ((HTDrawItem.canResponseLocation(klineView.drawContext.drawItemList, location, klineView)) == null) {
                        return false;
                    }
                }
            }
        }
        return true;
    }

    private HTPoint lastLocation;

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        handlerDraw(event);
        handlerShot(event);
        return true;
    }

    private void handlerShot(MotionEvent event) {
        if (shotView == null) {
            return;
        }
        if (event.getAction() == MotionEvent.ACTION_UP || event.getAction() == MotionEvent.ACTION_CANCEL) {
            shotView.setPoint(null);
            return;
        }
        HTPoint location = new HTPoint(event.getX(), event.getY());
        location = convertLocation(location);
        shotView.setPoint(location);
    }

    private void handlerDraw(MotionEvent event) {
        if (klineView == null) {
            return;
        }
        HTPoint location = new HTPoint(event.getX(), event.getY());
        location = convertLocation(location);
        HTPoint previousLocation = lastLocation != null ? lastLocation : location;
        lastLocation = location;
        int state = event.getAction();
        if (state == MotionEvent.ACTION_CANCEL) {
            state = MotionEvent.ACTION_UP;
        }
        HTPoint translation = new HTPoint(
                location.x - previousLocation.x,
                location.y - previousLocation.y
        );
        if (event.getAction() == MotionEvent.ACTION_UP || event.getAction() == MotionEvent.ACTION_CANCEL) {
            lastLocation = null;
        }
        klineView.drawContext.touchesGesture(location, translation, state);
    }
}
