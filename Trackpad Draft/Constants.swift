import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleDraftWindow = Self("toggleDraftWindow", default: .init(.d, modifiers: [.option, .shift]))
}
