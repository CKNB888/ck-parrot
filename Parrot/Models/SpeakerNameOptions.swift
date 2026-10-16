import Foundation

/// One name the "Who is this?" popover offers for a voice.
struct SpeakerNameOption: Hashable {
    enum Group: CaseIterable { case thisCall, invite, past }
    /// What gets saved as the voice's name.
    var name: String
    /// An invitee's email: the filter matches it.
    var email: String? = nil
    /// Two invitees share this name, so the popover shows the email under it.
    var showsEmail = false
    var group: Group
}

/// The names the naming popover offers (#142): names other voices in this
/// call already have (picking one joins the two voices, see
/// `Meeting.mergeSameNamedSpeakers`), everyone on the invite, then names from
/// past calls and remembered voices. Pure, so ProfileTest checks it; the
/// popover only lays it out.
enum SpeakerNameOptions {
    /// Same name = same person, compared trimmed and in any case. The merge
    /// uses this key too, so the list never shows two spellings of one person.
    static func key(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Labels Parrot made up, never a person's name.
    static func isPlaceholder(_ name: String) -> Bool {
        let k = key(name)
        return k.isEmpty || k == "me" || k == "them"
            || k.range(of: #"^speaker \d+$"#, options: .regularExpression) != nil
    }

    /// The name an invitee is saved under. Each name is one person, so two
    /// invitees who would get the same name are saved apart: "John (jpark)",
    /// or "John (acme.com)" when the email starts with the name itself. It
    /// shows in every transcript line, so not the whole email. No email, no
    /// way to tell them apart: the plain name.
    // ponytail: same name + same email start at two companies still clash; add the domain if that ever shows up.
    static func savedName(for attendee: Attendee, clashes: Bool) -> String {
        let name = attendee.displayName
        guard clashes, let email = attendee.email, let at = email.firstIndex(of: "@") else { return name }
        let start = String(email[..<at]), domain = String(email[email.index(after: at)...])
        let tag = key(start) == key(name) ? domain : start
        return tag.isEmpty ? name : "\(name) (\(tag))"
    }

    /// Every option for `label`, grouped and in order, each name once. The
    /// voice's own name is left out. `filter` matches names and emails,
    /// ignoring case and accents.
    static func build(label: String, speakerNames: [String: String], attendees: [Attendee],
                      pastNames: [String], filter: String = "") -> [SpeakerNameOption] {
        var seen = Set<String>()
        if let own = speakerNames[label] { seen.insert(key(own)) }
        var options: [SpeakerNameOption] = []
        func add(_ option: SpeakerNameOption) {
            guard !isPlaceholder(option.name), seen.insert(key(option.name)).inserted else { return }
            options.append(option)
        }

        let others = speakerNames.filter { $0.key != "Me" && $0.key != label }
            .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
        for (_, name) in others {
            add(.init(name: name.trimmingCharacters(in: .whitespacesAndNewlines), group: .thisCall))
        }

        let counts = Dictionary(grouping: attendees) { key($0.displayName) }.mapValues(\.count)
        for attendee in attendees {
            let clashes = counts[key(attendee.displayName), default: 0] > 1
            add(.init(name: savedName(for: attendee, clashes: clashes), email: attendee.email,
                      showsEmail: clashes && attendee.email != nil, group: .invite))
        }

        for name in pastNames {
            add(.init(name: name.trimmingCharacters(in: .whitespacesAndNewlines), group: .past))
        }

        let wanted = fold(filter)
        guard !wanted.isEmpty else { return options }
        return options.filter { fold($0.name).contains(wanted) || fold($0.email ?? "").contains(wanted) }
    }

    /// What Return saves: an offered name typed in another case comes back
    /// in its own spelling, so "mary" joins the existing "Mary".
    static func resolve(_ typed: String, among options: [SpeakerNameOption]) -> String {
        let typed = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        return options.first { key($0.name) == key(typed) }?.name ?? typed
    }

    /// Latin-ASCII first: some letters have no accent to strip, so "yilmaz"
    /// would never find "Yılmaz" (ı), nor "lodz" "Łódź" (ł).
    private static func fold(_ s: String) -> String {
        let s = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return (s.applyingTransform(StringTransform("Latin-ASCII"), reverse: false) ?? s)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}
