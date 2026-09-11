import CoreMotion
import SwiftUI

/// Manages CoreMotion updates to detect head gestures (Nod/Tilt) in Landscape orientation.
///
/// **Architecture Note**:
/// - Uses `CMDeviceMotion.gravity.z` to detect tilt since the device is physically in Landscape on the forehead.
/// - Implements a strict State Machine to Debounce inputs and prevent accidental triggers.
/// - Uses Auto-Calibration to capture baseline position when gameplay starts.
@Observable
@MainActor
final class MotionManager {
    // Avoid the implicit isolated-deinit back-deployment bug (swiftlang/swift#88036).
    nonisolated deinit {}
    // MARK: - Constants
    
    /// Threshold in Radians (approx 45 degrees)
    /// Increased from 0.65 to reduce sensitivity and prevent accidental triggers.
    private let triggerThreshold: Double = 0.785
    
    /// The range to reset debounce (approx 11.5 degrees)
    /// Increased to improve reliability and prevent false neutral detection.
    private let neutralThreshold: Double = 0.20
    
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
    
    enum CalibrationState: Equatable, Sendable {
        case notStarted
        case checking
        case valid
        case invalid(reason: String)
    }
    
    // MARK: - Properties
    
    private let motionProvider: MotionProviding
    
    /// Current state of the motion detection logic.
    private(set) var state: MotionState = .neutral
    
    /// Current screen tilt angle (for Debugging).
    private(set) var liveTilt: Double = 0.0
    
    /// The captured baseline tilt angle when gameplay starts.
    private var baselineTilt: Double = 0.0
    
    /// Flag to ensure we don't process inputs before calibration.
    private var isCalibrated: Bool = false
    
    /// Current calibration validation state
    private(set) var calibrationState: CalibrationState = .notStarted
    
    /// Acceptable range for device position (in radians, ~15 degrees)
    private let positionTolerance: Double = 0.26
    
    /// Stream of game events.
    private var eventContinuation: AsyncStream<GameInputEvent>.Continuation
    private(set) var eventStream: AsyncStream<GameInputEvent>
    
    /// Stream of errors.
    private let errorContinuation: AsyncStream<MotionError>.Continuation
    let errorStream: AsyncStream<MotionError>
    
    private var isMonitoring = false
    
    // MARK: - Initialization
    
    init(motionProvider: MotionProviding? = nil) {
        self.motionProvider = motionProvider ?? DeviceMotionProvider()
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
        
        guard motionProvider.isAvailable else {
            errorContinuation.yield(.notAvailable)
            return
        }
        
        isMonitoring = true
        // Reset state on start
        isCalibrated = false
        state = .neutral
        
        motionProvider.start { [weak self] sample, error in
            guard let self else { return }

            if let error = error {
                if (error as NSError).code == Int(CMErrorMotionActivityNotAuthorized.rawValue) {
                     self.errorContinuation.yield(.permissionDenied)
                } else {
                     self.errorContinuation.yield(.unknown(error.localizedDescription))
                }
                return
            }
            
            guard let sample, sample.isFinite else { return }
            self.processTilt(sample.tilt)
        }
    }
    
    func stopMonitoring() {
        motionProvider.stop()
        isMonitoring = false
        state = .neutral
        isCalibrated = false
        liveTilt = 0.0
        baselineTilt = 0.0
        calibrationState = .notStarted
    }
    
    /// Validates that the device is in the correct position for gameplay.
    /// The device should be roughly vertical (on forehead) in landscape orientation.
    /// Returns true if position is valid, false otherwise.
    func validatePosition() -> Bool {
        validate(motionProvider.currentSample)
    }

    private func validate(_ sample: MotionSample?) -> Bool {
        guard let sample, sample.isFinite else {
            calibrationState = .invalid(reason: "Sensor data unavailable")
            return false 
        }
        
        calibrationState = .checking
        
        // Device-fixed gravity axes work in both landscape orientations.
        // Screen must be vertical, with the phone's long edge horizontal.
        if abs(sample.tilt) > positionTolerance || abs(sample.y) > sin(positionTolerance) || abs(sample.x) < 0.9 {
            calibrationState = .invalid(reason: "Device not upright. Place phone on forehead in landscape.")
            return false
        }
        
        calibrationState = .valid
        return true
    }
    
    /// Captures the current device attitude as the "Neutral" point.
    /// Should only be called after validatePosition() returns true.
    @discardableResult
    func calibrate() -> Bool {
        let sample = motionProvider.currentSample
        guard validate(sample), let sample else {
            isCalibrated = false
            return false
        }
        baselineTilt = sample.tilt
        isCalibrated = true
        state = .neutral
        return true
    }
    
    // MARK: - Processing Logic
    
    private func processTilt(_ tilt: Double) {
        self.liveTilt = tilt
        
        // Ignore inputs until calibrated
        guard isCalibrated else { return }
        
        let delta = tilt - baselineTilt
        
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
    
    /// A cancelled AsyncStream consumer terminates its stream. Each round needs a new channel.
    func prepareForNewRound() {
        stopMonitoring()
        _ = beginInputStream()
    }

    /// Discards calibration/countdown events without losing inputs once gameplay starts.
    func beginInputStream() -> AsyncStream<GameInputEvent> {
        eventContinuation.finish()
        state = .neutral
        let channel = AsyncStream<GameInputEvent>.makeStream()
        eventStream = channel.stream
        eventContinuation = channel.continuation
        return channel.stream
    }

    // MARK: - Testing Support

    /// Legacy test hook: injects a calibrated tilt angle in radians through the same production state machine.
    func processGravityZ(_ rollValue: Double) {
        let wasCalibrated = isCalibrated
        let previousBaseline = baselineTilt
        isCalibrated = true
        baselineTilt = 0
        processTilt(rollValue)
        isCalibrated = wasCalibrated
        baselineTilt = previousBaseline
    }
}

/// Minimal sensor boundary: deterministic tests use the same calibration and input code as devices.
@MainActor
protocol MotionProviding {
    var isAvailable: Bool { get }
    var currentSample: MotionSample? { get }
    func start(_ handler: @escaping @MainActor (MotionSample?, Error?) -> Void)
    func stop()
}

final class DeviceMotionProvider: MotionProviding {
    // Avoid the implicit isolated-deinit back-deployment bug (swiftlang/swift#88036).
    nonisolated deinit {}
    private let manager = CMMotionManager()
    var isAvailable: Bool { manager.isDeviceMotionAvailable }
    var currentSample: MotionSample? { manager.deviceMotion.map { MotionSample($0.gravity) } }

    func start(_ handler: @escaping @MainActor (MotionSample?, Error?) -> Void) {
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { motion, error in
            // CoreMotion delivers this closure on OperationQueue.main.
            MainActor.assumeIsolated {
                handler(motion.map { MotionSample($0.gravity) }, error)
            }
        }
    }

    func stop() { manager.stopDeviceMotionUpdates() }
}

/// Gravity is measured in device-fixed axes; positive Z points out of the screen.
/// Screen toward floor => positive tilt, toward ceiling => negative tilt.
struct MotionSample: Equatable, Sendable {
    let x: Double
    let y: Double
    let z: Double
    init(x: Double, y: Double, z: Double) { self.x = x; self.y = y; self.z = z }
    init(_ gravity: CMAcceleration) { self.init(x: gravity.x, y: gravity.y, z: gravity.z) }
    var isFinite: Bool { x.isFinite && y.isFinite && z.isFinite }
    var tilt: Double { asin(max(-1, min(1, z))) }
}
