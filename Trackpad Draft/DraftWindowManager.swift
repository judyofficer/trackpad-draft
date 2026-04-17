import Cocoa
import SwiftUI

extension Notification.Name {
    static let draftWindowDidShow = Notification.Name("draftWindowDidShow")
    static let draftWindowDidHide = Notification.Name("draftWindowDidHide")
}

// MARK: - Settings Keys
enum SettingsKeys {
    static let windowWidth = "windowWidth"
    static let windowHeight = "windowHeight"
    static let windowOpacity = "windowOpacity"
    static let appLanguage = "appLanguage"
    
    static var defaultWidth: CGFloat { 800 }
    static var defaultHeight: CGFloat { 500 }
    static var defaultOpacity: Double { 0.85 }
    
    static var savedWidth: CGFloat {
        let v = UserDefaults.standard.double(forKey: windowWidth)
        return v > 0 ? CGFloat(v) : defaultWidth
    }
    static var savedHeight: CGFloat {
        let v = UserDefaults.standard.double(forKey: windowHeight)
        return v > 0 ? CGFloat(v) : defaultHeight
    }
    static var savedOpacity: Double {
        let v = UserDefaults.standard.double(forKey: windowOpacity)
        return v > 0 ? v : defaultOpacity
    }
}

@MainActor
class DraftWindowManager {
    static let shared = DraftWindowManager()
    private var window: NSWindow?
    private var cursorHidden = false
    private var hasOpenedBefore = false
    
    func toggleWindow() {
        if let window = window, window.isVisible {
            hideWindow()
        } else {
            showWindow()
        }
    }
    
    func showWindow() {
        if window == nil {
            createWindow()
        }
        
        guard let window = window else { return }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        if !hasOpenedBefore {
            // First time ever: open in mouse mode so user can place window
            hasOpenedBefore = true
            unlockCursor()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .draftWindowDidShow, object: ["isFirstTime": true])
            }
        } else {
            // Subsequent times: warp to center and enter drawing mode
            if let screen = window.screen {
                let cgY = screen.frame.height - window.frame.midY
                CGWarpMouseCursorPosition(CGPoint(x: window.frame.midX, y: cgY))
            }
            lockCursor()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .draftWindowDidShow, object: ["isFirstTime": false])
            }
        }
    }
    
    func hideWindow() {
        unlockCursor()
        window?.orderOut(nil)
        NotificationCenter.default.post(name: .draftWindowDidHide, object: nil)
    }
    
    func lockCursor() {
        CGAssociateMouseAndMouseCursorPosition(boolean_t(0))
        if !cursorHidden {
            NSCursor.hide()
            cursorHidden = true
        }
    }
    
    func unlockCursor() {
        CGAssociateMouseAndMouseCursorPosition(boolean_t(1))
        if cursorHidden {
            NSCursor.unhide()
            cursorHidden = false
        }
    }
    
    /// Recreate window with updated settings
    func applySettings() {
        let wasVisible = window?.isVisible ?? false
        if wasVisible { hideWindow() }
        window = nil
        if wasVisible { showWindow() }
    }
    
    private func createWindow() {
        let w = SettingsKeys.savedWidth
        let h = SettingsKeys.savedHeight
        let opacity = SettingsKeys.savedOpacity
        
        let rect = NSRect(x: 0, y: 0, width: w, height: h)
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        
        let newWindow = NSWindow(contentRect: rect,
                               styleMask: styleMask,
                               backing: .buffered,
                               defer: false)
        
        newWindow.title = "Draft"
        newWindow.titleVisibility = .hidden
        newWindow.titlebarAppearsTransparent = true
        newWindow.isOpaque = false
        newWindow.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(CGFloat(opacity))
        newWindow.level = .floating // Float on top of other windows
        newWindow.center()
        newWindow.isReleasedWhenClosed = false // Prevent deallocation on close
        newWindow.delegate = windowDelegate
        
        newWindow.hasShadow = true
        
        let contentView = DraftView()
        newWindow.contentView = NSHostingView(rootView: contentView)
        
        self.window = newWindow
    }
    
    // Use a separate delegate object to avoid @MainActor issues
    private let windowDelegate = DraftWindowDelegate()
}

// MARK: - Window Delegate
class DraftWindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Restore cursor when user clicks the red X button
        DraftWindowManager.shared.unlockCursor()
        NotificationCenter.default.post(name: .draftWindowDidHide, object: nil)
    }
}
