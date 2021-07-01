//
// Xcore
// Copyright © 2019 Xcore
// MIT license, see LICENSE file for details
//

import Foundation

// MARK: - Namespace

public enum IdleTimer { }

// MARK: - API

extension IdleTimer {
    private static let windowContainer = WindowContainer()

    /// Updates existing or creates a new timeout gesture for given `window` object.
    ///
    /// You can observe the timeout event using
    /// `UIApplication.willTimeOutUserInteractionNotification`
    /// and `UIApplication.didTimeOutUserInteractionNotification`.
    public static func setUserInteractionTimeout(duration: TimeInterval, warningDuration: TimeInterval? = nil, for window: UIWindow?) {
        guard let window = window else {
            return
        }

        windowContainer.add(window)
        windowContainer.configure(timeoutDuration: duration, warningDuration: warningDuration)
    }
}
