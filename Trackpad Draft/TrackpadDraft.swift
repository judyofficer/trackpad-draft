import SwiftUI
import AppKit
import Carbon
import KeyboardShortcuts

@main
struct TrackpadDraftApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // We manage all windows manually — this empty Settings keeps the app alive
        Settings {
            EmptyView()
        }
    }
}

struct SettingsView: View {
    @AppStorage(SettingsKeys.windowWidth) private var windowWidth: Double = Double(SettingsKeys.defaultWidth)
    @AppStorage(SettingsKeys.windowHeight) private var windowHeight: Double = Double(SettingsKeys.defaultHeight)
    @AppStorage(SettingsKeys.windowOpacity) private var windowOpacity: Double = SettingsKeys.defaultOpacity
    @AppStorage(SettingsKeys.appLanguage) private var appLanguage: String = AppLanguage.system.rawValue
    
    @State private var lockAspectRatio: Bool = true
    @State private var refreshID = UUID()  // force view refresh on language change
    
    // Mac trackpad ratio: 16:10 = 1.6
    private static let trackpadRatio: Double = 1.6
    
    var body: some View {
        TabView {
            // MARK: - General Tab
            VStack(alignment: .leading, spacing: 20) {
                // Language Section
                GroupBox(label: Label(L10n.language, systemImage: "globe")) {
                    HStack {
                        Text(L10n.languageLabel)
                            .frame(width: 80, alignment: .leading)
                        Picker("", selection: $appLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                    }
                    .padding(8)
                }
                .onChange(of: appLanguage) { _, _ in
                    refreshID = UUID()
                }
                
                // Window Size Section
                GroupBox(label: Label(L10n.windowSize, systemImage: "rectangle.dashed")) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Lock aspect ratio toggle
                        Toggle(isOn: $lockAspectRatio) {
                            Label(L10n.lockRatio, systemImage: "lock.rectangle")
                                .font(.system(size: 13))
                        }
                        .toggleStyle(.checkbox)
                        
                        HStack {
                            Text(L10n.width)
                                .frame(width: 50, alignment: .leading)
                            Slider(value: Binding(
                                get: { windowWidth },
                                set: { newVal in
                                    windowWidth = newVal
                                    if lockAspectRatio {
                                        windowHeight = (newVal / Self.trackpadRatio).rounded()
                                    }
                                }
                            ), in: 400...1600, step: 50)
                            Text("\(Int(windowWidth)) px")
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 65, alignment: .trailing)
                        }
                        HStack {
                            Text(L10n.height)
                                .frame(width: 50, alignment: .leading)
                            Slider(value: Binding(
                                get: { windowHeight },
                                set: { newVal in
                                    windowHeight = newVal
                                    if lockAspectRatio {
                                        windowWidth = (newVal * Self.trackpadRatio).rounded()
                                    }
                                }
                            ), in: 300...1000, step: 50)
                            Text("\(Int(windowHeight)) px")
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 65, alignment: .trailing)
                        }
                        HStack {
                            Text(L10n.opacity)
                                .frame(width: 50, alignment: .leading)
                            Slider(value: $windowOpacity, in: 0.3...1.0, step: 0.05)
                            Text("\(Int(windowOpacity * 100))%")
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 65, alignment: .trailing)
                        }
                    }
                    .padding(8)
                }
                
                HStack {
                    Button(L10n.resetDefaults) {
                        windowWidth = Double(SettingsKeys.defaultWidth)
                        windowHeight = Double(SettingsKeys.defaultHeight)
                        windowOpacity = SettingsKeys.defaultOpacity
                        DraftWindowManager.shared.applySettings()
                    }
                    .controlSize(.regular)
                    
                    Spacer()
                    
                    Button(L10n.applySettings) {
                        DraftWindowManager.shared.applySettings()
                    }
                    .controlSize(.regular)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
            .frame(width: 420)
            .tabItem {
                Label(L10n.tabGeneral, systemImage: "gear")
            }
            
            // MARK: - Shortcuts Tab
            VStack(alignment: .leading, spacing: 20) {
                GroupBox(label: Label(L10n.globalShortcuts, systemImage: "keyboard")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(L10n.toggleDraft)
                                .frame(width: 160, alignment: .leading)
                            KeyboardShortcuts.Recorder(for: .toggleDraftWindow)
                        }
                    }
                    .padding(8)
                }
                
                GroupBox(label: Label(L10n.canvasShortcuts, systemImage: "hand.draw")) {
                    VStack(alignment: .leading, spacing: 8) {
                        shortcutRow("1", L10n.switchToPen)
                        shortcutRow("2", L10n.switchToEraser)
                        shortcutRow("⌫ Delete", L10n.clearCanvas)
                        shortcutRow("⌘Z", L10n.undoStroke)
                        shortcutRow("Esc", L10n.hideDraft)
                        shortcutRow(L10n.tapTrackpad, L10n.toggleMouse)
                        shortcutRow(L10n.twoFingerScroll, L10n.panCanvas)
                        shortcutRow(L10n.holdDrag, L10n.moveWindow)
                    }
                    .padding(8)
                }
            }
            .padding(20)
            .frame(width: 420)
            .tabItem {
                Label(L10n.tabShortcuts, systemImage: "command.square")
            }
        }
        .id(refreshID)
    }
    
    private func shortcutRow(_ key: String, _ desc: String) -> some View {
        HStack {
            Text(key)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.blue.opacity(0.1)))
                .frame(width: 120, alignment: .leading)
            Text(desc)
                .foregroundColor(.secondary)
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the app from the Dock
        NSApp.setActivationPolicy(.accessory)
        
        // Setup Status Bar Menu
        setupStatusBar()
        
        // Setup Global Hotkey via KeyboardShortcuts
        KeyboardShortcuts.onKeyDown(for: .toggleDraftWindow) { [weak self] in
            self?.toggleDraftWindow()
        }
    }
    
    func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "pencil.and.outline", accessibilityDescription: "Trackpad Draft")
            button.action = #selector(statusBarClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }
    }
    
    @objc func statusBarClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Right click: show context menu
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: L10n.toggleDraft, action: #selector(toggleDraftWindow), keyEquivalent: "d"))
            menu.addItem(NSMenuItem(title: L10n.menuPreferences, action: #selector(openPreferences), keyEquivalent: ","))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: L10n.menuQuit, action: #selector(quitApp), keyEquivalent: "q"))
            
            statusBarItem?.menu = menu
            statusBarItem?.button?.performClick(nil) // trigger the menu
            // Remove menu after it closes so left click works next time
            DispatchQueue.main.async { [weak self] in
                self?.statusBarItem?.menu = nil
            }
        } else {
            // Left click: toggle draft window directly
            toggleDraftWindow()
        }
    }
    
    @objc func openPreferences() {
        // If window already exists, just bring it forward
        if let win = settingsWindow {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create a native NSWindow hosting our SettingsView
        let settingsView = SettingsView()
        let hostingView = NSHostingView(rootView: settingsView)
        
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = L10n.settingsTitle
        win.level = .modalPanel   // float above the draft window (.floating level)
        win.contentView = hostingView
        win.center()
        win.isReleasedWhenClosed = false
        win.makeKeyAndOrderFront(nil)
        
        NSApp.activate(ignoringOtherApps: true)
        
        self.settingsWindow = win
    }
    
    @objc func toggleDraftWindow() {
        DraftWindowManager.shared.toggleWindow()
    }
    
    @objc func quitApp() {
        DraftWindowManager.shared.unlockCursor()
        NSApplication.shared.terminate(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Failsafe to restore cursor
        DraftWindowManager.shared.unlockCursor()
    }
}
