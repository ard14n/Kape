import CoreMotion
import SwiftUI

/// Manages CoreMotion updates to detect head gestures (Nod/Tilt) in Landscape orientation.
///
/// **Architecture Note**:
/// - Uses `CMDeviceMotion.gravity.z` to detect tilt since the device is physically in Landscape on the forehead.
/// - Implements a strict State Machine to Debounce inputs and prevent accidental triggers.
/// - Uses Auto-Calibration to capture baseline position when gameplay starts.
@Observable
final class MotionManager {
    // MARK: - Constants
    
    /// Threshold in Gravity Z units (0.0 to 1.0)
    /// 0.6 G corresponds to roughly 37 degrees tilt from baseline.
    /// Range is -1.0 (Screen Up) to +1.0 (Screen Down).
    private let triggerThreshold: Double = 0.6
    
    /// The range to reset debounce (-0.2...0.2)
    private let neutralThreshold: Double = 0.2
    
    // MARK: - State Types
    
    enum MotionState: Equatable, Sendable {
        case neutral
        case triggered(GameInputEvent)
        case debouncing
    }
    
    enum GameInputEvent: Equatable, Sendable {
        case correct // Tilt Down (Screen -> Floor)
        case pass    // Tilt Up (Screen -> Ceiling)
    }
    
    enum MotionError: Error, Equatable {
        case permissionDenied
        case notAvailable
        case unknown(String)
    }
    
    // MARK: - Properties
    
    private let motionManager = CMMotionManager()
    
    /// Current state of the motion detection logic.
    private(set) var state: MotionState = .neutral
    
    /// Current Gravity Z value (for Debugging).
    private(set) var liveGravityZ: Double = 0.0
    
    /// The captured baseline Z value when gameplay starts.
    /// This allows playing while lying down or slightly tilted.
    private var baselineZ: Double = 0.0
    
    /// Stream of game events.
    private let eventContinuation: AsyncStream<GameInputEvent>.Continuation
    let eventStream: AsyncStream<GameInputEvent>
    
    /// Stream of errors.
    private let errorContinuation: AsyncStream<MotionError>.Continuation
    let errorStream: AsyncStream<MotionError>
    
    private var isMonitoring = false
    
    // MARK: - Initialization
    
    init() {
        var eventStreamContinuation: AsyncStream<GameInputEvent>.Continuation!
        self.eventStream = AsyncStream { eventStreamContinuation = $0 }
        self.eventContinuation = eventStreamContinuation
        
        var errorStreamContinuation: AsyncStream<MotionError>.Continuation!
        self.errorStream = AsyncStream { errorStreamContinuation = $0 }
        self.errorContinuation = errorStreamContinuation
    }
    
    // MARK: - Lifecycle
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        guard motionManager.isDeviceMotionAvailable else {
            errorContinuation.yield(.notAvailable)
            return
        }
        
        isMonitoring = true
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60Hz
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self else { return }
            
            if let error = error {
                if (error as NSError).code == Int(CMErrorMotionActivityNotAuthorized.rawValue) {
                     self.errorContinuation.yield(.permissionDenied)
                } else {
                     self.errorContinuation.yield(.unknown(error.localizedDescription))
                }
                return
            }
            
            guard let motion = motion else { return }
            self.processMotion(motion)
        }
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        motionManager.stopDeviceMotionUpdates()
        isMonitoring = false
        state = .neutral
        liveGravityZ = 0.0
        baselineZ = 0.0
    }
    
    /// Captures the current device attitude as the "Neutral" point.
    /// Call this when the Buffer phase ends and user is presumably holding the phone on their forehead.
    func calibrate() {
        guard let motion = motionManager.deviceMotion else { return }
        // We capture the current Z gravity.
        // Example: If user is vertical, Z ~ 0.
        // If user is lying on back looking up (phone horizontal above face), Z ~ 1.0 (Screen Down).
        // Wait, if phone is above face screen down, Z is +1.
        // If user is lying on couch (45 deg), Z is 0.7.
        // We use this baseline to detect relative changes.
        self.baselineZ = motion.gravity.z
    }
    
    // MARK: - Processing Logic
    
    private func processMotion(_ motion: CMDeviceMotion) {
        // Use Gravity Vector Z component.
        // Z axis is perpendicular to the screen.
        // Range: -1.0 (Screen Up) to +1.0 (Screen Down).
        let currentZ = motion.gravity.z
        self.processGravityZ(currentZ)
    }
    
    /// Processes a gravity Z value. Exposed for Unit Testing.
    /// - Parameter z: The gravity Z component (-1.0 to 1.0).
    func processGravityZ(_ z: Double) {
        self.liveGravityZ = z
        
        let delta = z - baselineZ
        
        // 2. State Machine
        switch state {
        case .neutral:
            // Check for triggers (Delta from baseline)
            // If delta > threshold (moving towards +1/ScreenDown) -> Correct
            if delta > triggerThreshold {
                trigger(.correct)
            } 
            // If delta < -threshold (moving towards -1/ScreenUp) -> Pass
            else if delta < -triggerThreshold {
                trigger(.pass)
            }
            
        case .triggered, .debouncing:
            // Check for return to Neutral
            if abs(delta) < neutralThreshold {
                state = .neutral
            } else {
                state = .debouncing // Remain in debounce until strict neutral
            }
        }
    }
    
    private func trigger(_ event: GameInputEvent) {
        state = .triggered(event)
        eventContinuation.yield(event)
    }
}
