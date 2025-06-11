import SwiftUI

class ThemeManager: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode: Bool = true
    @AppStorage("fontSizeAdjustment") var fontSizeAdjustment: Int = 0
    @AppStorage("darkModeTextColor") var darkModeTextColor: String = "green"
    @AppStorage("lightModeTextColor") var lightModeTextColor: String = "black"
    @AppStorage("selectedFont") var selectedFont: String = "SourceCodePro-Bold"
    @AppStorage("lineWeight") var lineWeight: Int = 0
    @AppStorage("fontOpacity") var fontOpacity: Double = 1.0
    @AppStorage("lineStyle") var lineStyle: Int = 0

    // Default settings for reset
    private let defaultSettings: [String: Any] = [
        "isDarkMode": true,
        "fontSizeAdjustment": 0,
        "darkModeTextColor": "green",
        "lightModeTextColor": "black",
        "selectedFont": "SourceCodePro-Bold",
        "lineWeight": 0,
        "fontOpacity": 1.0,
        "lineStyle": 0
    ]

    // Available fonts for selection in Settings
    var availableFonts: [String] {
        [
            "SourceCodePro-Bold",
            "Rye-Regular"
        ]
    }

    // Computed properties for theme
    var backgroundColor: Color {
        isDarkMode ? .black : Color(red: 245/255, green: 235/255, blue: 215/255) // Warmer: Creamy Ivory
    }

    var themeColor: Color {
        if isDarkMode {
            return darkModeTextColor == "green" ? .green : .white
        } else {
            return lightModeTextColor == "black" ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 178/255, green: 34/255, blue: 34/255)
        }
    }

    var lineWidth: CGFloat {
        return CGFloat(lineWeight + 1)
    }

    var lineStroke: some ShapeStyle {
        switch lineStyle {
        case 1: // Radiant Beam
            return AnyShapeStyle(LinearGradient(
                gradient: Gradient(colors: [themeColor.opacity(0.6), themeColor]),
                startPoint: .leading,
                endPoint: .trailing
            ))
        default: // Classic
            return AnyShapeStyle(themeColor.opacity(fontOpacity))
        }
    }

    func adjustedFontSize(base: CGFloat) -> CGFloat {
        switch fontSizeAdjustment {
        case -2:
            return base * 0.8
        case -1:
            return base * 0.9
        case 1:
            return base * 1.1
        case 2:
            return base * 1.2
        default:
            return base
        }
    }

    func resetToDefaults() {
        isDarkMode = defaultSettings["isDarkMode"] as! Bool
        fontSizeAdjustment = defaultSettings["fontSizeAdjustment"] as! Int
        darkModeTextColor = defaultSettings["darkModeTextColor"] as! String
        lightModeTextColor = defaultSettings["lightModeTextColor"] as! String
        selectedFont = defaultSettings["selectedFont"] as! String
        lineWeight = defaultSettings["lineWeight"] as! Int
        fontOpacity = defaultSettings["fontOpacity"] as! Double
        lineStyle = defaultSettings["lineStyle"] as! Int
    }
}
