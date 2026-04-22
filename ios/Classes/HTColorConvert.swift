import UIKit

#if canImport(React)
import React
#endif

enum HTColorConvert {
    static func uiColorOptional(_ value: Any?) -> UIColor? {
#if canImport(React)
        if let color = RCTConvert.uiColor(value) {
            return color
        }
#endif
        if let color = value as? UIColor {
            return color
        }
        if let number = value as? NSNumber {
            return colorFromInt(number.intValue)
        }
        if let intValue = value as? Int {
            return colorFromInt(intValue)
        }
        if let stringValue = value as? String {
            return colorFromString(stringValue)
        }
        return nil
    }

    static func uiColor(_ value: Any?, fallback: UIColor) -> UIColor {
        return uiColorOptional(value) ?? fallback
    }

    private static func colorFromInt(_ value: Int) -> UIColor {
        let rgba = UInt32(value)
        let alpha = CGFloat((rgba >> 24) & 0xFF) / 255.0
        let red = CGFloat((rgba >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgba >> 8) & 0xFF) / 255.0
        let blue = CGFloat(rgba & 0xFF) / 255.0
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    private static func colorFromString(_ value: String) -> UIColor? {
        let raw = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if raw == "white" {
            return UIColor.white
        }
        if raw == "black" {
            return UIColor.black
        }
        if raw == "transparent" {
            return UIColor.clear
        }
        if raw.hasPrefix("#") {
            return colorFromHex(raw)
        }
        if raw.hasPrefix("rgb(") || raw.hasPrefix("rgba(") {
            return colorFromRgb(raw)
        }
        return nil
    }

    private static func colorFromHex(_ hexString: String) -> UIColor? {
        let hex = String(hexString.dropFirst())
        if hex.count == 6 {
            guard let value = UInt32(hex, radix: 16) else { return nil }
            let red = CGFloat((value >> 16) & 0xFF) / 255.0
            let green = CGFloat((value >> 8) & 0xFF) / 255.0
            let blue = CGFloat(value & 0xFF) / 255.0
            return UIColor(red: red, green: green, blue: blue, alpha: 1)
        }
        if hex.count == 8 {
            guard let value = UInt32(hex, radix: 16) else { return nil }
            let alpha = CGFloat((value >> 24) & 0xFF) / 255.0
            let red = CGFloat((value >> 16) & 0xFF) / 255.0
            let green = CGFloat((value >> 8) & 0xFF) / 255.0
            let blue = CGFloat(value & 0xFF) / 255.0
            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        }
        return nil
    }

    private static func colorFromRgb(_ raw: String) -> UIColor? {
        let values = raw
            .replacingOccurrences(of: "rgba(", with: "")
            .replacingOccurrences(of: "rgb(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard values.count == 3 || values.count == 4 else { return nil }
        guard let red = Double(values[0]),
              let green = Double(values[1]),
              let blue = Double(values[2]) else { return nil }
        let alpha: Double
        if values.count == 4, let alphaValue = Double(values[3]) {
            alpha = alphaValue
        } else {
            alpha = 1
        }
        return UIColor(
            red: CGFloat(red / 255.0),
            green: CGFloat(green / 255.0),
            blue: CGFloat(blue / 255.0),
            alpha: CGFloat(alpha)
        )
    }
}
