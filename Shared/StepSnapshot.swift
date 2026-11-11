import Foundation

/// What the widget renders. Saved into the App Group so the widget still has
/// something to show when HealthKit is locked (device locked) or unreachable.
struct StepSnapshot: Codable, Equatable {
    enum Status: String, Codable {
        case ok              // steps came from the Fitbit source
        case noSource        // Apple Health has no Fitbit / Google Health steps yet
        case needsPermission // user has not granted Health access to the app
    }

    var steps: Int
    var goal: Int
    var updatedAt: Date
    var sourceName: String?
    var status: Status

    var progress: Double { goal > 0 ? min(Double(steps) / Double(goal), 1.0) : 0 }
    var reachedGoal: Bool { steps >= goal && goal > 0 }

    var mood: BirdMood {
        guard status == .ok else { return .sleepy }
        if reachedGoal { return .party }
        if progress < 0.25 { return .sleepy }
        return .happy
    }

    var message: String {
        switch status {
        case .needsPermission: return "allow Health in app"
        case .noSource:        return "waiting for Fitbit"
        case .ok:
            if reachedGoal { return "goal reached!" }
            if progress >= 0.75 { return "almost there!" }
            if progress >= 0.25 { return "nice going!" }
            return "let's wander"
        }
    }

    /// This snapshot as it should look on the day of `now`: unchanged if it was
    /// taken that day, otherwise back to zero steps as of that day's midnight.
    /// Keeps yesterday's count from lingering after 00:00.
    func rolledOver(to now: Date = .now) -> StepSnapshot {
        let calendar = Calendar.current
        guard !calendar.isDate(updatedAt, inSameDayAs: now) else { return self }
        var fresh = self
        fresh.steps = 0
        fresh.updatedAt = calendar.startOfDay(for: now)
        return fresh
    }

    static let sample = StepSnapshot(steps: 5_432, goal: 8_000, updatedAt: .now,
                                     sourceName: "Google Health", status: .ok)
    static let empty  = StepSnapshot(steps: 0, goal: 8_000, updatedAt: .now,
                                     sourceName: nil, status: .noSource)
}

enum BirdMood { case sleepy, happy, party }
