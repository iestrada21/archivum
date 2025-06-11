import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    // Font Size Actions
    private func decreaseFontSize() {
        if themeManager.fontSizeAdjustment > -2 {
            themeManager.fontSizeAdjustment -= 1
        }
    }
    
    private func increaseFontSize() {
        if themeManager.fontSizeAdjustment < 2 {
            themeManager.fontSizeAdjustment += 1
        }
    }
    
    // Line Boldness Actions
    private func decreaseLineBoldness() {
        if themeManager.lineWeight > 0 {
            themeManager.lineWeight -= 1
        }
    }
    
    private func increaseLineBoldness() {
        if themeManager.lineWeight < 3 {
            themeManager.lineWeight += 1
        }
    }
    
    // Font Opacity Actions
    private func decreaseFontOpacity() {
        if themeManager.fontOpacity > 0.7 {
            themeManager.fontOpacity = max(0.7, themeManager.fontOpacity - 0.3)
        }
    }
    
    private func increaseFontOpacity() {
        if themeManager.fontOpacity < 1.3 {
            themeManager.fontOpacity = min(1.3, themeManager.fontOpacity + 0.3)
        }
    }

    // Font Style Action
    private func cycleFontStyle() {
        let fontOptions = themeManager.availableFonts
        if let currentIndex = fontOptions.firstIndex(of: themeManager.selectedFont) {
            let nextIndex = (currentIndex + 1) % fontOptions.count
            themeManager.selectedFont = fontOptions[nextIndex]
        } else {
            themeManager.selectedFont = fontOptions[0]
        }
    }
    
    // Line Style Action
    private func cycleLineStyle() {
        themeManager.lineStyle = (themeManager.lineStyle + 1) % 2 // Toggle between 0 (Classic) and 1 (Radiant Beam)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // Font Size Adjustment
                settingsRow(
                    label: "Letter Scale",
                    value: "\(themeManager.fontSizeAdjustment)",
                    minusAction: decreaseFontSize,
                    plusAction: increaseFontSize,
                    minusDisabled: themeManager.fontSizeAdjustment <= -2,
                    plusDisabled: themeManager.fontSizeAdjustment >= 2
                )
                
                // Font Color Toggle
                HStack(spacing: 5) {
                    Text("Letter Hue: \(themeManager.isDarkMode ? themeManager.darkModeTextColor : themeManager.lightModeTextColor)")
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button(themeManager.isDarkMode ? (themeManager.darkModeTextColor == "green" ? "White" : "Green") : (themeManager.lightModeTextColor == "black" ? "Firebrick" : "Black")) {
                        if themeManager.isDarkMode {
                            themeManager.darkModeTextColor = themeManager.darkModeTextColor == "green" ? "white" : "green"
                        } else {
                            themeManager.lightModeTextColor = themeManager.lightModeTextColor == "black" ? "firebrick" : "black"
                        }
                    }
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 10)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .frame(width: 100, height: 30)
                    .overlay(
                        Rectangle()
                            .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                            .if(themeManager.lineStyle == 1) { $0.shadow(color: themeManager.themeColor.opacity(0.5), radius: 2, x: 0, y: 0) }
                    )
                }
                .background(themeManager.backgroundColor)
                .overlay(
                    Rectangle()
                        .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                        .if(themeManager.lineStyle == 1) { $0.shadow(color: themeManager.themeColor.opacity(0.5), radius: 2, x: 0, y: 0) }
                )
                
                // Font Style Toggle
                HStack(spacing: 5) {
                    Text("Letter Form: \(themeManager.selectedFont)")
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button("Cycle Form") {
                        cycleFontStyle()
                    }
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 10)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .frame(width: 100, height: 30)
                    .overlay(
                        Rectangle()
                            .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                            .if(themeManager.lineStyle == 1) { $0.shadow(color: themeManager.themeColor.opacity(0.5), radius: 2, x: 0, y: 0) }
                    )
                }
                .background(themeManager.backgroundColor)
                .overlay(
                    Rectangle()
                        .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                        .if(themeManager.lineStyle == 1) { $0.shadow(color: themeManager.themeColor.opacity(0.5), radius: 2, x: 0, y: 0) }
                )
                
                // Line Boldness
                settingsRow(
                    label: "Line Strength",
                    value: "\(themeManager.lineWeight)",
                    minusAction: decreaseLineBoldness,
                    plusAction: increaseLineBoldness,
                    minusDisabled: themeManager.lineWeight <= 0,
                    plusDisabled: themeManager.lineWeight >= 3
                )
                
                // Font Opacity
                settingsRow(
                    label: "Letter Clarity",
                    value: String(format: "%.1f", themeManager.fontOpacity),
                    minusAction: decreaseFontOpacity,
                    plusAction: increaseFontOpacity,
                    minusDisabled: themeManager.fontOpacity <= 0.7,
                    plusDisabled: themeManager.fontOpacity >= 1.3
                )
                
                // Line Style Toggle
                HStack(spacing: 5) {
                    Text("Line Style: \(themeManager.lineStyle == 0 ? "Classic" : "Radiant Beam")")
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button("Cycle Style") {
                        cycleLineStyle()
                    }
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 10)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .frame(width: 100, height: 30)
                    .overlay(
                        Rectangle()
                            .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                            .if(themeManager.lineStyle == 1) { $0.shadow(color: themeManager.themeColor.opacity(0.5), radius: 2, x: 0, y: 0) }
                    )
                }
                .background(themeManager.backgroundColor)
                .overlay(
                    Rectangle()
                        .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                        .if(themeManager.lineStyle == 1) { $0.shadow(color: themeManager.themeColor.opacity(0.5), radius: 2, x: 0, y: 0) }
                )
                
                // Restore Defaults
                Button("Restore Ancient Defaults") {
                    themeManager.resetToDefaults()
                }
                .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(themeManager.backgroundColor)
                .overlay(
                    Rectangle()
                        .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                        .if(themeManager.lineStyle == 1) { $0.shadow(color: themeManager.themeColor.opacity(0.5), radius: 2, x: 0, y: 0) }
                )
            }
            .padding(10)
        }
        .background(themeManager.backgroundColor)
        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
    }
    
    private func settingsRow(
        label: String,
        value: String,
        minusAction: @escaping () -> Void,
        plusAction: @escaping () -> Void,
        minusDisabled: Bool,
        plusDisabled: Bool
    ) -> some View {
        HStack(spacing: 5) {
            Text("\(label): \(value)")
                .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button("-") {
                minusAction()
            }
            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 10)))
            .foregroundColor(minusDisabled ? themeManager.themeColor.opacity(themeManager.fontOpacity * 0.5) : themeManager.themeColor.opacity(themeManager.fontOpacity))
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .frame(width: 50, height: 30)
            .overlay(
                Rectangle()
                    .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                    .if(themeManager.lineStyle == 1) { $0.shadow(color: themeManager.themeColor.opacity(0.5), radius: 2, x: 0, y: 0) }
            )
            .disabled(minusDisabled)
            
            Button("+") {
                plusAction()
            }
            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 10)))
            .foregroundColor(plusDisabled ? themeManager.themeColor.opacity(themeManager.fontOpacity * 0.5) : themeManager.themeColor.opacity(themeManager.fontOpacity))
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .frame(width: 50, height: 30)
            .overlay(
                Rectangle()
                    .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                    .if(themeManager.lineStyle == 1) { $0.shadow(color: themeManager.themeColor.opacity(0.5), radius: 2, x: 0, y: 0) }
            )
            .disabled(plusDisabled)
        }
        .background(themeManager.backgroundColor)
        .overlay(
            Rectangle()
                .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                .if(themeManager.lineStyle == 1) { $0.shadow(color: themeManager.themeColor.opacity(0.5), radius: 2, x: 0, y: 0) }
        )
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ThemeManager())
            .preferredColorScheme(.dark)
    }
}
