import UIKit
import NativeKLineView

final class ViewController: UIViewController {
    private let klineView = NativeKLineView()
    private let toolbar = UIView()
    private let titleLabel = UILabel()
    private let themeLabel = UILabel()
    private let themeSwitch = UISwitch()
    private let chartContainer = UIView()

    private let controlBar = UIView()
    private let timeButton = UIButton(type: .system)
    private let indicatorButton = UIButton(type: .system)
    private let drawButton = UIButton(type: .system)
    private let clearButton = UIButton(type: .system)

    private var isDarkTheme = false
    private var selectedTimeType = 2
    private var selectedMainIndicator = 1
    private var selectedSubIndicator = 3
    private var selectedDrawTool = DrawTypeConstants.none
    private var drawShouldContinue = true
    private var klineData: [KLineItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        configureDefaults()
        setupUI()
        reloadKLineData()
    }

    private func configureDefaults() {
        let isHorizontalScreen = UIScreen.main.bounds.width > UIScreen.main.bounds.height
        selectedSubIndicator = isHorizontalScreen ? 0 : 3
        klineData = generateMockData()
    }

    private func setupUI() {
        view.backgroundColor = .white
        klineView.translatesAutoresizingMaskIntoConstraints = false
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        controlBar.translatesAutoresizingMaskIntoConstraints = false

        setupToolbar()
        setupControlBar()

        chartContainer.translatesAutoresizingMaskIntoConstraints = false
        chartContainer.addSubview(klineView)

        view.addSubview(toolbar)
        view.addSubview(chartContainer)
        view.addSubview(controlBar)

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 56),

            chartContainer.topAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: 8),
            chartContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            chartContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),

            controlBar.topAnchor.constraint(equalTo: chartContainer.bottomAnchor, constant: 8),
            controlBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlBar.heightAnchor.constraint(equalToConstant: 56),
            controlBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            klineView.topAnchor.constraint(equalTo: chartContainer.topAnchor),
            klineView.leadingAnchor.constraint(equalTo: chartContainer.leadingAnchor),
            klineView.trailingAnchor.constraint(equalTo: chartContainer.trailingAnchor),
            klineView.bottomAnchor.constraint(equalTo: chartContainer.bottomAnchor)
        ])

        chartContainer.layer.cornerRadius = 8
        chartContainer.layer.borderWidth = 1
        chartContainer.clipsToBounds = true
        chartContainer.backgroundColor = .clear

        klineView.backgroundColor = .clear

        applyTheme()
    }

    private func setupToolbar() {
        toolbar.layer.borderWidth = 1

        titleLabel.text = "K线图表"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        themeLabel.font = UIFont.systemFont(ofSize: 14)
        themeLabel.translatesAutoresizingMaskIntoConstraints = false

        themeSwitch.addTarget(self, action: #selector(toggleTheme), for: .valueChanged)
        themeSwitch.translatesAutoresizingMaskIntoConstraints = false

        toolbar.addSubview(titleLabel)
        toolbar.addSubview(themeLabel)
        toolbar.addSubview(themeSwitch)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),

            themeSwitch.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor, constant: -16),
            themeSwitch.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),

            themeLabel.trailingAnchor.constraint(equalTo: themeSwitch.leadingAnchor, constant: -8),
            themeLabel.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor)
        ])
    }

    private func setupControlBar() {
        controlBar.layer.borderWidth = 1

        let stack = UIStackView(arrangedSubviews: [timeButton, indicatorButton, drawButton, clearButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fillEqually
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        controlBar.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: controlBar.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: controlBar.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: controlBar.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: controlBar.bottomAnchor, constant: -8)
        ])

        configureButton(timeButton, action: #selector(showTimeSelector))
        configureButton(indicatorButton, action: #selector(showIndicatorSelector))
        configureButton(drawButton, action: #selector(showDrawToolSelector))
        configureButton(clearButton, action: #selector(clearDrawings))

        updateControlButtonTitles()
    }

    private func configureButton(_ button: UIButton, action: Selector) {
        button.addTarget(self, action: action, for: .touchUpInside)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
    }

    private func updateControlButtonTitles() {
        timeButton.setTitle(TimeTypes[selectedTimeType]?.label ?? "", for: .normal)

        let mainLabel = IndicatorTypes.main[selectedMainIndicator]?.label ?? ""
        let subLabel = IndicatorTypes.sub[selectedSubIndicator]?.label ?? ""
        indicatorButton.setTitle("\(mainLabel)/\(subLabel)", for: .normal)

        let drawTitle = selectedDrawTool == DrawTypeConstants.none ? "绘图" : (DrawToolHelper.name(type: selectedDrawTool) ?? "绘图")
        drawButton.setTitle(drawTitle, for: .normal)
        clearButton.setTitle("清除", for: .normal)
    }

    @objc private func toggleTheme() {
        isDarkTheme = themeSwitch.isOn
        applyTheme()
        reloadKLineData()
    }

    private func applyTheme() {
        let theme = ThemeManager.currentTheme(isDark: isDarkTheme)
        view.backgroundColor = UIColor(colorInt: theme.backgroundColor)
        toolbar.backgroundColor = UIColor(colorInt: theme.headerColor)
        toolbar.layer.borderColor = UIColor(colorInt: theme.gridColor).cgColor
        controlBar.backgroundColor = UIColor(colorInt: theme.headerColor)
        controlBar.layer.borderColor = UIColor(colorInt: theme.gridColor).cgColor
        chartContainer.layer.borderColor = UIColor(colorInt: theme.gridColor).cgColor

        titleLabel.textColor = UIColor(colorInt: theme.textColor)
        themeLabel.textColor = UIColor(colorInt: theme.textColor)
        themeLabel.text = isDarkTheme ? "夜间" : "日间"

        [timeButton, indicatorButton, drawButton, clearButton].forEach { button in
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = UIColor(colorInt: theme.buttonColor)
        }

        if selectedDrawTool != DrawTypeConstants.none {
            drawButton.backgroundColor = UIColor(colorInt: theme.increaseColor)
        }

        setNeedsStatusBarAppearanceUpdate()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return isDarkTheme ? .lightContent : .darkContent
    }

    @objc private func showTimeSelector() {
        let alert = UIAlertController(title: "选择时间周期", message: nil, preferredStyle: .actionSheet)
        let sortedKeys = TimeTypes.keys.sorted()
        for key in sortedKeys {
            guard let item = TimeTypes[key] else { continue }
            alert.addAction(UIAlertAction(title: item.label, style: .default, handler: { [weak self] _ in
                self?.selectedTimeType = key
                self?.klineData = self?.generateMockData() ?? []
                self?.updateControlButtonTitles()
                self?.reloadKLineData()
            }))
        }
        alert.addAction(UIAlertAction(title: "关闭", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func showIndicatorSelector() {
        let alert = UIAlertController(title: "选择指标", message: nil, preferredStyle: .actionSheet)

        IndicatorTypes.main.keys.sorted().forEach { key in
            if let item = IndicatorTypes.main[key] {
                alert.addAction(UIAlertAction(title: "主图: \(item.label)", style: .default, handler: { [weak self] _ in
                    self?.selectedMainIndicator = key
                    self?.updateControlButtonTitles()
                    self?.reloadKLineData()
                }))
            }
        }

        IndicatorTypes.sub.keys.sorted().forEach { key in
            if let item = IndicatorTypes.sub[key] {
                alert.addAction(UIAlertAction(title: "副图: \(item.label)", style: .default, handler: { [weak self] _ in
                    self?.selectedSubIndicator = key
                    self?.updateControlButtonTitles()
                    self?.reloadKLineData()
                }))
            }
        }

        alert.addAction(UIAlertAction(title: "关闭", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func showDrawToolSelector() {
        let alert = UIAlertController(title: "绘图工具", message: nil, preferredStyle: .actionSheet)
        DrawToolTypes.order.forEach { key in
            if let item = DrawToolTypes.list[key] {
                alert.addAction(UIAlertAction(title: item.label, style: .default, handler: { [weak self] _ in
                    self?.selectDrawTool(key)
                }))
            }
        }

        let continueTitle = drawShouldContinue ? "连续绘图: 开" : "连续绘图: 关"
        alert.addAction(UIAlertAction(title: continueTitle, style: .default, handler: { [weak self] _ in
            self?.drawShouldContinue.toggle()
        }))

        alert.addAction(UIAlertAction(title: "关闭", style: .cancel))
        present(alert, animated: true)
    }

    private func selectDrawTool(_ tool: Int) {
        selectedDrawTool = tool
        updateControlButtonTitles()
        setOptionList(optionList: [
            "drawList": [
                "shouldReloadDrawItemIndex": tool == DrawTypeConstants.none ? DrawStateConstants.none : DrawStateConstants.showContext,
                "drawShouldContinue": drawShouldContinue,
                "drawType": tool,
                "shouldFixDraw": false
            ]
        ])
        applyTheme()
    }

    @objc private func clearDrawings() {
        selectedDrawTool = DrawTypeConstants.none
        updateControlButtonTitles()
        setOptionList(optionList: [
            "drawList": [
                "shouldReloadDrawItemIndex": DrawStateConstants.none,
                "shouldClearDraw": true
            ]
        ])
        applyTheme()
    }

    private func reloadKLineData() {
        let processed = processKLineData(rawData: klineData)
        let optionList = packOptionList(modelArray: processed)
        setOptionList(optionList: optionList)
    }

    private func setOptionList(optionList: [String: Any]) {
        if let jsonData = try? JSONSerialization.data(withJSONObject: optionList, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            klineView.optionList = jsonString
        }
    }
}

// MARK: - Data & Config

private extension ViewController {
    func generateMockData() -> [KLineItem] {
        var data: [KLineItem] = []
        var lastClose: Double = 50000
        let now = Date().timeIntervalSince1970 * 1000

        for i in 0..<200 {
            let time = now - Double(200 - i) * 15 * 60 * 1000
            let open = lastClose
            let volatility = 0.02
            let change = (Double.random(in: 0..<1) - 0.5) * open * volatility
            let close = max(open + change, open * 0.95)

            let maxPrice = max(open, close)
            let minPrice = min(open, close)
            let high = maxPrice + Double.random(in: 0..<1) * open * 0.01
            let low = minPrice - Double.random(in: 0..<1) * open * 0.01

            let volume = (0.5 + Double.random(in: 0..<1)) * 1_000_000

            data.append(KLineItem(
                time: time,
                open: open.rounded(toPlaces: 2),
                high: high.rounded(toPlaces: 2),
                low: low.rounded(toPlaces: 2),
                close: close.rounded(toPlaces: 2),
                volume: volume.rounded(toPlaces: 2)
            ))
            lastClose = close
        }

        return data
    }

    func processKLineData(rawData: [KLineItem]) -> [KLineItem] {
        let symbolPrice = 2
        let volumeCount = 0
        let targetList = getTargetList()

        var processed = rawData.map { item -> KLineItem in
            var copy = item
            copy.id = item.time
            copy.vol = item.volume
            return copy
        }

        processed = calculateIndicatorsFromTargetList(data: processed, targetList: targetList)

        return processed.map { item in
            var copy = item
            let timeString = formatTime(timestamp: item.id, format: "MM-DD HH:mm")
            let appendValue = item.close - item.open
            let appendPercent = appendValue / item.open * 100
            let isAppend = appendValue >= 0
            let prefixString = isAppend ? "+" : "-"
            let appendValueString = prefixString + fixRound(value: abs(appendValue), precision: symbolPrice, showSign: true, showGrouping: false)
            let appendPercentString = prefixString + fixRound(value: abs(appendPercent), precision: 2, showSign: true, showGrouping: false) + "%"

            let theme = ThemeManager.currentTheme(isDark: isDarkTheme)
            let color = isAppend ? theme.increaseColor : theme.decreaseColor

            copy.dateString = timeString
            copy.selectedItemList = [
                ["title": "时间", "detail": timeString],
                ["title": "开", "detail": fixRound(value: item.open, precision: symbolPrice, showSign: true, showGrouping: false)],
                ["title": "高", "detail": fixRound(value: item.high, precision: symbolPrice, showSign: true, showGrouping: false)],
                ["title": "低", "detail": fixRound(value: item.low, precision: symbolPrice, showSign: true, showGrouping: false)],
                ["title": "收", "detail": fixRound(value: item.close, precision: symbolPrice, showSign: true, showGrouping: false)],
                ["title": "涨跌额", "detail": appendValueString, "color": color],
                ["title": "涨跌幅", "detail": appendPercentString, "color": color],
                ["title": "成交量", "detail": fixRound(value: item.vol, precision: volumeCount, showSign: true, showGrouping: false)]
            ]

            addIndicatorToSelectedList(item: &copy, targetList: targetList, priceCount: symbolPrice)
            return copy
        }
    }

    func packOptionList(modelArray: [KLineItem]) -> [String: Any] {
        let theme = ThemeManager.currentTheme(isDark: isDarkTheme)
        let pixelRatio: Double = 1

        let configList: [String: Any] = [
            "colorList": [
                "increaseColor": theme.increaseColor,
                "decreaseColor": theme.decreaseColor
            ],
            "targetColorList": [
                color(0.96, 0.86, 0.58),
                color(0.38, 0.82, 0.75),
                color(0.8, 0.57, 1),
                color(1, 0.23, 0.24),
                color(0.44, 0.82, 0.03),
                color(0.44, 0.13, 1)
            ],
            "minuteLineColor": theme.minuteLineColor,
            "minuteGradientColorList": [
                color(0.094117647, 0.341176471, 0.831372549, 0.149019608),
                color(0.266666667, 0.501960784, 0.972549020, 0.149019608),
                color(0.074509804, 0.121568627, 0.188235294, 0),
                color(0.074509804, 0.121568627, 0.188235294, 0)
            ],
            "minuteGradientLocationList": [0, 0.3, 0.6, 1],
            "backgroundColor": theme.backgroundColor,
            "textColor": theme.detailColor,
            "gridColor": theme.gridColor,
            "candleTextColor": theme.titleColor,
            "panelBackgroundColor": isDarkTheme ? color(0.03, 0.09, 0.14, 0.9) : color(1, 1, 1, 0.95),
            "panelBorderColor": theme.detailColor,
            "panelTextColor": theme.titleColor,
            "selectedPointContainerColor": color(0, 0, 0, 0),
            "selectedPointContentColor": isDarkTheme ? theme.titleColor : color(1, 1, 1),
            "closePriceCenterBackgroundColor": theme.backgroundColor9703,
            "closePriceCenterBorderColor": theme.textColor7724,
            "closePriceCenterTriangleColor": theme.textColor7724,
            "closePriceCenterSeparatorColor": theme.detailColor,
            "closePriceRightBackgroundColor": theme.backgroundColor,
            "closePriceRightSeparatorColor": theme.backgroundColorBlue,
            "closePriceRightLightLottieFloder": "images",
            "closePriceRightLightLottieScale": 0.4,
            "panelGradientColorList": isDarkTheme ? [
                color(0.0588235, 0.101961, 0.160784, 0.2),
                color(0.811765, 0.827451, 0.913725, 0.101961),
                color(0.811765, 0.827451, 0.913725, 0.2),
                color(0.811765, 0.827451, 0.913725, 0.101961),
                color(0.0784314, 0.141176, 0.223529, 0.2)
            ] : [
                color(1, 1, 1, 0),
                color(0.54902, 0.623529, 0.678431, 0.101961),
                color(0.54902, 0.623529, 0.678431, 0.25098),
                color(0.54902, 0.623529, 0.678431, 0.101961),
                color(1, 1, 1, 0)
            ],
            "panelGradientLocationList": [0, 0.25, 0.5, 0.75, 1],
            "mainFlex": selectedSubIndicator == 0 ? (isHorizontal() ? 0.75 : 0.85) : 0.6,
            "volumeFlex": isHorizontal() ? 0.25 : 0.15,
            "paddingTop": 20 * pixelRatio,
            "paddingBottom": 20 * pixelRatio,
            "paddingRight": 50 * pixelRatio,
            "itemWidth": 8 * pixelRatio,
            "candleWidth": 6 * pixelRatio,
            "minuteVolumeCandleColor": color(0.0941176, 0.509804, 0.831373, 0.501961),
            "minuteVolumeCandleWidth": 2 * pixelRatio,
            "macdCandleWidth": 1 * pixelRatio,
            "headerTextFontSize": 10 * pixelRatio,
            "rightTextFontSize": 10 * pixelRatio,
            "candleTextFontSize": 10 * pixelRatio,
            "panelTextFontSize": 10 * pixelRatio,
            "panelMinWidth": 130 * pixelRatio,
            "fontFamily": "DINPro-Medium",
            "closePriceRightLightLottieSource": ""
        ]

        let drawList: [String: Any] = [
            "shotBackgroundColor": theme.backgroundColor,
            "drawType": selectedDrawTool,
            "shouldReloadDrawItemIndex": DrawStateConstants.none,
            "drawShouldContinue": drawShouldContinue,
            "drawColor": color(1, 0.46, 0.05),
            "drawLineHeight": 2,
            "drawDashWidth": 4,
            "drawDashSpace": 4,
            "drawIsLock": false,
            "shouldFixDraw": false,
            "shouldClearDraw": false
        ]

        return [
            "modelArray": modelArray.map { $0.toDictionary() },
            "shouldScrollToEnd": true,
            "targetList": getTargetList().asDictionary(),
            "price": 2,
            "volume": 0,
            "primary": selectedMainIndicator,
            "second": selectedSubIndicator,
            "time": TimeTypes[selectedTimeType]?.value ?? TimeConstants.oneMinute,
            "configList": configList,
            "drawList": drawList
        ]
    }
}

// MARK: - Indicator Calculations

private extension ViewController {
    func calculateIndicatorsFromTargetList(data: [KLineItem], targetList: TargetList) -> [KLineItem] {
        var processed = data

        let selectedMAPeriods = targetList.maList.filter { $0.selected }.map { ($0.period, $0.index) }
        if !selectedMAPeriods.isEmpty {
            processed = calculateMAWithConfig(data: processed, periodConfigs: selectedMAPeriods)
        }

        let selectedVolumeMAPeriods = targetList.maVolumeList.filter { $0.selected }.map { ($0.period, $0.index) }
        if !selectedVolumeMAPeriods.isEmpty {
            processed = calculateVolumeMAWithConfig(data: processed, periodConfigs: selectedVolumeMAPeriods)
        }

        if isBOLLSelected() {
            processed = calculateBOLL(data: processed, n: targetList.bollN, p: targetList.bollP)
        }

        if isMACDSelected() {
            processed = calculateMACD(data: processed, s: targetList.macdS, l: targetList.macdL, m: targetList.macdM)
        }

        if isKDJSelected() {
            processed = calculateKDJ(data: processed, n: targetList.kdjN, m1: targetList.kdjM1, m2: targetList.kdjM2)
        }

        let selectedRSIPeriods = targetList.rsiList.filter { $0.selected }.map { ($0.period, $0.index) }
        if !selectedRSIPeriods.isEmpty {
            processed = calculateRSIWithConfig(data: processed, periodConfigs: selectedRSIPeriods)
        }

        let selectedWRPeriods = targetList.wrList.filter { $0.selected }.map { ($0.period, $0.index) }
        if !selectedWRPeriods.isEmpty {
            processed = calculateWRWithConfig(data: processed, periodConfigs: selectedWRPeriods)
        }

        return processed
    }

    func calculateMAWithConfig(data: [KLineItem], periodConfigs: [(Int, Int)]) -> [KLineItem] {
        return data.enumerated().map { index, item in
            var copy = item
            var maList = Array<MAItem?>(repeating: nil, count: 3)
            for (period, maIndex) in periodConfigs {
                if index < period - 1 {
                    maList[maIndex] = MAItem(value: item.close, title: "\(period)")
                } else {
                    var sum: Double = 0
                    for i in (index - period + 1)...index {
                        sum += data[i].close
                    }
                    maList[maIndex] = MAItem(value: sum / Double(period), title: "\(period)")
                }
            }
            copy.maList = maList
            return copy
        }
    }

    func calculateVolumeMAWithConfig(data: [KLineItem], periodConfigs: [(Int, Int)]) -> [KLineItem] {
        return data.enumerated().map { index, item in
            var copy = item
            var maVolumeList = Array<MAItem?>(repeating: nil, count: 2)
            for (period, maIndex) in periodConfigs {
                if index < period - 1 {
                    maVolumeList[maIndex] = MAItem(value: item.volume, title: "\(period)")
                } else {
                    var sum: Double = 0
                    for i in (index - period + 1)...index {
                        sum += data[i].volume
                    }
                    maVolumeList[maIndex] = MAItem(value: sum / Double(period), title: "\(period)")
                }
            }
            copy.maVolumeList = maVolumeList
            return copy
        }
    }

    func calculateBOLL(data: [KLineItem], n: Int, p: Int) -> [KLineItem] {
        return data.enumerated().map { index, item in
            var copy = item
            if index < n - 1 {
                copy.bollMb = item.close
                copy.bollUp = item.close
                copy.bollDn = item.close
                return copy
            }

            var sum: Double = 0
            for i in (index - n + 1)...index {
                sum += data[i].close
            }
            let ma = sum / Double(n)

            var variance: Double = 0
            for i in (index - n + 1)...index {
                variance += pow(data[i].close - ma, 2)
            }
            let std = sqrt(variance / Double(n - 1))

            copy.bollMb = ma
            copy.bollUp = ma + Double(p) * std
            copy.bollDn = ma - Double(p) * std
            return copy
        }
    }

    func calculateMACD(data: [KLineItem], s: Int, l: Int, m: Int) -> [KLineItem] {
        var ema12 = data.first?.close ?? 0
        var ema26 = data.first?.close ?? 0
        var dea: Double = 0

        return data.enumerated().map { index, item in
            var copy = item
            if index == 0 {
                copy.macdValue = 0
                copy.macdDea = 0
                copy.macdDif = 0
                return copy
            }

            ema12 = (2 * item.close + Double(s - 1) * ema12) / Double(s + 1)
            ema26 = (2 * item.close + Double(l - 1) * ema26) / Double(l + 1)
            let dif = ema12 - ema26
            dea = (2 * dif + Double(m - 1) * dea) / Double(m + 1)
            let macd = 2 * (dif - dea)

            copy.macdValue = macd
            copy.macdDea = dea
            copy.macdDif = dif
            return copy
        }
    }

    func calculateKDJ(data: [KLineItem], n: Int, m1: Int, m2: Int) -> [KLineItem] {
        var k: Double = 50
        var d: Double = 50

        return data.enumerated().map { index, item in
            var copy = item
            if index == 0 {
                copy.kdjK = k
                copy.kdjD = d
                copy.kdjJ = 3 * k - 2 * d
                return copy
            }

            let startIndex = max(0, index - n + 1)
            var highest = -Double.greatestFiniteMagnitude
            var lowest = Double.greatestFiniteMagnitude
            for i in startIndex...index {
                highest = max(highest, data[i].high)
                lowest = min(lowest, data[i].low)
            }

            let rsv = highest == lowest ? 50 : ((item.close - lowest) / (highest - lowest)) * 100
            k = (rsv + Double(m1 - 1) * k) / Double(m1)
            d = (k + Double(m1 - 1) * d) / Double(m1)
            let j = Double(m2) * k - 2 * d

            copy.kdjK = k
            copy.kdjD = d
            copy.kdjJ = j
            return copy
        }
    }

    func calculateRSIWithConfig(data: [KLineItem], periodConfigs: [(Int, Int)]) -> [KLineItem] {
        return data.enumerated().map { index, item in
            var copy = item
            var rsiList = Array<IndicatorItem?>(repeating: nil, count: 3)

            if index == 0 {
                for (period, rsiIndex) in periodConfigs {
                    rsiList[rsiIndex] = IndicatorItem(value: 50, index: rsiIndex, title: "\(period)")
                }
                copy.rsiList = rsiList
                return copy
            }

            for (period, rsiIndex) in periodConfigs {
                if index < period {
                    rsiList[rsiIndex] = IndicatorItem(value: 50, index: rsiIndex, title: "\(period)")
                    continue
                }

                var gains: Double = 0
                var losses: Double = 0
                for i in (index - period + 1)...index {
                    let change = data[i].close - data[i - 1].close
                    if change > 0 {
                        gains += change
                    } else {
                        losses += abs(change)
                    }
                }

                let avgGain = gains / Double(period)
                let avgLoss = losses / Double(period)
                let rs = avgLoss == 0 ? 100 : avgGain / avgLoss
                let rsi = 100 - (100 / (1 + rs))
                rsiList[rsiIndex] = IndicatorItem(value: rsi, index: rsiIndex, title: "\(period)")
            }

            copy.rsiList = rsiList
            return copy
        }
    }

    func calculateWRWithConfig(data: [KLineItem], periodConfigs: [(Int, Int)]) -> [KLineItem] {
        return data.enumerated().map { index, item in
            var copy = item
            var wrList = Array<IndicatorItem?>(repeating: nil, count: 1)

            for (period, wrIndex) in periodConfigs {
                if index < period - 1 {
                    wrList[wrIndex] = IndicatorItem(value: -50, index: wrIndex, title: "\(period)")
                    continue
                }

                var highest = -Double.greatestFiniteMagnitude
                var lowest = Double.greatestFiniteMagnitude
                for i in (index - period + 1)...index {
                    highest = max(highest, data[i].high)
                    lowest = min(lowest, data[i].low)
                }

                let wr = highest == lowest ? -50 : -((highest - item.close) / (highest - lowest)) * 100
                wrList[wrIndex] = IndicatorItem(value: wr, index: wrIndex, title: "\(period)")
            }

            copy.wrList = wrList
            return copy
        }
    }

    func addIndicatorToSelectedList(item: inout KLineItem, targetList: TargetList, priceCount: Int) {
        if isMASelected(), let maList = item.maList {
            for maItem in maList {
                if let maItem, !maItem.title.isEmpty {
                    item.selectedItemList.append([
                        "title": "MA\(maItem.title)",
                        "detail": fixRound(value: maItem.value, precision: priceCount, showSign: false, showGrouping: false)
                    ])
                }
            }
        }

        if isBOLLSelected(), let bollMb = item.bollMb, let bollUp = item.bollUp, let bollDn = item.bollDn {
            item.selectedItemList.append(contentsOf: [
                ["title": "BOLL上", "detail": fixRound(value: bollUp, precision: priceCount, showSign: false, showGrouping: false)],
                ["title": "BOLL中", "detail": fixRound(value: bollMb, precision: priceCount, showSign: false, showGrouping: false)],
                ["title": "BOLL下", "detail": fixRound(value: bollDn, precision: priceCount, showSign: false, showGrouping: false)]
            ])
        }

        if isMACDSelected(), let dif = item.macdDif, let dea = item.macdDea, let macd = item.macdValue {
            item.selectedItemList.append(contentsOf: [
                ["title": "DIF", "detail": fixRound(value: dif, precision: 4, showSign: false, showGrouping: false)],
                ["title": "DEA", "detail": fixRound(value: dea, precision: 4, showSign: false, showGrouping: false)],
                ["title": "MACD", "detail": fixRound(value: macd, precision: 4, showSign: false, showGrouping: false)]
            ])
        }

        if isKDJSelected(), let k = item.kdjK, let d = item.kdjD, let j = item.kdjJ {
            item.selectedItemList.append(contentsOf: [
                ["title": "K", "detail": fixRound(value: k, precision: 2, showSign: false, showGrouping: false)],
                ["title": "D", "detail": fixRound(value: d, precision: 2, showSign: false, showGrouping: false)],
                ["title": "J", "detail": fixRound(value: j, precision: 2, showSign: false, showGrouping: false)]
            ])
        }

        if isRSISelected(), let rsiList = item.rsiList {
            for rsiItem in rsiList {
                if let rsiItem {
                    item.selectedItemList.append([
                        "title": "RSI\(rsiItem.title)",
                        "detail": fixRound(value: rsiItem.value, precision: 2, showSign: false, showGrouping: false)
                    ])
                }
            }
        }

        if isWRSelected(), let wrList = item.wrList {
            for wrItem in wrList {
                if let wrItem {
                    item.selectedItemList.append([
                        "title": "WR\(wrItem.title)",
                        "detail": fixRound(value: wrItem.value, precision: 2, showSign: false, showGrouping: false)
                    ])
                }
            }
        }
    }
}

// MARK: - Helpers & Models

private extension ViewController {
    func isHorizontal() -> Bool {
        return UIScreen.main.bounds.width > UIScreen.main.bounds.height
    }

    func isMASelected() -> Bool { selectedMainIndicator == 1 }
    func isBOLLSelected() -> Bool { selectedMainIndicator == 2 }
    func isMACDSelected() -> Bool { selectedSubIndicator == 3 }
    func isKDJSelected() -> Bool { selectedSubIndicator == 4 }
    func isRSISelected() -> Bool { selectedSubIndicator == 5 }
    func isWRSelected() -> Bool { selectedSubIndicator == 6 }

    func getTargetList() -> TargetList {
        return TargetList(
            maList: [
                TargetItem(title: "5", selected: isMASelected(), index: 0),
                TargetItem(title: "10", selected: isMASelected(), index: 1),
                TargetItem(title: "20", selected: isMASelected(), index: 2)
            ],
            maVolumeList: [
                TargetItem(title: "5", selected: true, index: 0),
                TargetItem(title: "10", selected: true, index: 1)
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
                TargetItem(title: "6", selected: isRSISelected(), index: 0),
                TargetItem(title: "12", selected: isRSISelected(), index: 1),
                TargetItem(title: "24", selected: isRSISelected(), index: 2)
            ],
            wrList: [
                TargetItem(title: "14", selected: isWRSelected(), index: 0)
            ]
        )
    }
}

private struct KLineItem {
    var time: Double
    var open: Double
    var high: Double
    var low: Double
    var close: Double
    var volume: Double

    var id: Double = 0
    var vol: Double = 0
    var dateString: String = ""
    var selectedItemList: [[String: Any]] = []

    var maList: [MAItem?]?
    var maVolumeList: [MAItem?]?
    var bollMb: Double?
    var bollUp: Double?
    var bollDn: Double?
    var macdValue: Double?
    var macdDea: Double?
    var macdDif: Double?
    var kdjK: Double?
    var kdjD: Double?
    var kdjJ: Double?
    var rsiList: [IndicatorItem?]?
    var wrList: [IndicatorItem?]?

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "time": time,
            "open": open,
            "high": high,
            "low": low,
            "close": close,
            "volume": volume,
            "id": id,
            "vol": vol,
            "dateString": dateString,
            "selectedItemList": selectedItemList
        ]

        if let maList {
            dict["maList"] = maList.map { $0?.toDictionary() as Any }
        }
        if let maVolumeList {
            dict["maVolumeList"] = maVolumeList.map { $0?.toDictionary() as Any }
        }
        if let bollMb { dict["bollMb"] = bollMb }
        if let bollUp { dict["bollUp"] = bollUp }
        if let bollDn { dict["bollDn"] = bollDn }
        if let macdValue { dict["macdValue"] = macdValue }
        if let macdDea { dict["macdDea"] = macdDea }
        if let macdDif { dict["macdDif"] = macdDif }
        if let kdjK { dict["kdjK"] = kdjK }
        if let kdjD { dict["kdjD"] = kdjD }
        if let kdjJ { dict["kdjJ"] = kdjJ }
        if let rsiList {
            dict["rsiList"] = rsiList.map { $0?.toDictionary() as Any }
        }
        if let wrList {
            dict["wrList"] = wrList.map { $0?.toDictionary() as Any }
        }

        return dict
    }
}

private struct MAItem {
    let value: Double
    let title: String

    func toDictionary() -> [String: Any] {
        return ["value": value, "title": title]
    }
}

private struct IndicatorItem {
    let value: Double
    let index: Int
    let title: String

    func toDictionary() -> [String: Any] {
        return ["value": value, "index": index, "title": title]
    }
}

private struct TargetItem {
    let title: String
    let selected: Bool
    let index: Int

    var period: Int { Int(title) ?? 0 }

    func toDictionary() -> [String: Any] {
        ["title": title, "selected": selected, "index": index]
    }
}

private struct TargetList {
    let maList: [TargetItem]
    let maVolumeList: [TargetItem]
    let bollN: Int
    let bollP: Int
    let macdS: Int
    let macdL: Int
    let macdM: Int
    let kdjN: Int
    let kdjM1: Int
    let kdjM2: Int
    let rsiList: [TargetItem]
    let wrList: [TargetItem]

    func asDictionary() -> [String: Any] {
        return [
            "maList": maList.map { $0.toDictionary() },
            "maVolumeList": maVolumeList.map { $0.toDictionary() },
            "bollN": "\(bollN)",
            "bollP": "\(bollP)",
            "macdS": "\(macdS)",
            "macdL": "\(macdL)",
            "macdM": "\(macdM)",
            "kdjN": "\(kdjN)",
            "kdjM1": "\(kdjM1)",
            "kdjM2": "\(kdjM2)",
            "rsiList": rsiList.map { $0.toDictionary() },
            "wrList": wrList.map { $0.toDictionary() }
        ]
    }
}

private struct TimeType {
    let label: String
    let value: Int
}

private enum TimeConstants {
    static let oneMinute = 1
    static let threeMinute = 2
    static let fiveMinute = 3
    static let fifteenMinute = 4
    static let thirtyMinute = 5
    static let oneHour = 6
    static let fourHour = 7
    static let sixHour = 8
    static let oneDay = 9
    static let oneWeek = 10
    static let oneMonth = 11
    static let minuteHour = -1
}

private let TimeTypes: [Int: TimeType] = [
    1: TimeType(label: "分时", value: TimeConstants.minuteHour),
    2: TimeType(label: "1分钟", value: TimeConstants.oneMinute),
    3: TimeType(label: "3分钟", value: TimeConstants.threeMinute),
    4: TimeType(label: "5分钟", value: TimeConstants.fiveMinute),
    5: TimeType(label: "15分钟", value: TimeConstants.fifteenMinute),
    6: TimeType(label: "30分钟", value: TimeConstants.thirtyMinute),
    7: TimeType(label: "1小时", value: TimeConstants.oneHour),
    8: TimeType(label: "4小时", value: TimeConstants.fourHour),
    9: TimeType(label: "6小时", value: TimeConstants.sixHour),
    10: TimeType(label: "1天", value: TimeConstants.oneDay),
    11: TimeType(label: "1周", value: TimeConstants.oneWeek),
    12: TimeType(label: "1月", value: TimeConstants.oneMonth)
]

private struct IndicatorType {
    let label: String
    let value: String
}

private enum IndicatorTypes {
    static let main: [Int: IndicatorType] = [
        1: IndicatorType(label: "MA", value: "ma"),
        2: IndicatorType(label: "BOLL", value: "boll"),
        0: IndicatorType(label: "NONE", value: "none")
    ]
    static let sub: [Int: IndicatorType] = [
        3: IndicatorType(label: "MACD", value: "macd"),
        4: IndicatorType(label: "KDJ", value: "kdj"),
        5: IndicatorType(label: "RSI", value: "rsi"),
        6: IndicatorType(label: "WR", value: "wr"),
        0: IndicatorType(label: "NONE", value: "none")
    ]
}

private enum DrawTypeConstants {
    static let none = 0
    static let show = -1
    static let line = 1
    static let horizontalLine = 2
    static let verticalLine = 3
    static let halfLine = 4
    static let parallelLine = 5
    static let rectangle = 101
    static let parallelogram = 102
}

private enum DrawStateConstants {
    static let none = -3
    static let showPencil = -2
    static let showContext = -1
}

private struct DrawToolType {
    let label: String
    let value: Int
}

private enum DrawToolTypes {
    static let list: [Int: DrawToolType] = [
        DrawTypeConstants.none: DrawToolType(label: "关闭绘图", value: DrawTypeConstants.none),
        DrawTypeConstants.line: DrawToolType(label: "线段", value: DrawTypeConstants.line),
        DrawTypeConstants.horizontalLine: DrawToolType(label: "水平线", value: DrawTypeConstants.horizontalLine),
        DrawTypeConstants.verticalLine: DrawToolType(label: "垂直线", value: DrawTypeConstants.verticalLine),
        DrawTypeConstants.halfLine: DrawToolType(label: "射线", value: DrawTypeConstants.halfLine),
        DrawTypeConstants.parallelLine: DrawToolType(label: "平行通道", value: DrawTypeConstants.parallelLine),
        DrawTypeConstants.rectangle: DrawToolType(label: "矩形", value: DrawTypeConstants.rectangle),
        DrawTypeConstants.parallelogram: DrawToolType(label: "平行四边形", value: DrawTypeConstants.parallelogram)
    ]
    static let order: [Int] = [
        DrawTypeConstants.none,
        DrawTypeConstants.line,
        DrawTypeConstants.horizontalLine,
        DrawTypeConstants.verticalLine,
        DrawTypeConstants.halfLine,
        DrawTypeConstants.parallelLine,
        DrawTypeConstants.rectangle,
        DrawTypeConstants.parallelogram
    ]
}

private enum DrawToolHelper {
    static func name(type: Int) -> String? {
        switch type {
        case DrawTypeConstants.line:
            return "线段"
        case DrawTypeConstants.horizontalLine:
            return "水平线"
        case DrawTypeConstants.verticalLine:
            return "垂直线"
        case DrawTypeConstants.halfLine:
            return "射线"
        case DrawTypeConstants.parallelLine:
            return "平行通道"
        case DrawTypeConstants.rectangle:
            return "矩形"
        case DrawTypeConstants.parallelogram:
            return "平行四边形"
        default:
            return nil
        }
    }
}

private struct Theme {
    let backgroundColor: Int
    let titleColor: Int
    let detailColor: Int
    let textColor7724: Int
    let headerColor: Int
    let tabBarBackgroundColor: Int
    let backgroundColor9103: Int
    let backgroundColor9703: Int
    let backgroundColor9113: Int
    let backgroundColor9709: Int
    let backgroundColor9603: Int
    let backgroundColor9411: Int
    let backgroundColor9607: Int
    let backgroundColor9609: Int
    let backgroundColor9509: Int
    let backgroundColorBlue: Int
    let buttonColor: Int
    let borderColor: Int
    let backgroundOpacity: Int
    let increaseColor: Int
    let decreaseColor: Int
    let minuteLineColor: Int
    let gridColor: Int
    let separatorColor: Int
    let textColor: Int
}

private enum ThemeManager {
    static func currentTheme(isDark: Bool) -> Theme {
        if isDark {
            return Theme(
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
                textColor: color(0.81, 0.83, 0.91)
            )
        }

        return Theme(
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
            textColor: color(0.08, 0.09, 0.12)
        )
    }
}

private func color(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> Int {
    let red = Int(round(r * 255))
    let green = Int(round(g * 255))
    let blue = Int(round(b * 255))
    let alpha = Int(round(a * 255))
    return (alpha << 24) | (red << 16) | (green << 8) | blue
}

private func fixRound(value: Double?, precision: Int, showSign: Bool, showGrouping: Bool) -> String {
    guard let value, !value.isNaN else { return "--" }
    var result = String(format: "%0.*f", precision, value)
    if showGrouping {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = precision
        formatter.minimumFractionDigits = precision
        if let formatted = formatter.string(from: NSNumber(value: value)) {
            result = formatted
        }
    }
    if showSign && value > 0 {
        result = "+" + result
    }
    return result
}

private func formatTime(timestamp: Double, format: String) -> String {
    let date = Date(timeIntervalSince1970: timestamp / 1000)
    let calendar = Calendar.current
    let month = String(format: "%02d", calendar.component(.month, from: date))
    let day = String(format: "%02d", calendar.component(.day, from: date))
    let hour = String(format: "%02d", calendar.component(.hour, from: date))
    let minute = String(format: "%02d", calendar.component(.minute, from: date))
    let second = String(format: "%02d", calendar.component(.second, from: date))

    return format
        .replacingOccurrences(of: "MM", with: month)
        .replacingOccurrences(of: "DD", with: day)
        .replacingOccurrences(of: "HH", with: hour)
        .replacingOccurrences(of: "mm", with: minute)
        .replacingOccurrences(of: "ss", with: second)
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

private extension UIColor {
    convenience init(colorInt: Int) {
        let alpha = CGFloat((colorInt >> 24) & 0xff) / 255.0
        let red = CGFloat((colorInt >> 16) & 0xff) / 255.0
        let green = CGFloat((colorInt >> 8) & 0xff) / 255.0
        let blue = CGFloat(colorInt & 0xff) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
