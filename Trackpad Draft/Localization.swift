import Foundation
import SwiftUI

// MARK: - Supported Languages
enum AppLanguage: String, CaseIterable, Identifiable {
    case zh = "zh"
    case en = "en"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .zh: return "中文"
        case .en: return "English"
        }
    }
    
    /// Detect system language, default to English if not Chinese
    static var system: AppLanguage {
        let lang = Locale.preferredLanguages.first ?? "en"
        if lang.hasPrefix("zh") {
            return .zh
        }
        return .en
    }
}

// MARK: - Localized Strings
struct L10n {
    static var current: AppLanguage {
        let raw = UserDefaults.standard.string(forKey: SettingsKeys.appLanguage) ?? ""
        return AppLanguage(rawValue: raw) ?? AppLanguage.system
    }
    
    // MARK: Settings – Tabs
    static var tabGeneral: String { current == .zh ? "通用" : "General" }
    static var tabShortcuts: String { current == .zh ? "快捷键" : "Shortcuts" }
    
    // MARK: Settings – Window Size
    static var windowSize: String { current == .zh ? "窗口大小" : "Window Size" }
    static var lockRatio: String { current == .zh ? "按比例调节 (16:10)" : "Lock Ratio (16:10)" }
    static var width: String { current == .zh ? "宽度" : "Width" }
    static var height: String { current == .zh ? "高度" : "Height" }
    static var opacity: String { current == .zh ? "透明度" : "Opacity" }
    static var resetDefaults: String { current == .zh ? "恢复默认" : "Reset" }
    static var applySettings: String { current == .zh ? "应用窗口设置" : "Apply" }
    
    // MARK: Settings – Shortcuts
    static var globalShortcuts: String { current == .zh ? "全局快捷键" : "Global Shortcuts" }
    static var toggleDraft: String { current == .zh ? "呼出 / 隐藏草稿纸" : "Show / Hide Draft" }
    static var canvasShortcuts: String { current == .zh ? "画板内快捷键（不可更改）" : "Canvas Shortcuts (Read-only)" }
    static var switchToPen: String { current == .zh ? "切换到画笔" : "Switch to Pen" }
    static var switchToEraser: String { current == .zh ? "切换到橡皮擦" : "Switch to Eraser" }
    static var clearCanvas: String { current == .zh ? "清空画布" : "Clear Canvas" }
    static var hideDraft: String { current == .zh ? "隐藏草稿纸" : "Hide Draft" }
    static var toggleMouse: String { current == .zh ? "显示 / 隐藏鼠标" : "Show / Hide Cursor" }
    static var panCanvas: String { current == .zh ? "平移画布" : "Pan Canvas" }
    static var moveWindow: String { current == .zh ? "移动窗口" : "Move Window" }
    static var undoStroke: String { current == .zh ? "撤回上一笔" : "Undo Last Stroke" }
    static var tapTrackpad: String { current == .zh ? "单击触摸板" : "Tap Trackpad" }
    static var twoFingerScroll: String { current == .zh ? "双指滑动" : "Two-finger Scroll" }
    static var holdDrag: String { current == .zh ? "按住拖动" : "Hold & Drag" }
    
    // MARK: Settings – Language
    static var language: String { current == .zh ? "语言" : "Language" }
    static var languageLabel: String { current == .zh ? "界面语言" : "UI Language" }
    
    // MARK: Status Bar Menu
    // menuToggleDraft removed — use toggleDraft (same value)
    static var menuPreferences: String { current == .zh ? "设置..." : "Preferences..." }
    static var menuQuit: String { current == .zh ? "退出" : "Quit" }
    
    // MARK: Window Title
    static var settingsTitle: String { current == .zh ? "TrackpadDraft 设置" : "TrackpadDraft Settings" }
}
