import Foundation
import Combine
import CoreGraphics
import SwiftUI

enum DrawingMode {
    case pen
    case eraser
}

struct Stroke: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    var color: Color = .primary
    var lineWidth: CGFloat = 2.0
}

@MainActor
class CanvasEngine: ObservableObject {
    @Published var strokes: [Stroke] = []
    @Published var currentStroke: Stroke?
    @Published var offset: CGSize = .zero
    @Published var virtualCursorPosition: CGPoint?
    
    @Published var currentMode: DrawingMode = .pen
    @Published var isMouseVisible: Bool = true
    
    @Published var penLineWidth: CGFloat = 2.0
    @Published var eraserRadius: CGFloat = 10.0
    
    // Undo history: each element is a snapshot of `strokes` before a change
    private var undoStack: [[Stroke]] = []
    
    // Convert absolute trackpad coords to window coords
    // trackpad size roughly 14x8 cm, let's assume normalized 0...1 relative input
    
    // MARK: - Drawing & Erasing
    
    func beginStroke(at point: CGPoint) {
        if currentMode == .eraser {
            // Save snapshot before erasing begins
            undoStack.append(strokes)
            eraseStrokes(at: point)
        } else {
            currentStroke = Stroke(points: [point])
            currentStroke?.lineWidth = penLineWidth
        }
    }
    
    func addPointToStroke(_ point: CGPoint) {
        if currentMode == .eraser {
            eraseStrokes(at: point)
        } else {
            currentStroke?.points.append(point)
        }
    }
    
    private func eraseStrokes(at point: CGPoint) {
        let threshold: CGFloat = eraserRadius
        
        strokes.removeAll { stroke in
            stroke.points.contains { p in
                hypot(p.x - point.x, p.y - point.y) < threshold
            }
        }
    }
    
    func endStroke() {
        if let stroke = currentStroke {
            // Save snapshot before committing a new stroke
            undoStack.append(strokes)
            strokes.append(stroke)
        }
        currentStroke = nil
    }
    
    func cancelStroke() {
        currentStroke = nil
    }
    
    func clearAll() {
        guard !strokes.isEmpty else { return }
        undoStack.append(strokes)
        strokes.removeAll()
    }
    
    // MARK: - Undo
    
    func undo() {
        guard let previous = undoStack.popLast() else { return }
        currentStroke = nil
        strokes = previous
    }
    
    var canUndo: Bool { !undoStack.isEmpty }
    
    func toggleMouseVisibility(in window: NSWindow?) {
        isMouseVisible.toggle()
        if isMouseVisible {
            DraftWindowManager.shared.unlockCursor()
        } else {
            // Warp cursor back to window center before locking
            if let win = window, let screenHeight = NSScreen.main?.frame.height {
                CGWarpMouseCursorPosition(CGPoint(x: win.frame.midX, y: screenHeight - win.frame.midY))
            }
            DraftWindowManager.shared.lockCursor()
        }
    }
}
