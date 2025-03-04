import Foundation

protocol SystemStateObserverForTimerDelegate: AnyObject, Sendable {
    func systemDidBecomeActive()
    func systemWillBecomeInactive()
}

protocol SystemStateObserverForTimerInterface: AnyObject, Sendable {
    var delegate: SystemStateObserverForTimerDelegate? { get set }
    var canScheduleTimer: Bool { get }
}

#if os(iOS)
import UIKit
final class SystemStateObserverForTimer: SystemStateObserverForTimerInterface, Sendable {
    private class MutableState {
        weak var delegate: (any SystemStateObserverForTimerDelegate)?
        var canScheduleTimer: Bool

        init(delegate: (any SystemStateObserverForTimerDelegate)? = nil, canScheduleTimer: Bool) {
            self.delegate = delegate
            self.canScheduleTimer = canScheduleTimer
        }
    }

    private let mutableState: Protected<MutableState>

    private let notificationCenter: NotificationCenter

    var delegate: (any SystemStateObserverForTimerDelegate)? {
        get { mutableState.read(\.delegate) }
        set { updateDelegate(to: newValue) }
    }

    var canScheduleTimer: Bool { mutableState.read(\.canScheduleTimer) }

    static func isSystemReadyForTimerSetup() -> Bool {
        UIApplication.shared.applicationState == .active
    }

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        self.mutableState = .init(MutableState(canScheduleTimer: Self.isSystemReadyForTimerSetup()))
        setupSystemStateObservers()
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    /// Subscribes to app state notifications.
    private func setupSystemStateObservers() {
        notificationCenter.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(appDidEnterForeground),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    /// Updates delegate to a new value and asks old delegates to stop timer,
    /// and new timer receives request based on the current `canScheduleTimer` value.
    ///
    /// - Parameter newValue: A new delegate value.
    private func updateDelegate(to newValue: (any SystemStateObserverForTimerDelegate)?) {
        let (oldDelegate, canScheduleTimer) = mutableState.write {
            let oldDelegate = $0.delegate
            $0.delegate = newValue
            return (oldDelegate, $0.canScheduleTimer)
        }
        notify(delegate: oldDelegate, canScheduleTimer: false)
        notify(delegate: newValue, canScheduleTimer: canScheduleTimer)
    }

    /// Asks the delegate to stop or start timer based on a `canScheduleTimer` value.
    ///
    /// - Parameters:
    ///   - delegate: A delegate to notify.
    ///   - canScheduleTimer: A `Bool` representing if delegate must schedule timer or stop it.
    private func notify(delegate: (any SystemStateObserverForTimerDelegate)?, canScheduleTimer: Bool) {
        guard let delegate = delegate else { return }

        if canScheduleTimer {
            delegate.scheduleTimer()
        } else {
            delegate.stopTimer()
        }
    }

    /// Changes the `canScheduleTimer` property to a new value and notifies delegate if needed.
    ///
    /// - Parameter newValue: A new value for the `canScheduleTimer`.
    private func changeCanScheduleTimerValue(to newValue: Bool) {
        let (delegate, valueDidChange) = mutableState.write { mutableState in
            let valueDidChange: Bool = mutableState.canScheduleTimer != newValue
            mutableState.canScheduleTimer = newValue
            return (mutableState.delegate, valueDidChange)
        }

        guard valueDidChange else { return }

        notify(delegate: delegate, canScheduleTimer: newValue)
    }

    /// Changes changeCanSchedule to `true`
    ///
    /// Called when the app becomes active.
    @objc private func appDidEnterForeground() {
        changeCanScheduleTimerValue(to: true)
    }

    /// Changes changeCanSchedule to `false`
    ///
    /// Called when the app goes to background.
    @objc private func appDidEnterBackground() {
        changeCanScheduleTimerValue(to: false)
    }
}
#else
import Cocoa
import IOKit.pwr_mgt

final class SystemStateObserverForTimer: SystemStateObserverForTimerInterface, Sendable {
    private class MutableState {
        weak var delegate: (any SystemStateObserverForTimerDelegate)?
        var canScheduleTimer: Bool

        init(delegate: (any SystemStateObserverForTimerDelegate)? = nil, canScheduleTimer: Bool) {
            self.delegate = delegate
            self.canScheduleTimer = canScheduleTimer
        }
    }

    private let mutableState: Protected<MutableState>

    private let notificationCenter: NotificationCenter

    var delegate: (any SystemStateObserverForTimerDelegate)? {
        get { mutableState.read(\.delegate) }
        set { updateDelegate(to: newValue) }
    }

    var canScheduleTimer: Bool { mutableState.read(\.canScheduleTimer) }

    static func isSystemReadyForTimerSetup() -> Bool {
        let idleSleepAssertion: UnsafeMutablePointer<IOPMAssertionID> = .allocate(capacity: 1)
        defer { idleSleepAssertion.deinitialize(count: 1) }
        let sleepStatus = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoIdleSleep as CFString, IOPMAssertionLevel(kIOPMAssertionLevelOn), "Check if system is asleep" as CFString, idleSleepAssertion)

        if sleepStatus == kIOReturnSuccess {
            return false // System is not asleep
        } else {
            return true // System is asleep
        }
    }

    init(notificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter) {
        self.notificationCenter = notificationCenter
        self.mutableState = .init(MutableState(canScheduleTimer: Self.isSystemReadyForTimerSetup()))
        setupSystemStateObservers()
    }

    deinit {
        notificationCenter.removeObserver(self)
    }
    
    /// Subscribes to sleep mode notifications.
    private func setupSystemStateObservers() {
        // Observe sleep mode for macOS.
        notificationCenter.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWakeUp),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }
    
    /// Updates delegate to a new value and asks old delegates to stop timer,
    /// and new timer receives request based on the current `canScheduleTimer` value.
    ///
    /// - Parameter newValue: A new delegate value.
    private func updateDelegate(to newValue: (any SystemStateObserverForTimerDelegate)?) {
        let (oldDelegate, canScheduleTimer) = mutableState.write {
            let oldDelegate = $0.delegate
            $0.delegate = newValue
            return (oldDelegate, $0.canScheduleTimer)
        }
        notify(delegate: oldDelegate, canScheduleTimer: false)
        notify(delegate: newValue, canScheduleTimer: canScheduleTimer)
    }
    
    /// Asks the delegate to stop or start timer based on a `canScheduleTimer` value.
    ///
    /// - Parameters:
    ///   - delegate: A delegate to notify.
    ///   - canScheduleTimer: A `Bool` representing if delegate must schedule timer or stop it.
    private func notify(delegate: (any SystemStateObserverForTimerDelegate)?, canScheduleTimer: Bool) {
        guard let delegate = delegate else { return }

        if canScheduleTimer {
            delegate.systemDidBecomeActive()
        } else {
            delegate.systemWillBecomeInactive()
        }
    }

    /// Changes the `canScheduleTimer` property to a new value and notifies delegate if needed.
    ///
    /// - Parameter newValue: A new value for the `canScheduleTimer`.
    private func changeCanScheduleTimerValue(to newValue: Bool) {
        let (delegate, valueDidChange) = mutableState.write { mutableState in
            let valueDidChange: Bool = mutableState.canScheduleTimer != newValue
            mutableState.canScheduleTimer = newValue
            return (mutableState.delegate, valueDidChange)
        }

        guard valueDidChange else { return }

        notify(delegate: delegate, canScheduleTimer: newValue)
    }

    /// Changes changeCanSchedule to `true`
    ///
    ///Called when the system wakes up.
    @objc private func systemDidWakeUp() {
        changeCanScheduleTimerValue(to: true)
    }

    /// Changes changeCanSchedule to `false`
    ///
    /// Called when the system goes to sleep.
    @objc private func systemWillSleep() {
        changeCanScheduleTimerValue(to: false)
    }
}
#endif

protocol TimerInterface {
    init(
        systemStateObserverForTimer: SystemStateObserverForTimerInterface,
        timerInterval: TimeInterval,
        timerAction: @escaping @Sendable () -> Void
    )

    func enable()
    func disable()
    func rescheduleNotEarlierThan(in seconds: Int)
}

extension CrossPlatformTimer: TimerInterface {
    func rescheduleNotEarlierThan(in seconds: Int) {
        mutableState.write(\.runNotEarlierThan,  Date(timeIntervalSinceNow: TimeInterval(seconds)))
        scheduleTimer()
    }

    func enable() {
        mutableState.write(\.isEnabled, true)
        scheduleTimer()
    }
    
    func disable() {
        mutableState.write(\.isEnabled, false)
        stopTimer()
    }
}

final class CrossPlatformTimer: Sendable {
    private class MutableState {
        var isEnabled: Bool = false
        var timer: DispatchSourceTimer?
        var lastExecutionTime: Date?
        var runNotEarlierThan: Date?

        init(timer: DispatchSourceTimer? = nil, lastExecutionTime: Date? = nil, runNotEarlierThan: Date? = nil) {
            self.timer = timer
            self.lastExecutionTime = lastExecutionTime
            self.runNotEarlierThan = runNotEarlierThan
        }

        deinit {
            timer?.cancel()
            timer = .none
        }
    }

    private let mutableState: Protected<MutableState>

    // Timer closure
    private let timerAction: @Sendable () -> Void

    private let systemStateObserverForTimer: SystemStateObserverForTimerInterface
    private let timerInterval: TimeInterval

    init(
        systemStateObserverForTimer: SystemStateObserverForTimerInterface = SystemStateObserverForTimer(),
        timerInterval: TimeInterval = 60.0 * 60.0,
        timerAction: @escaping @Sendable () -> Void
    ) {
        self.systemStateObserverForTimer = systemStateObserverForTimer
        self.timerInterval = timerInterval
        self.mutableState = .init(.init(timer: .none, lastExecutionTime: .none))
        self.timerAction =  timerAction
        systemStateObserverForTimer.delegate = self
        if systemStateObserverForTimer.canScheduleTimer {
            scheduleTimer()
        }
    }

    deinit {
        stopTimer()
    }

    // Start the timer
    private func scheduleTimer() {
        // Create a DispatchSourceTimer
        let timer: DispatchSourceTimer?
        let lastExecutionTime: Date?
        let runNotEarlierThan: Date?

        stopTimer()

        (timer, lastExecutionTime, runNotEarlierThan) = mutableState.write { mutableState in

            guard mutableState.isEnabled else { return (.none, .none, .none) }

            let timer: DispatchSourceTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
            mutableState.timer = timer
            return (timer, mutableState.lastExecutionTime, mutableState.runNotEarlierThan)
        }

        guard let timer else { return }

        let nowDate: Date = Date()
        let leftTimeInterval: TimeInterval = max(
            // Time interval reduced by time since the last fetch.
            // Handles cases when system is back alive from sleep and background mode.
            timerInterval - nowDate.timeIntervalSince(lastExecutionTime ?? nowDate),

            // Should not run earlier than specified date.
            runNotEarlierThan?.timeIntervalSince(nowDate) ?? 0.0,

            // Should not be negative
            0.0
        )

        print("Scheduling timer in \(leftTimeInterval) seconds")

        timer.schedule(deadline: .now() + leftTimeInterval, repeating: timerInterval)

        // Handle the timer firing
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            self.timerAction()
            self.mutableState.write(\.lastExecutionTime, Date())
        }

        // Start the timer
        timer.resume()
    }

    // Stop the timer
    private func stopTimer() {
        mutableState.write { mutableState in
            mutableState.timer?.cancel()
            mutableState.timer = .none
        }
    }
}

extension CrossPlatformTimer: SystemStateObserverForTimerDelegate {
    func systemDidBecomeActive() {
        scheduleTimer()
    }

    func systemWillBecomeInactive() {
        stopTimer()
    }
}
