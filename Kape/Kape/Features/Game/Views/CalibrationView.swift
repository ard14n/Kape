import SwiftUI

/// Validates the neutral pose before a new round and after interruptions.
struct CalibrationView: View {
    let motionManager: MotionManager
    let onCalibrated: () -> Void
    @State private var isValid = false
    @State private var statusMessage = "Vendose telefonin horizontalisht mbi ballë."

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                if geometry.size.width > geometry.size.height {
                    HStack(spacing: 24) { indicator; instructions }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 24)
                        .frame(minHeight: geometry.size.height)
                } else {
                    VStack(spacing: 24) { indicator; instructions }
                        .padding(24)
                        .padding(.top, 40)
                        .frame(minHeight: geometry.size.height)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("CalibrationScreen")
        .task {
            while !Task.isCancelled {
                isValid = motionManager.validatePosition()
                if isValid {
                    statusMessage = "Pozicioni është i saktë!"
                    // Revalidate after the settling period; never start from a stale pose.
                    do { try await Task.sleep(for: .milliseconds(500)) } catch { return }
                    guard !Task.isCancelled else { return }
                    if motionManager.calibrate() {
                        onCalibrated()
                        return
                    }
                } else {
                    statusMessage = "Vendose telefonin horizontalisht mbi ballë."
                    if case .invalid(let reason) = motionManager.calibrationState,
                       reason == "Sensor data unavailable" {
                        statusMessage = "Sensori i lëvizjes nuk është gati. Provo përsëri ose kthehu te kategoritë."
                    }
                }
                do { try await Task.sleep(for: .milliseconds(250)) } catch { return }
            }
        }
    }

    private var indicator: some View {
        Image(systemName: isValid ? "checkmark.circle.fill" : "iphone")
            .font(.system(size: 56))
            .foregroundStyle(isValid ? Color.neonGreen : Color.neonRed)
            .rotationEffect(.degrees(isValid ? 0 : -90))
            .frame(width: 104, height: 104)
            .background((isValid ? Color.neonGreen : Color.neonRed).opacity(0.15), in: Circle())
            .accessibilityHidden(true)
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kalibrimi").font(.title.bold()).foregroundStyle(.white)
                .accessibilityIdentifier("CalibrationTitle")
            Text(statusMessage).font(.body).foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("CalibrationStatus")
            Text("Mbaje ekranin nga miqtë dhe prit një çast.")
                .font(.callout).foregroundStyle(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
