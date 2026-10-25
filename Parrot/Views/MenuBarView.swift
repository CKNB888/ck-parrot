import SwiftUI
import SwiftData

/// Content of the menu-bar extra, shown as a panel (.menuBarExtraStyle(.window)
/// in ParrotApp) rather than an NSMenu: a menu can't be kept out of screen
/// sharing, a window can. ParrotAppDelegate.applyShareProtection() sets
/// sharingType = .none on it like on every other window, so viewers of a
/// shared screen never see it — even while it's open.
struct MenuBarView: View {
    @Environment(RecordingManager.self) private var recordingManager
    @Environment(ProfileStore.self) private var profileStore
    @Environment(AppSession.self) private var appSession
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @Query(sort: \CallProfile.sortOrder) private var profiles: [CallProfile]
    @Query(Self.recentFirst) private var recent: [Meeting]
    @AppStorage(ParrotAppDelegate.hideFromShareKey) private var hideFromShare = true
    @State private var tab: Tab = .now

    enum Tab: Hashable { case now, recent }

    static let repoURL = URL(string: "https://github.com/CKNB888/ck-parrot")!

    private static var recentFirst: FetchDescriptor<Meeting> {
        var descriptor = FetchDescriptor<Meeting>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 8
        return descriptor
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Picker("", selection: $tab) {
                Text(L("Now")).tag(Tab.now)
                Text(L("Recent")).tag(Tab.recent)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    switch tab {
                    case .now: nowTab
                    case .recent: recentTab
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 340)

            Divider()
            footer
        }
        .frame(width: 340)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 20, height: 20)
            Text(verbatim: "CK Parrot")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            MBHeaderIcon(symbol: hideFromShare ? "eye.slash" : "eye",
                       help: hideFromShare ? "Hidden from screen sharing" : "Visible in screen sharing") {
                hideFromShare.toggle()
            }
            MBHeaderIcon(symbol: "macwindow", help: "Open Parrot") { showMainWindow() }
            MBHeaderIcon(symbol: "chevron.left.forwardslash.chevron.right", help: "GitHub") {
                NSWorkspace.shared.open(Self.repoURL)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Now

    @ViewBuilder private var nowTab: some View {
        if let prompt = recordingManager.callWatcher.prompt {
            MBCard {
                HStack {
                    Text(prompt.kind == .start ? "Record \(prompt.appName) Call" : "Call Ended? Stop Recording")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Button(L("OK")) { recordingManager.callWatcher.acceptPrompt() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            }
        }

        if recordingManager.isRecording {
            recordingCard
        } else {
            idleCard
        }

        stats
    }

    private var recordingCard: some View {
        MBCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                    Text(L("Recording")).font(.system(size: 13, weight: .medium))
                    Spacer()
                    Text(recordingManager.formattedElapsedTime)
                        .font(.system(size: 13).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    Button { recordingManager.markMoment() } label: {
                        Label(L("Mark Moment"), systemImage: "bookmark")
                    }
                    .keyboardShortcut("m", modifiers: [.control, .option])
                    Button { recordingManager.toggleMute() } label: {
                        Label(L(recordingManager.isMuted ? "Unmute Me" : "Mute Me"),
                              systemImage: recordingManager.isMuted ? "mic.slash" : "mic")
                    }
                    .keyboardShortcut("m", modifiers: [.control, .option, .shift])
                }
                .controlSize(.small)
                .disabled(recordingManager.isStopping)

                let assistant = recordingManager.callAnalysisEngine
                if assistant.isSetUp {
                    Toggle(L("Assistant"), isOn: Binding(
                        get: { !assistant.isPaused },
                        set: { assistant.setPaused(!$0) }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .font(.system(size: 12))
                    .disabled(recordingManager.isStopping)
                }

                Button {
                    Task { await recordingManager.stopRecording() }
                } label: {
                    Text(L(recordingManager.isStopping ? "Finalizing…" : "Stop Recording"))
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .keyboardShortcut(".")
                .disabled(recordingManager.isStopping)
            }
        }
    }

    private var idleCard: some View {
        MBCard {
            VStack(alignment: .leading, spacing: 10) {
                nextCall
                Button { startRecording() } label: {
                    Label(L("Start Recording"), systemImage: "record.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut("r")
                .disabled(!recordingManager.transcriptionEngine.isReady)

                if !recordingManager.transcriptionEngine.isReady {
                    Text("Loading speech model…")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                if profiles.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(profiles) { profile in
                                let active = profile.id == profileStore.activeProfile?.id
                                Button(profile.name) { profileStore.setActive(profile) }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .tint(active ? .accentColor : nil)
                            }
                        }
                    }
                }

                Button {
                    showMainWindow { appSession.askRequest = AppSession.AskRequest(scope: nil, scopeTitle: nil) }
                } label: {
                    Label(L("Ask Parrot…"), systemImage: "text.magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.regular)
                .keyboardShortcut("k")
            }
        }
    }

    /// Today's next calendar call. Once it's about to start, one click
    /// opens its link and records it.
    @ViewBuilder private var nextCall: some View {
        if let next = recordingManager.callWatcher.nextCall {
            let name = next.event.title.isEmpty ? "" : " “\(Self.short(next.event.title))”"
            if next.joinable {
                Button(next.event.callLink == nil ? "Record\(name)" : "Join & Record\(name)") {
                    if let link = next.event.callLink { NSWorkspace.shared.open(link) }
                    Task { await recordingManager.startDetectedCall(appID: nil) }
                }
                .controlSize(.small)
            } else {
                Text("Next\(name) at \(next.event.start.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Everything Parrot has heard, one quiet line. Not read mid-call.
    @ViewBuilder private var stats: some View {
        if !recordingManager.isRecording {
            let meetings = (try? modelContext.fetch(FetchDescriptor<Meeting>())) ?? []
            if !meetings.isEmpty {
                let words = meetings.reduce(0) { $0 + DashboardView.words(in: $1) }
                    .formatted(.number.notation(.compactName))
                let calls = meetings.count == 1 ? String(localized: "1 call") : String(localized: "\(meetings.count) calls")
                Text("\(words) words heard in \(calls).")
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Recent

    @ViewBuilder private var recentTab: some View {
        if recent.isEmpty {
            Text(L("No calls yet."))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 120)
        } else {
            VStack(spacing: 0) {
                ForEach(recent) { meeting in
                    Button {
                        showMainWindow { appSession.pendingJump = AppSession.Jump(meetingID: meeting.id, time: nil) }
                    } label: {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(Self.short(meeting.title, limit: 40))
                                    .font(.system(size: 13, weight: .medium))
                                    .lineLimit(1)
                                Text(meeting.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(Duration.seconds(meeting.duration)
                                .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated, maximumUnitCount: 2)))
                                .font(.system(size: 11).monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if meeting.id != recent.last?.id { Divider() }
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            SettingsLink {
                Label(L("Settings…"), systemImage: "slider.horizontal.3")
            }
            Spacer()
            Button { NSApplication.shared.terminate(nil) } label: {
                Label(L("Quit Parrot"), systemImage: "power")
            }
            .keyboardShortcut("q")
        }
        .buttonStyle(.borderless)
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    // MARK: - Actions

    private func startRecording() {
        Task {
            do {
                try await recordingManager.preflightPermissionsAndStart(modelContext: modelContext)
            } catch {
                NSApp.activate(ignoringOtherApps: true)
                let alert = NSAlert()
                alert.messageText = String(localized: "Couldn't start recording")
                alert.informativeText = error.localizedDescription
                alert.runModal()
            }
        }
    }

    /// Brings the main window forward, reopening it if it was closed.
    private func showMainWindow(_ request: () -> Void = {}) {
        request()
        ParrotAppDelegate.showInDock()
        NSApp.activate(ignoringOtherApps: true)
        if let window = ParrotApp.mainWindow {
            window.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: ParrotApp.mainWindowID)
        }
    }

    private static func short(_ title: String, limit: Int = 32) -> String {
        title.count > limit ? title.prefix(limit - 1).trimmingCharacters(in: .whitespaces) + "…" : title
    }
}

/// A small monochrome icon button for the panel header.
private struct MBHeaderIcon: View {
    let symbol: String
    let help: LocalizedStringKey
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .regular))
                .frame(width: 26, height: 26)
                .background(RoundedRectangle(cornerRadius: 6).fill(hovering ? Color.primary.opacity(0.08) : .clear))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .help(help)
        .onHover { hovering = $0 }
    }
}

/// A quiet grouped surface: hairline border, no shadow.
private struct MBCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.035)))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.primary.opacity(0.08)))
    }
}

/// The menu-bar icon: the parrot, and while recording a dot, the call time
/// and a crossed-out mic when muted. Drawn into one template image, so the
/// bar shows exactly this layout and macOS tints it for light, dark and the
/// open menu.
struct MenuBarLabel: View {
    let recordingManager: RecordingManager

    var body: some View {
        let time = recordingManager.isRecording ? recordingManager.formattedElapsedTime : nil
        let muted = recordingManager.isRecording && recordingManager.isMuted
        Image(nsImage: Self.render(time: time, muted: muted))
            .accessibilityLabel(time.map { "Parrot, recording \($0)\(muted ? ", muted" : "")" } ?? "Parrot")
    }

    static func render(time: String?, muted: Bool) -> NSImage {
        let parrot = NSImage(named: "MenuBarIcon").map(Image.init(nsImage:)) ?? Image(systemName: "waveform")
        let content = HStack(spacing: Theme.Metrics.menuBarGap) {
            parrot
            if let time {
                Circle().frame(width: Theme.Metrics.menuBarDot, height: Theme.Metrics.menuBarDot)
                Text(time)
            }
            if muted { Image(systemName: "mic.slash.fill") }
        }
        .font(Theme.Typography.menuBarTime)
        .foregroundStyle(.black)   // only the shape counts: the image is a template
        let renderer = ImageRenderer(content: content)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        let image = renderer.nsImage ?? NSImage()
        image.isTemplate = true
        return image
    }
}
