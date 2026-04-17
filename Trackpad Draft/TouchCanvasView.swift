import SwiftUI
import AppKit

struct TouchCanvasView: NSViewRepresentable {
    @ObservedObject var engine: CanvasEngine
    
    func makeNSView(context: Context) -> TrackpadView {
        let view = TrackpadView()
        view.engine = engine
        return view
    }
    
    func updateNSView(_ nsView: TrackpadView, context: Context) {
        // Update if needed
    }
}

class TrackpadView: NSView {
    weak var engine: CanvasEngine?
    
    // To track touches, we must enable touch events
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.acceptsTouchEvents = true
        self.wantsRestingTouches = true // Capture touches even if they don't move immediately
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // We only process touches if exactly one finger is touching
    // If two fingers are touching, we could pass them to an NSPanGestureRecognizer instead
    private var activeTouchIdentity: NSObjectProtocol?
    
    override func touchesBegan(with event: NSEvent) {
        if engine?.isMouseVisible == true { return }
        let touches = event.touches(matching: .touching, in: self)
        
        if touches.count > 1 {
            // Cancel any mid-air mistaken drawing from primary finger arriving early
            if activeTouchIdentity != nil {
                engine?.cancelStroke()
                activeTouchIdentity = nil
                engine?.virtualCursorPosition = nil
            }
            return
        }
        
        // Only start drawing if exactly 1 touch is detected (to avoid rejecting pan gestures)
        if touches.count == 1, let touch = touches.first {
            activeTouchIdentity = touch.identity as? NSObjectProtocol
            let point = mapTouchLocation(touch: touch)
            engine?.virtualCursorPosition = point
            
            let offset = engine?.offset ?? .zero
            let canvasPoint = CGPoint(x: point.x - offset.width, y: point.y - offset.height)
            engine?.beginStroke(at: canvasPoint)
        }
    }
    
    override func touchesMoved(with event: NSEvent) {
        if engine?.isMouseVisible == true { return }
        let touches = event.touches(matching: .touching, in: self)
        
        if touches.count > 1 {
            if activeTouchIdentity != nil {
                engine?.cancelStroke()
                activeTouchIdentity = nil
                engine?.virtualCursorPosition = nil
            }
            return
        }
        
        guard let identity = activeTouchIdentity else { return }
        
        if let touch = touches.first(where: { $0.identity.isEqual(identity) }) {
            let point = mapTouchLocation(touch: touch)
            engine?.virtualCursorPosition = point
            
            let offset = engine?.offset ?? .zero
            let canvasPoint = CGPoint(x: point.x - offset.width, y: point.y - offset.height)
            engine?.addPointToStroke(canvasPoint)
        }
    }
    
    override func touchesEnded(with event: NSEvent) {
        guard let identity = activeTouchIdentity else { return }
        let touches = event.touches(matching: .any, in: self) // Need .any to detect ended touches
        if let touch = touches.first(where: { $0.identity.isEqual(identity) }), touch.phase == .ended || touch.phase == .cancelled {
            engine?.endStroke()
            engine?.virtualCursorPosition = nil
            activeTouchIdentity = nil
        }
    }
    
    override func touchesCancelled(with event: NSEvent) {
        if activeTouchIdentity != nil {
            engine?.endStroke()
            engine?.virtualCursorPosition = nil
            activeTouchIdentity = nil
        }
    }
    
    private func mapTouchLocation(touch: NSTouch) -> CGPoint {
        // NSTouch normalizedPosition is (0.0...1.0, 0.0...1.0)
        let normalized = touch.normalizedPosition
        
        // AppKit's coordinates for trackpad have (0,0) at the bottom-left.
        // SwiftUI Canvas starts (0,0) at the top-left.
        // Therefore, we must invert the Y-axis.
        let x = normalized.x * bounds.width
        let y = (1.0 - normalized.y) * bounds.height
        return CGPoint(x: x, y: y)
    }
    
    // To keep the view transparent/interactive properly
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    private var lastMouseDownEvent: NSEvent?
    
    // Explicitly handle dragging the window from anywhere
    override func mouseDown(with event: NSEvent) {
        lastMouseDownEvent = event
    }
    
    override func mouseDragged(with event: NSEvent) {
        if let downEvent = lastMouseDownEvent {
            self.window?.performDrag(with: downEvent)
            lastMouseDownEvent = nil
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        if lastMouseDownEvent != nil {
            // A click without dragging toggles the mouse
            engine?.toggleMouseVisibility(in: self.window)
            lastMouseDownEvent = nil
        }
    }
    
    override var mouseDownCanMoveWindow: Bool {
        return false // We handle performDrag manually based on drag detection
    }
    
    // Intercept scrollWheel for two-finger panning
    override func scrollWheel(with event: NSEvent) {
        // macOS provides cumulative scrolling deltas in points
        let dx = event.scrollingDeltaX
        let dy = event.scrollingDeltaY
        
        engine?.offset.width += dx
        engine?.offset.height += dy
    }
}
