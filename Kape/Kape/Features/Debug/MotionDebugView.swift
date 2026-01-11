import SwiftUI

struct MotionDebugView: View {
    @State private var motionManager = MotionManager()
    @State private var eventLog: [String] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Motion Debugger")
                .font(.largeTitle.bold())
            
            // Live Data
            VStack {
                Text("Gravity Z")
                    .foregroundStyle(.secondary)
                Text(String(format: "%.2f", motionManager.liveGravityZ))
                    .font(.system(size: 60, weight: .black, design: .monospaced))
                    .foregroundStyle(colorForState(motionManager.state))
                
                Button("Calibrate Zero") {
                    motionManager.calibrate()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
            
            // State Indicator
            Text(stateDescription(motionManager.state))
                .font(.title2)
                .padding()
                .background(Capsule().fill(colorForState(motionManager.state).opacity(0.2)))
            
            // Event Log
            List {
                ForEach(eventLog.reversed(), id: \.self) { log in
                    Text(log)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxHeight: 200)
            .listStyle(.plain)
            
            Spacer()
            
            Button(action: {
                eventLog.removeAll()
            }) {
                Label("Clear Log", systemImage: "trash")
            }
        }
        .padding()
        .onAppear {
            motionManager.startMonitoring()
            Task {
                for await event in motionManager.eventStream {
                    let timestamp = Date().formatted(date: .omitted, time: .standard)
                    let eventName = (event == .correct) ? "✅ CORRECT" : "⏭️ PASS"
                    eventLog.append("[\(timestamp)] \(eventName)")
                }
            }
        }
        .onDisappear {
            motionManager.stopMonitoring()
        }
    }
    
    private func colorForState(_ state: MotionManager.MotionState) -> Color {
        switch state {
        case .neutral: return .blue
        case .triggered(.correct): return .green
        case .triggered(.pass): return .orange
        case .debouncing: return .gray
        }
    }
    
    private func stateDescription(_ state: MotionManager.MotionState) -> String {
        switch state {
        case .neutral: return "Neutral"
        case .triggered(.correct): return "TRIGGERED: Correct"
        case .triggered(.pass): return "TRIGGERED: Pass"
        case .debouncing: return "Debouncing..."
        }
    }
}

#Preview {
    MotionDebugView()
}
