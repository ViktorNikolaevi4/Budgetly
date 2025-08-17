import Foundation
import SwiftUI

class AppTrialManager {
    @AppStorage("firstLaunchDate") private var firstLaunchDate: Double = 0
    @AppStorage("hasSubscribed") private var hasSubscribed: Bool = false  // Если когда-то подписался

    init() {
        if firstLaunchDate == 0 {
            firstLaunchDate = Date().timeIntervalSince1970
        }
    }

    var isInTrial: Bool {
        let now = Date().timeIntervalSince1970
        let daysPassed = (now - firstLaunchDate) / (24 * 3600)
        return daysPassed < 3 && !hasSubscribed
    }

    var trialDaysLeft: Int {
        let now = Date().timeIntervalSince1970
        let daysPassed = (now - firstLaunchDate) / (24 * 3600)
        return max(0, 3 - Int(daysPassed))
    }

    func markAsSubscribed() {
        hasSubscribed = true
    }

    var shouldShowPaywall: Bool {
        !isInTrial && !hasSubscribed
    }
}
