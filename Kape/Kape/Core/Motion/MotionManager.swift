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
    
    /// Threshold in Radians (approx 37 degrees)
    /// Increased from 0.4 to prevent accidental triggers (User requested "stable and reliable").
    private let triggerThreshold: Double = 0.65
    
    /// The range to reset debounce (approx 8.5 degrees)
    private let neutralThreshold: Double = 0.15
    
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
    
    /// Current Roll value (for Debugging).
    private(set) var liveRoll: Double = 0.0
    
    /// The captured baseline Roll value when gameplay starts.
    private var baselineRoll: Double = 0.0
    
    /// Flag to ensure we don't process inputs before calibration.
    private var isCalibrated: Bool = false
    
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
        // Reset state on start
        isCalibrated = false
        state = .neutral
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60Hz
        
        // Start updates with a specific reference frame for better stability
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] motion, error in
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
        isCalibrated = false
        liveRoll = 0.0
        baselineRoll = 0.0
    }
    
    /// Captures the current device attitude as the "Neutral" point.
    func calibrate() {
        guard let motion = motionManager.deviceMotion else { return }
        // Use attitude.roll for longitudinal tilt in Landscape (Nodding)
        self.baselineRoll = motion.attitude.roll
        self.isCalibrated = true
    }
    
    // MARK: - Processing Logic
    
    private func processMotion(_ motion: CMDeviceMotion) {
        let roll = motion.attitude.roll
        self.liveRoll = roll
        
        // Ignore inputs until calibrated
        guard isCalibrated else { return }
        
        let delta = roll - baselineRoll
        
        // 2. State Machine
        switch state {
        case .neutral:
            // Check for triggers (Delta from baseline)
            // If delta > threshold (Tilt Down) -> Correct
            if delta > triggerThreshold {
                trigger(.correct)
            } 
            // If delta < -threshold (Tilt Up) -> Pass
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
