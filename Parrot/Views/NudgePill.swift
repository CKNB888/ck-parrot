import AppKit
import SwiftUI

/// The floating pill: one nudge over every app, full-screen calls included,
/// for about 10 seconds. A non-activating panel, so the call app keeps the
/// keyboard, and left out of screen capture so a screen share never shows
/// the other side what Parrot noticed.
@MainActor
final class NudgePillController {
    static let shared = NudgePillController()
    static let visibleFor: TimeInterval = 10

    /// Brings Parrot forward on the live call (set by RecordingManager).
    var onOpen: (() -> Void)?
    private var panel: NSPanel?
    private var hideTask: Task<Void, Never>?
    private var hovering = false
    private var generation = 0
    /// True while Parrot itself moves the pill, so only user drags are saved.
    private var animating = false
    private var moveObserver: NSObjectProtocol?

    func show(_ nudge: Nudge) {
        generation += 1
        hovering = false
        let panel = self.panel ?? Self.makePanel()
        if self.panel == nil {
            moveObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didMoveNotification, object: panel, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.panelMoved() }
            }
        }
        self.panel = panel
        // The menu bar screen decides the style: notch → island, else under the icon.
        // ck-parrot v2.1.1: a pill the user dragged comes back where they left it,
        // on that display; a missing display or off-screen spot falls back to the default.
        let saved = PillPosition.load().flatMap { PillPosition.restore($0, screens: Self.screenFrames()) }
        let screen = saved.flatMap { s in NSScreen.screens.first { Self.displayID($0) == s.displayID } }
            ?? NSScreen.screens.first ?? NSScreen.main
        let placement = saved != nil ? .menuBar : PillPlacement.detect(safeAreaTop: screen?.safeAreaInsets.top ?? 0)
        let notchInset: CGFloat
        if case .notch(let inset) = placement { notchInset = inset } else { notchInset = 0 }
        let host = NSHostingView(rootView: NudgePillView(
            nudge: nudge,
            notchInset: notchInset,
            onOpen: { [weak self] in
                self?.hide()
                self?.onOpen?()
            },
            onDismiss: { [weak self] in self?.hide() },
            onHover: { [weak self] inside in self?.hover(inside) }))
        let size = host.fittingSize
        host.frame = NSRect(origin: .zero, size: size)
        panel.contentView = host
        panel.setContentSize(size)
        var target = NSRect(origin: .zero, size: size)
        if let screen {
            let menuBarHeight = max(screen.frame.maxY - screen.visibleFrame.maxY, NSStatusBar.system.thickness)
            target.origin = PillPlacement.origin(placement, size: size, frame: screen.frame,
                                                 menuBarHeight: menuBarHeight,
                                                 statusItemMidX: Self.statusItemMidX(on: screen))
            if let saved { target.origin = CGPoint(x: saved.x, y: saved.y) }
        }
        // Island above the menu bar; otherwise just under it.
        panel.level = notchInset > 0 ? NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1) : .statusBar
        // Slide out of the notch / menu bar instead of popping up mid-screen.
        let wasVisible = panel.isVisible && panel.alphaValue > 0.5
        if !wasVisible {
            panel.setFrame(target.offsetBy(dx: 0, dy: notchInset > 0 ? size.height * 0.6 : 8), display: false)
            panel.alphaValue = 0
        }
        panel.orderFrontRegardless()
        animating = true
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.28
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.8, 0.2, 1)
            panel.animator().setFrame(target, display: true)
            panel.animator().alphaValue = 1
        }, completionHandler: { [weak self] in
            MainActor.assumeIsolated { self?.animating = false }
        })
        scheduleHide()
    }

    func hide() {
        hideTask?.cancel()
        hideTask = nil
        guard let panel, panel.isVisible else { return }
        let fading = generation
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                // A newer nudge may have arrived during the fade.
                if self?.generation == fading { panel.orderOut(nil) }
            }
        })
    }

    private func hover(_ inside: Bool) {
        hovering = inside
        if inside { hideTask?.cancel() } else { scheduleHide() }
    }

    private func scheduleHide() {
        hideTask?.cancel()
        hideTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.visibleFor))
            guard !Task.isCancelled, let self, !self.hovering else { return }
            self.hide()
        }
    }

    /// Centre x of Parrot's menu bar icon (its status bar window), if on `screen`.
    private static func statusItemMidX(on screen: NSScreen) -> CGFloat? {
        NSApp.windows.first { window in
            window.className.contains("NSStatusBarWindow") && window.isVisible
                && window.screen == screen
        }?.frame.midX
    }

    private func panelMoved() {
        guard !animating, let panel, panel.isVisible, let screen = panel.screen else { return }
        PillPosition.save(PillPosition(displayID: Self.displayID(screen), x: panel.frame.minX, y: panel.frame.minY,
                                       width: panel.frame.width, height: panel.frame.height))
    }

    static func displayID(_ screen: NSScreen) -> UInt32 {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }

    private static func screenFrames() -> [(id: UInt32, frame: CGRect)] {
        NSScreen.screens.map { (displayID($0), $0.visibleFrame) }
    }

    private static func makePanel() -> NSPanel {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: Theme.Metrics.pillWidth, height: 48),
                            styleMask: [.nonactivatingPanel, .borderless], backing: .buffered, defer: true)
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        // Never in a screen share or recording: the other side mustn't see it.
        panel.sharingType = .none
        return panel
    }
}

struct NudgePillView: View {
    let nudge: Nudge
    /// > 0 when docked in the notch: content sits below it on a black island.
    var notchInset: CGFloat = 0
    var onOpen: () -> Void = {}
    var onDismiss: () -> Void = {}
    var onHover: (Bool) -> Void = { _ in }
    @Environment(\.colorScheme) private var colorScheme

    /// Island: square top flush with the screen edge, round bottom.
    private var pillShape: UnevenRoundedRectangle {
        let r = Theme.Metrics.pillRadius
        let top: CGFloat = notchInset > 0 ? 0 : r
        return UnevenRoundedRectangle(topLeadingRadius: top, bottomLeadingRadius: r,
                                      bottomTrailingRadius: r, topTrailingRadius: top, style: .continuous)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: nudge.kind.symbol)
                .foregroundStyle(Theme.Colors.warn)
            Text(nudge.text)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onDismiss) {
                Image(systemName: "xmark").font(Theme.Typography.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.Colors.ink3)
            .help("Dismiss")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .padding(.top, notchInset)
        .frame(width: Theme.Metrics.pillWidth)
        .environment(\.colorScheme, notchInset > 0 ? .dark : colorScheme)
        .background { pillShape.fill(notchInset > 0 ? AnyShapeStyle(Color.black) : AnyShapeStyle(.regularMaterial)) }
        .overlay { if notchInset == 0 { pillShape.stroke(Theme.Colors.nudgeLine, lineWidth: 1) } }
        .contentShape(pillShape)
        .onTapGesture(perform: onOpen)
        .onHover(perform: onHover)
    }
}

/// The same nudge inside the Copilot panel, above the coach line, until
/// dismissed or replaced.
struct NudgeBanner: View {
    let nudge: Nudge
    var onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: nudge.kind.symbol)
                .foregroundStyle(Theme.Colors.warn)
            Text(nudge.text)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button(action: onDismiss) {
                Image(systemName: "xmark").font(Theme.Typography.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.Colors.ink3)
            .help("Dismiss")
        }
        .padding(10)
        .background(Theme.Colors.nudge, in: RoundedRectangle(cornerRadius: Theme.Metrics.radius))
        .overlay(RoundedRectangle(cornerRadius: Theme.Metrics.radius).strokeBorder(Theme.Colors.nudgeLine))
    }
}

/// ck-parrot v2.1.1: where the user last dragged the pill (display + frame).
struct PillPosition: Codable, Equatable {
    static let defaultsKey = "nudgePillPosition"
    var displayID: UInt32
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat

    static func load(_ defaults: UserDefaults = .standard) -> PillPosition? {
        defaults.data(forKey: defaultsKey).flatMap { try? JSONDecoder().decode(PillPosition.self, from: $0) }
    }

    static func save(_ p: PillPosition, _ defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(p) { defaults.set(data, forKey: defaultsKey) }
    }

    /// The saved spot if its display is still attached and the pill's centre is
    /// on it (nudged fully inside); nil means "use the default placement".
    static func restore(_ p: PillPosition, screens: [(id: UInt32, frame: CGRect)]) -> PillPosition? {
        guard let frame = screens.first(where: { $0.id == p.displayID })?.frame else { return nil }
        guard frame.contains(CGPoint(x: p.x + p.width / 2, y: p.y + p.height / 2)) else { return nil }
        var q = p
        q.x = min(max(p.x, frame.minX), frame.maxX - p.width)
        q.y = min(max(p.y, frame.minY), frame.maxY - p.height)
        return q
    }
}
