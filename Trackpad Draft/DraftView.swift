import SwiftUI

struct DraftView: View {
    @StateObject private var engine = CanvasEngine()
    @State private var keyMonitor: Any?
    
    var body: some View {
        ZStack {
            // Background color for the translucent paper feel
            Color.white.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            
            // The drawing canvas
            Canvas { context, size in
                context.translateBy(x: engine.offset.width, y: engine.offset.height)
                
                for stroke in engine.strokes {
                    var path = Path()
                    guard let first = stroke.points.first else { continue }
                    path.move(to: first)
                    for point in stroke.points.dropFirst() {
                        path.addLine(to: point)
                    }
                    context.stroke(path, with: .color(stroke.color), style: StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round, lineJoin: .round))
                }
                
                // Draw current stroke
                if let active = engine.currentStroke, let first = active.points.first {
                    var path = Path()
                    path.move(to: first)
                    for point in active.points.dropFirst() {
                        path.addLine(to: point)
                    }
                    context.stroke(path, with: .color(active.color), style: StrokeStyle(lineWidth: active.lineWidth, lineCap: .round, lineJoin: .round))
                }
            }
            
            // The Touch Input overlay
            TouchCanvasView(engine: engine)
                .edgesIgnoringSafeArea(.all)
                
            // Virtual Cursor
            if !engine.isMouseVisible, let vPos = engine.virtualCursorPosition {
                ZStack {
                    if engine.currentMode == .eraser {
                        // Eraser: dashed ring showing erase radius
                        Circle()
                            .stroke(Color.secondary.opacity(0.5), style: SwiftUI.StrokeStyle(lineWidth: 1, dash: [3, 3]))
                            .frame(width: engine.eraserRadius * 2, height: engine.eraserRadius * 2)
                    } else {
                        // Pen: tiny solid dot with subtle halo
                        Circle()
                            .fill(Color.primary.opacity(0.15))
                            .frame(width: 12, height: 12)
                    }
                    Circle()
                        .fill(Color.primary.opacity(0.6))
                        .frame(width: 4, height: 4)
                }
                .position(vPos)
                .allowsHitTesting(false)
            }
            
            // UI Overlay
            VStack {
                HStack {
                    Spacer()
                    // Compact toolbar at top trailing
                    VStack(spacing: 10) {
                        Button(action: { engine.currentMode = .pen }) {
                            VStack(spacing: 3) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14))
                                    .foregroundColor(engine.currentMode == .pen ? .blue : .primary)
                                Text("1")
                                    .font(.system(size: 8, weight: .bold, design: .rounded))
                                    .foregroundColor(engine.currentMode == .pen ? .blue : .primary.opacity(0.7))
                                    .frame(width: 13, height: 13)
                                    .background(Circle().fill(engine.currentMode == .pen ? Color.blue.opacity(0.2) : Color.primary.opacity(0.1)))
                            }
                            .frame(width: 38, height: 38)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Pen size indicator (only when pen is active & mouse visible)
                        if engine.isMouseVisible && engine.currentMode == .pen {
                            VStack(spacing: 2) {
                                Circle()
                                    .fill(Color.primary)
                                    .frame(width: engine.penLineWidth, height: engine.penLineWidth)
                                    .frame(width: 18, height: 18)
                                Slider(value: $engine.penLineWidth, in: 1...8, step: 0.5)
                                    .frame(width: 55)
                                    .controlSize(.mini)
                            }
                        }
                        
                        Button(action: { engine.currentMode = .eraser }) {
                            VStack(spacing: 3) {
                                Image(systemName: "eraser")
                                    .font(.system(size: 14))
                                    .foregroundColor(engine.currentMode == .eraser ? .blue : .primary)
                                Text("2")
                                    .font(.system(size: 8, weight: .bold, design: .rounded))
                                    .foregroundColor(engine.currentMode == .eraser ? .blue : .primary.opacity(0.7))
                                    .frame(width: 13, height: 13)
                                    .background(Circle().fill(engine.currentMode == .eraser ? Color.blue.opacity(0.2) : Color.primary.opacity(0.1)))
                            }
                            .frame(width: 38, height: 38)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Eraser size indicator (only when eraser is active & mouse visible)
                        if engine.isMouseVisible && engine.currentMode == .eraser {
                            VStack(spacing: 2) {
                                Circle()
                                    .stroke(Color.secondary, lineWidth: 1)
                                    .frame(width: min(engine.eraserRadius, 18), height: min(engine.eraserRadius, 18))
                                    .frame(width: 18, height: 18)
                                Slider(value: $engine.eraserRadius, in: 5...40, step: 1)
                                    .frame(width: 55)
                                    .controlSize(.mini)
                            }
                        }
                        
                        Divider().frame(width: 14)
                        
                        // Undo button
                        Button(action: { engine.undo() }) {
                            VStack(spacing: 3) {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.system(size: 14))
                                    .foregroundColor(engine.canUndo ? .primary : .primary.opacity(0.3))
                                Text("⌘Z")
                                    .font(.system(size: 7, weight: .bold, design: .rounded))
                                    .foregroundColor(engine.canUndo ? .primary.opacity(0.7) : .primary.opacity(0.2))
                                    .frame(width: 18, height: 13)
                                    .background(Capsule().fill(engine.canUndo ? Color.primary.opacity(0.1) : Color.clear))
                            }
                            .frame(width: 38, height: 38)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .keyboardShortcut("z", modifiers: .command)
                        .disabled(!engine.canUndo)
                        
                        Button(action: {
                            engine.clearAll()
                            engine.offset = .zero
                        }) {
                            VStack(spacing: 3) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                Text("⌫")
                                    .font(.system(size: 7, weight: .bold, design: .rounded))
                                    .foregroundColor(.red.opacity(0.8))
                                    .frame(width: 13, height: 13)
                                    .background(Circle().fill(Color.red.opacity(0.15)))
                            }
                            .frame(width: 38, height: 38)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .keyboardShortcut(.delete, modifiers: []) // Trigger with Backspace
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.85)))
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    .padding(.trailing, 12)
                    .padding(.top, 12)
                    .opacity(engine.isMouseVisible ? 1.0 : 0.4) // Kept dimly visible when drawing
                    .animation(.easeInOut(duration: 0.2), value: engine.isMouseVisible)
                }
                
                Spacer() // push to top
                
                // Hidden button for Escape
                Button(action: {
                    DraftWindowManager.shared.hideWindow()
                }) {
                    EmptyView()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .opacity(0)
            }
        }
        .onAppear {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
                if event.modifierFlags.contains(.command) {
                    // Cmd+Z: undo
                    if event.keyCode == 6 { // Z key
                        engine.undo()
                        return nil
                    }
                } else {
                    switch event.keyCode {
                    case 18: // 1
                        engine.currentMode = .pen
                        return nil
                    case 19: // 2
                        engine.currentMode = .eraser
                        return nil
                    default:
                        break
                    }
                }
                return event
            }
        }
        .onDisappear {
            if let m = keyMonitor {
                NSEvent.removeMonitor(m)
                keyMonitor = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .draftWindowDidShow)) { notification in
            if let info = notification.object as? [String: Bool], let isFirstTime = info["isFirstTime"], isFirstTime {
                // Start in mouse mode when window opens for the first time
                engine.isMouseVisible = true
            } else {
                engine.isMouseVisible = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .draftWindowDidHide)) { _ in
            // Reset to mouse mode so state is consistent next time the window shows
            engine.isMouseVisible = true
        }
    }
}
