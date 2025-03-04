//
//  GrowthBookInstance+FeatureFlagsRefreshPolicy.swift
//  GrowthBook-IOS
//
//  Created by Vitalii Budnik on 2/28/25.
//

import Foundation

extension GrowthBookInstance {
    /// GrowthBook feature flags refresh policy.
    public enum RefreshPolicy: Sendable, Equatable {
        /// No feature flags refresh.
        ///
        /// Will fetch feature flags once on SDK init.
        case noRefresh

        /// Refresh with polling requests.
        ///
        /// Will do polling request each interval.
        case repetitivePolling(interval: TimeInterval)

        /// Refresh with polling requests with respect to TTL in responses.
        ///
        /// Will do polling request each interval.
        case respectfulPolling(interval: TimeInterval)

        /// Update with Server Side Events.
        case serverSideEvents

        // MARK: Public

        /// Default poling policy: `.respectfulPolling`.
        public static let `default`: Self = .respectfulPolling(interval: 60.0 * 60.0)

    }
}
