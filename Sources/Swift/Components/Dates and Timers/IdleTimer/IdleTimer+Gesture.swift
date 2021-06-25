//
// Xcore
// Copyright © 2019 Xcore
// MIT license, see LICENSE file for details
//

import UIKit

// MARK: - Notification

extension UIApplication {
    /// Posted before the `didTimeOutUserInteractionNotification`.
    ///
    /// - See: `IdleTimer.setUserInteractionTimeout(duration:for:)`
    public static var willTimeOutUserInteractionNotification: Notification.Name {
        .init(#function)
    }

    /// Posted after the user interaction timeout.
    ///
    /// - See: `IdleTimer.setUserInteractionTimeout(duration:for:)`
    public static var didTimeOutUserInteractionNotification: Notification.Name {
        .init(#function)
    }
}

extension NotificationCenter.Event {
    /// Posted before the `didTimeOutUserInteractionNotification`.
    ///
    /// - See: `IdleTimer.setUserInteractionTimeout(duration:for:)`
    @discardableResult
    public func applicationWillTimeOutUserInteraction(_ callback: @escaping () -> Void) -> NSObjectProtocol {
        observe(UIApplication.willTimeOutUserInteractionNotification, callback)
    }

    /// Posted after the user interaction timeout.
    ///
    /// - See: `IdleTimer.setUserInteractionTimeout(duration:for:)`
    @discardableResult
    public func applicationDidTimeOutUserInteraction(_ callback: @escaping () -> Void) -> NSObjectProtocol {
        observe(UIApplication.didTimeOutUserInteractionNotification, callback)
    }
}

// MARK: - Gesture

extension IdleTimer {
    final private class Gesture: UIGestureRecognizer {
        private let onTouchesEnded: () -> Void

        init(onTouchesEnded: @escaping () -> Void) {
            self.onTouchesEnded = onTouchesEnded
            super.init(target: nil, action: nil)
            cancelsTouchesInView = false
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
            onTouchesEnded()
            state = .failed
            super.touchesEnded(touches, with: event)
        }
    }
}

// MARK: - Windows

extension IdleTimer {
    final class WindowContainer {
        private let mainTimer: InternalTimer
        private let warningTimer: InternalTimer

        /// The timeout duration in seconds, after which idle timer notification is
        /// posted.
        var timeoutDuration: TimeInterval {
            mainTimer.timeoutDuration
        }

        /// The timeout duration in seconds, before which the main timer notifiacation
        /// is posted.
        var warningDuration: TimeInterval {
            warningTimer.timeoutDuration
        }

        init() {
            mainTimer = .init(timeoutAfter: 0) {
                NotificationCenter.default.post(name: UIApplication.didTimeOutUserInteractionNotification, object: nil)
            }

            warningTimer = .init(timeoutAfter: 0) {
                NotificationCenter.default.post(name: UIApplication.willTimeOutUserInteractionNotification, object: nil)
            }
        }

        func add(_ window: UIWindow) {
            if window.gestureRecognizers?.firstElement(type: IdleTimer.Gesture.self) != nil {
                // Return we already have the gesture added to the given window.
                return
            }

            let newGesture = Gesture { [weak self] in
                self?.mainTimer.wake()
                self?.warningTimer.wake()
            }
            window.addGestureRecognizer(newGesture)
        }

        /// Configures timeout and warning timeout for the window container.
        ///
        /// - Parameters:
        ///   - timeoutDuration: The TimeInterval which idle main timer.
        ///   - warningDuration: The TimeInterval specifies duration before
        ///      the main timer is called. Value should be lower then
        ///      timeoutDuration.
        func configure(timeoutDuration: TimeInterval, warningDuration: TimeInterval? = nil) {
            self.mainTimer.timeoutDuration = timeoutDuration
            if let warningDuration = warningDuration {
                #if DEBUG
                guard warningDuration < timeoutDuration else {
                    fatalError("IdleTimer: warningDuration should be lower then timeoutDuration")
                }
                #endif

                self.warningTimer.timeoutDuration = max(0, timeoutDuration - warningDuration)
            }
        }
    }
}
