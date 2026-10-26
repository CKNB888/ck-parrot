import Foundation

enum ProfilePresets {
    static let defaultProfileID = UUID(uuidString: "00000000-0000-0000-0000-0000000000D1")!
    private static let salesID    = UUID(uuidString: "00000000-0000-0000-0000-0000000000C1")!
    private static let coachingID = UUID(uuidString: "00000000-0000-0000-0000-0000000000C2")!
    private static let interviewID = UUID(uuidString: "00000000-0000-0000-0000-0000000000C3")!
    private static let supportID  = UUID(uuidString: "00000000-0000-0000-0000-0000000000C4")!
    private static let genericID  = UUID(uuidString: "00000000-0000-0000-0000-0000000000C5")!
    private static let vendorID   = UUID(uuidString: "00000000-0000-0000-0000-0000000000C6")!
    private static let investorID = UUID(uuidString: "00000000-0000-0000-0000-0000000000C7")!
    private static let classroomID = UUID(uuidString: "00000000-0000-0000-0000-0000000000C8")!
    // ck-parrot v2.1.1: built-in Chinese prompt library.
    private static let meetingZhID = UUID(uuidString: "00000000-0000-0000-0000-0000000000C9")!
    private static let interviewZhID = UUID(uuidString: "00000000-0000-0000-0000-0000000000CA")!
    private static let translateID = UUID(uuidString: "00000000-0000-0000-0000-0000000000CB")!
    private static let classScienceID = UUID(uuidString: "00000000-0000-0000-0000-0000000000CC")!
    private static let classLanguageID = UUID(uuidString: "00000000-0000-0000-0000-0000000000CD")!

    /// Bump when the built-in preset definitions change (persona, kinds, counterpart).
    /// `ProfileStore` refreshes built-in profiles whose stored version is older,
    /// so existing installs pick up improvements without wiping user-owned fields.
    /// v2: "Discovery gap" relabeled "Ask this next" — users didn't know what the
    /// grey card was for.
    /// v3: "Ask this next" recolored grey → warm gold; grey read as boring for a
    /// card that carries real value (and the parrot is colorful).
    /// v4: "Vendor call" preset added — the user is the customer (a bank,
    /// supplier or agency is pitching or onboarding them). Sales discovery cast
    /// the bank as "the prospect" on a real call.
    /// v5: Profiles 2.0. Built-ins get their own report templates (see
    /// `reportTemplate(for:)`) and the "Investor pitch" preset is added.
    /// v6: card and persona text users can read in Settings (no shouting
    /// capitals or em-dashes), the job-only rule on Interview's live Red flag,
    /// "You're talking" on Interview, Frustration cue its own color.
    /// v8 (ck-parrot 2.1.1): upstream presets' summary and persona in Chinese.
    /// v7 (ck-parrot 2.1.1): Chinese prompt library — 会议助手, 求职面试, 同声翻译, 课堂·理科, 课堂·语言.
    static let presetVersion = 8

    // The hex strings below are persisted in user data — never change them when
    // retheming the app. KindResolver.adaptiveColor maps each one to an adaptive
    // light/dark pair at render time.
    private static func kind(_ key: String, _ label: String, _ hex: String, _ icon: String,
                             _ trigger: String, pinned: Bool = false, priority: Int = 0) -> ProfileKind {
        ProfileKind(id: UUID(), key: key, label: label, colorHex: hex, iconSystemName: icon,
                    triggerDescription: trigger, isPinned: pinned, priority: priority)
    }
    private static func gauge(_ key: String, _ label: String, _ low: String, _ high: String, _ hex: String) -> SentimentGauge {
        SentimentGauge(id: UUID(), key: key, label: label, lowLabel: low, highLabel: high, colorHex: hex)
    }

    /// A fresh built-in follows its shipped report and is known across Macs
    /// by its preset id.
    private static func shipped(_ p: CallProfile) -> CallProfile {
        p.reportChoice = .preset
        p.sharedID = p.id
        p.sharedVersion = 1
        p.sharedSource = "builtin"
        return p
    }

    /// Default = today's exact behavior. persona/tone/fallback injected from migration.
    static func makeDefault(persona: String, tone: String, allowGeneralKnowledge: Bool) -> CallProfile {
        shipped(CallProfile(
            id: defaultProfileID, name: "Default", iconSystemName: "person.wave.2",
            summary: "适用于大多数通话，入门首选。",
            isBuiltIn: true, sortOrder: 0, persona: persona, tone: tone,
            counterpart: "the other person",
            allowGeneralKnowledge: allowGeneralKnowledge, presetVersion: presetVersion,
            kinds: [
                kind("suggestion", "Suggested answer", "4F6FB0", "text.bubble.fill", "The other person asked something or raised a topic. Draft a short, concrete line to say now."),
                kind("question", "Open question", "2F7E96", "questionmark.circle.fill", "The other person asked a direct question that hasn't been answered yet. Surface it briefly."),
                kind("blocker", "Blocker", "E8943A", "exclamationmark.triangle.fill", "An objection or obstacle came up (price, timing, decision maker, competitor) that isn't resolved.", pinned: true, priority: 10),
                kind("action_item", "Action item", "3F9168", "checkmark.circle.fill", "The user committed to do something after the call. Include any date or time mentioned."),
                kind("feedback", "Feedback", "5F6470", "chart.line.uptrend.xyaxis", "A brief read on how the call is going, only when something clearly shifts. Use sparingly."),
            ],
            gauges: [gauge("my_dominance", "You're talking", "Balanced", "Dominating", "5F6470")]
        ))
    }

    static func all() -> [CallProfile] {
        [
            makeDefault(persona: defaultPersona, tone: "", allowGeneralKnowledge: true),
            CallProfile(id: salesID, name: "Sales discovery", iconSystemName: "dollarsign.circle",
                summary: "销售沟通：挖掘需求、应对异议。",
                isBuiltIn: true, sortOrder: 1,
                persona: salesPersona,
                tone: "", counterpart: "the prospect", allowGeneralKnowledge: true,
                presetVersion: presetVersion,
                kinds: [
                    kind("suggestion", "Suggested answer", "4F6FB0", "text.bubble.fill", "The prospect asked something. Draft a short, concrete line to say now."),
                    kind("objection", "Objection", "E8943A", "hand.raised.fill", "The prospect raised a concern (price, timing, competitor, authority) that isn't resolved.", pinned: true, priority: 10),
                    kind("unanswered_question", "Unanswered question", "C0563B", "questionmark.bubble.fill", "The prospect asked a question and the conversation moved on without really answering it. Flag it so the user can circle back.", pinned: true, priority: 9),
                    kind("opportunity", "Opportunity", "7A5FB0", "scope", "The prospect revealed a pain, goal or need the user's offering could solve. Suggest how to position a solution, grounded in the user's documents when they cover it.", priority: 7),
                    kind("buying_signal", "Buying signal", "3F9168", "arrow.up.right.circle.fill", "The prospect showed interest or intent. Flag it so the user can move the deal forward."),
                    kind("next_step", "Next step", "2F7E96", "calendar.badge.plus", "A concrete next step or commitment to propose or confirm."),
                    kind("discovery_gap", "Ask this next", "C29218", "magnifyingglass", "An important unknown (budget, timeline, decision maker, success criteria) the user hasn't asked about yet. Phrase the title as the question to ask."),
                ],
                gauges: [gauge("buying_temperature", "Buying temp", "Cold", "Hot", "E8943A"),
                         gauge("my_dominance", "You're talking", "Balanced", "Dominating", "5F6470")]),
            CallProfile(id: coachingID, name: "1:1 coaching", iconSystemName: "heart.text.square",
                summary: "辅导与一对一：倾听、回应、提开放式问题。",
                isBuiltIn: true, sortOrder: 2,
                persona: "你是温和、不评判的辅导助手。帮我认真倾听、复述确认、提出开放式问题；所有输出用简体中文，结论在前。不要把对方当成异议或阻碍。",
                tone: "", counterpart: "the person", allowGeneralKnowledge: true,
                presetVersion: presetVersion,
                kinds: [
                    kind("reflection", "Reflection", "4F6FB0", "quote.bubble.fill", "Offer a brief reflective statement the user could mirror back to show understanding."),
                    kind("open_question", "Open question", "2F7E96", "questionmark.circle.fill", "A non-leading open question the user could ask to deepen the conversation."),
                    kind("emotional_cue", "Emotional cue", "E8943A", "waveform.path.ecg", "The person expressed a notable emotion (frustration, relief, worry) worth acknowledging.", pinned: false, priority: 5),
                    kind("commitment", "Commitment", "3F9168", "checkmark.circle.fill", "Either side committed to a concrete next step; include any timing."),
                    kind("coaching_moment", "Coaching moment", "5F6470", "text.bubble.fill", "An opening for the user to offer guidance or a useful reframe."),
                ],
                gauges: [gauge("client_openness", "Openness", "Guarded", "Open", "2F7E96"),
                         gauge("my_dominance", "You're talking", "Balanced", "Dominating", "5F6470")]),
            CallProfile(id: interviewID, name: "Interview", iconSystemName: "person.crop.rectangle.stack",
                summary: "我是面试官：评估候选人。",
                isBuiltIn: true, sortOrder: 3,
                persona: "你是面试官助手，帮我公平地评估候选人：提示可追问的问题、积极信号和风险点，帮我覆盖计划要问的内容。所有输出用简体中文，结论在前。",
                tone: "", counterpart: "the candidate", allowGeneralKnowledge: true,
                presetVersion: presetVersion,
                kinds: [
                    kind("follow_up_question", "Follow-up", "2F7E96", "questionmark.circle.fill", "A sharp follow-up question to probe the candidate's last answer."),
                    kind("red_flag", "Red flag", "E8943A", "flag.fill", "Something concerning about the candidate's fit for the job, from what they said. Only job-related points, never age, looks, accent or other personal traits.", pinned: true, priority: 10),
                    kind("strong_signal", "Strong signal", "3F9168", "star.fill", "A strong positive signal worth recording."),
                    kind("topic_to_cover", "Topic to cover", "4F6FB0", "list.bullet", "A planned topic the user hasn't covered yet."),
                    kind("note", "Note", "5F6470", "note.text", "A neutral observation worth capturing."),
                ],
                gauges: [gauge("candidate_confidence", "Confidence", "Hesitant", "Confident", "3F9168"),
                         gauge("my_dominance", "You're talking", "Balanced", "Dominating", "5F6470")]),
            CallProfile(id: supportID, name: "Customer support", iconSystemName: "lifepreserver",
                summary: "客户支持：解决问题，安抚情绪。",
                isBuiltIn: true, sortOrder: 4,
                persona: "你是冷静、可靠的客户支持助手。帮我把客户的问题讲清楚、解决掉，并让客户安心。所有输出用简体中文，结论在前。",
                tone: "", counterpart: "the customer", allowGeneralKnowledge: true,
                presetVersion: presetVersion,
                kinds: [
                    kind("answer", "Answer", "4F6FB0", "text.bubble.fill", "The customer asked something. Draft a clear, accurate answer the user can give."),
                    kind("unresolved_issue", "Unresolved issue", "E8943A", "exclamationmark.triangle.fill", "An issue the customer raised that isn't resolved yet.", pinned: true, priority: 10),
                    kind("frustration_cue", "Frustration cue", "C0563B", "waveform.path.ecg", "The customer is getting frustrated. Flag it so the user can calm things down."),
                    kind("follow_up", "Follow-up", "3F9168", "arrow.uturn.right", "A follow-up action the user should take or promise."),
                    kind("note", "Note", "5F6470", "note.text", "A neutral observation worth capturing."),
                ],
                gauges: [gauge("customer_frustration", "Frustration", "Calm", "Upset", "E8943A")]),
            CallProfile(id: genericID, name: "Generic", iconSystemName: "bubble.left.and.bubble.right",
                summary: "卡片更少，不对通话做任何预设。",
                isBuiltIn: true, sortOrder: 5,
                persona: "你是中立的会议助手。给出有用的建议、未解决的问题和待办，不预设通话目的。所有输出用简体中文，结论在前。",
                tone: "", counterpart: "the other person", allowGeneralKnowledge: true,
                presetVersion: presetVersion,
                kinds: [
                    kind("suggestion", "Suggestion", "4F6FB0", "text.bubble.fill", "A useful thing the user could say in response to the recent conversation."),
                    kind("question", "Open question", "2F7E96", "questionmark.circle.fill", "A direct question the other person asked that hasn't been answered."),
                    kind("action_item", "Action item", "3F9168", "checkmark.circle.fill", "Something the user committed to. Include any timing."),
                    kind("note", "Note", "5F6470", "note.text", "A neutral observation worth capturing."),
                ],
                gauges: [gauge("engagement", "Engagement", "Flat", "Engaged", "2F7E96")]),
            CallProfile(id: vendorID, name: "Vendor call", iconSystemName: "building.columns",
                summary: "我是客户：银行或供应商向我介绍服务。",
                isBuiltIn: true, sortOrder: 6,
                persona: vendorPersona,
                tone: "", counterpart: "the vendor", allowGeneralKnowledge: true,
                presetVersion: presetVersion,
                kinds: [
                    kind("their_commitment", "Their commitment", "3F9168", "checkmark.seal.fill", "The vendor promised something concrete: a timeline, a feature, a fee, a follow-up, a document. Capture it exactly as said."),
                    kind("my_open_question", "My open question", "C0563B", "questionmark.bubble.fill", "You asked the vendor something and did not get a clear answer, or the vendor moved on. Flag it so you can circle back; the reply is how to ask it again.", pinned: true, priority: 10),
                    kind("red_flag", "Red flag", "E8943A", "exclamationmark.triangle.fill", "A limitation, risk, fee, hold, exclusion, lock-in or condition the vendor mentioned that could hurt you. Quote the condition.", pinned: true, priority: 9),
                    kind("pricing_detail", "Pricing detail", "4F6FB0", "tag.fill", "A number the vendor stated: fee, rate, settlement time, limit, minimum, timeline. Record it so it is not lost."),
                    kind("ask_this", "Ask this", "C29218", "magnifyingglass", "An important thing you have not asked this vendor yet: pricing, timelines, support, exit terms, compliance steps. Phrase the title as the question.", priority: 7),
                    kind("next_step", "Next step", "2F7E96", "calendar.badge.plus", "A concrete action either side agreed to; say who and when."),
                ],
                gauges: [gauge("fit", "Fit", "Poor", "Strong", "3F9168"),
                         gauge("my_dominance", "You're talking", "Balanced", "Dominating", "5F6470")]),
            CallProfile(id: investorID, name: "Investor pitch", iconSystemName: "chart.line.uptrend.xyaxis",
                summary: "向风投和天使投资人路演。",
                isBuiltIn: true, sortOrder: 7,
                persona: investorPersona,
                tone: "", counterpart: "the investor", allowGeneralKnowledge: true,
                presetVersion: presetVersion,
                kinds: [
                    kind("suggestion", "Suggested answer", "4F6FB0", "text.bubble.fill", "The investor asked something. Draft a short, confident answer the user can give now, with a number when one is known."),
                    kind("objection", "Objection", "E8943A", "hand.raised.fill", "The investor pushed back on market size, team, traction, competition or terms, and it isn't resolved.", pinned: true, priority: 10),
                    kind("unanswered_question", "Unanswered question", "C0563B", "questionmark.bubble.fill", "The investor asked a question and the conversation moved on without a real answer. Flag it so the user can come back to it.", pinned: true, priority: 9),
                    kind("interest_signal", "Interest signal", "3F9168", "arrow.up.right.circle.fill", "The investor showed interest: asked about terms, a next meeting, partners or diligence."),
                    kind("their_ask", "They asked for", "2F7E96", "tray.and.arrow.down.fill", "The investor asked for data, a deck, metrics or an intro. Capture exactly what, so it gets sent."),
                    kind("ask_this", "Ask this", "C29218", "magnifyingglass", "Something the user should learn about this investor: check size, stage, lead or follow, timeline, conflicts. Phrase the title as the question.", priority: 7),
                ],
                gauges: [gauge("interest", "Interest", "Cold", "Leaning in", "3F9168"),
                         gauge("my_dominance", "You're talking", "Balanced", "Dominating", "5F6470")]),
            CallProfile(id: classroomID, name: "课堂答疑", iconSystemName: "graduationcap",
                summary: "老师上课时：学生提问，先给结论再给要点。",
                isBuiltIn: true, sortOrder: 8,
                persona: classroomPersona,
                tone: "", counterpart: "the students", allowGeneralKnowledge: true,
                presetVersion: presetVersion,
                kinds: [
                    kind("answer", "答案", "4F6FB0", "text.bubble.fill", "A student asked a question. Title = the one-sentence conclusion in Simplified Chinese; body = at most 3 short key points or steps the teacher can say aloud, formulas in plain notation.", pinned: true, priority: 10),
                    kind("misconception", "易错点", "E8943A", "exclamationmark.triangle.fill", "A student's question or answer shows a common mistake. Title names the mistake; body gives the correct idea in one sentence.", priority: 8),
                    kind("unanswered_question", "待回答", "C0563B", "questionmark.bubble.fill", "A student asked something and the lesson moved on without answering it. Flag it so the teacher can come back to it.", pinned: true, priority: 9),
                    kind("follow_up", "追问建议", "2F7E96", "questionmark.circle.fill", "A short check-for-understanding question the teacher could ask the class next."),
                    kind("note", "课堂记录", "5F6470", "note.text", "A key point, assignment or announcement worth recording for the lesson summary."),
                ],
                gauges: [gauge("my_dominance", "You're talking", "Balanced", "Dominating", "5F6470")]),
            CallProfile(id: meetingZhID, name: "会议助手", iconSystemName: "person.3",
                summary: "开会时：有人问我就给可直接说的回答，并记下决定和待办。",
                isBuiltIn: true, sortOrder: 9, persona: meetingZhPersona,
                tone: "", counterpart: "the other participants", allowGeneralKnowledge: true,
                presetVersion: presetVersion,
                kinds: [
                    kind("suggestion", "建议回答", "4F6FB0", "text.bubble.fill", "Someone asked the user a question. Title = a one-sentence answer in Simplified Chinese the user can say now; body = at most 2 short supporting points.", pinned: true, priority: 10),
                    kind("decision", "决定", "3F9168", "checkmark.seal.fill", "The group decided something. Title states the decision in one sentence.", priority: 8),
                    kind("action_item", "待办", "C29218", "checkmark.circle.fill", "Someone committed to do something. Title = who does what; include any date mentioned.", pinned: true, priority: 9),
                    kind("question", "待确认", "C0563B", "questionmark.bubble.fill", "A question was raised and left unanswered. Flag it briefly."),
                ],
                gauges: [gauge("my_dominance", "You're talking", "Balanced", "Dominating", "5F6470")]),
            CallProfile(id: interviewZhID, name: "求职面试", iconSystemName: "person.text.rectangle",
                summary: "我是求职者：面试官提问时给出第一人称、可照着说的回答。",
                isBuiltIn: true, sortOrder: 10, persona: interviewZhPersona,
                tone: "", counterpart: "the interviewer", allowGeneralKnowledge: true,
                presetVersion: presetVersion,
                kinds: [
                    kind("answer", "参考回答", "4F6FB0", "text.bubble.fill", "The interviewer asked a question. Title = the one-sentence core answer in first person, Simplified Chinese; body = 2-3 short points grounded in the user's notes. Never invent experience.", pinned: true, priority: 10),
                    kind("clarify", "可以反问", "2F7E96", "questionmark.circle.fill", "A short clarifying or closing question the user could ask the interviewer."),
                    kind("caution", "注意", "E8943A", "exclamationmark.triangle.fill", "The user's answer rambled, contradicted their notes, or missed the question. One sentence on how to fix it.", priority: 7),
                ],
                gauges: [gauge("my_dominance", "You're talking", "Balanced", "Dominating", "5F6470")]),
            CallProfile(id: translateID, name: "同声翻译", iconSystemName: "character.bubble",
                summary: "外语会议：把对方说的话实时译成中文，我的中文译成对方语言。",
                isBuiltIn: true, sortOrder: 11, persona: translatePersona,
                tone: "", counterpart: "the other person", allowGeneralKnowledge: false,
                presetVersion: presetVersion,
                kinds: [
                    kind("translation", "译文", "4F6FB0", "character.bubble.fill", "The other person said something in a foreign language. Title = the faithful Simplified Chinese translation of the key sentence; body = the rest, translated, keeping names and numbers.", pinned: true, priority: 10),
                    kind("reply", "用对方语言回复", "3F9168", "arrowshape.turn.up.left.fill", "The user should reply. Title = a short reply in the other person's language; body = its Chinese meaning."),
                ],
                gauges: [gauge("my_dominance", "You're talking", "Balanced", "Dominating", "5F6470")]),
            CallProfile(id: classScienceID, name: "课堂答疑·理科", iconSystemName: "function",
                summary: "数学 / 物理 / 化学 / 编程课：结论 + 依据 + 步骤。",
                isBuiltIn: true, sortOrder: 12, persona: classSciencePersona,
                tone: "", counterpart: "the students", allowGeneralKnowledge: true,
                presetVersion: presetVersion,
                kinds: [
                    kind("answer", "答案", "4F6FB0", "text.bubble.fill", "A student asked a question. Title = the result (with units) or conclusion in Simplified Chinese; body = the law/formula used, then numbered steps, one line each.", pinned: true, priority: 10),
                    kind("misconception", "易错点", "E8943A", "exclamationmark.triangle.fill", "A common mistake shown or likely here. Title names it; body gives the fix in one sentence.", priority: 8),
                    kind("unanswered_question", "待回答", "C0563B", "questionmark.bubble.fill", "A student question the lesson moved past without answering.", pinned: true, priority: 9),
                ],
                gauges: [gauge("my_dominance", "You're talking", "Balanced", "Dominating", "5F6470")]),
            CallProfile(id: classLanguageID, name: "课堂答疑·语言", iconSystemName: "textformat.abc",
                summary: "语文 / 英语课：答案要点 + 规则 + 例句。",
                isBuiltIn: true, sortOrder: 13, persona: classLanguagePersona,
                tone: "", counterpart: "the students", allowGeneralKnowledge: true,
                presetVersion: presetVersion,
                kinds: [
                    kind("answer", "答案", "4F6FB0", "text.bubble.fill", "A student asked a question. Title = the answer in one sentence; body = the rule in Chinese and one correct example (English examples stay in English).", pinned: true, priority: 10),
                    kind("misconception", "易错点", "E8943A", "exclamationmark.triangle.fill", "A typical error: title names it, body shows wrong vs right in one line each.", priority: 8),
                    kind("unanswered_question", "待回答", "C0563B", "questionmark.bubble.fill", "A student question the lesson moved past without answering.", pinned: true, priority: 9),
                ],
                gauges: [gauge("my_dominance", "You're talking", "Balanced", "Dominating", "5F6470")]),
        ].map(shipped)
    }

    private static let meetingZhPersona = """
    你是我的会议助手，参会者发言来自转写（可能有错字，按上下文理解）。所有输出用简体中文，结论放最前面。\
    有人向我提问时，给出专业、简洁、可直接说出口的回答（不超过 60 字）；只记录真正的决定和待办，不编造，不寒暄。
    """
    private static let interviewZhPersona = """
    你是我的求职面试助手，我是求职者，面试官的话来自转写。用第一人称、口语化的简体中文给出我可以照着说的回答：\
    先一句话核心回答，再 2-3 个要点，必须来自我的笔记或简历里的真实经历，绝不编造。技术题先说思路和复杂度。不要回答我自己说的话。
    """
    private static let translatePersona = """
    你是同声翻译。对方说外语时，把意思忠实、简短地译成简体中文；需要我回应时，用对方的语言给出一句简短回复并附中文意思。\
    保留人名、数字和专有名词，不解释、不评论、不添加原话没有的内容。
    """
    private static let classSciencePersona = """
    你是老师的理科课堂答疑助手（数学、物理、化学、编程），学生提问来自转写。所有输出用简体中文，标题就是结果或结论，\
    物理量带单位。正文先写「依据：」所用定律或公式，再分步列式，每步一行；化学方程式要配平并注明条件；编程给最短可运行代码。\
    最多 4 行，不寒暄、不复述问题、不回答老师自己说的话。
    """
    private static let classLanguagePersona = """
    你是老师的语文、英语课堂答疑助手，学生提问来自转写。标题是一句话答案；正文用中文讲规则或赏析要点\
    （赏析按「手法、内容、效果」），英语例句保持英文并给出正确例句，最多 3 行。引用原文要准确，不编造。
    """

    private static let classroomPersona = """
    你是老师的课堂答疑助手，老师正在上课，学生的提问来自转写（可能有错字，请按上下文理解）。\
    所有输出用简体中文。每张卡片：标题就是一句话结论（最重要的信息放最前面）；正文最多 3 个要点或步骤，每条一句，\
    关键术语或数值放在要点开头；不寒暄、不复述问题、不编造。按学科作答：数学物理先列依据再给步骤和带单位的结果，\
    化学方程式要配平并注明条件，编程给最短可运行代码，英语规则用中文讲、例句用英文。不要回答老师自己说的话。
    """

    // MARK: - Report templates

    private static func section(_ key: String, _ title: String, _ type: String, _ guide: String,
                                commitments: Bool = false) -> ReportTemplate.Section {
        ReportTemplate.Section(key: key, title: title, type: type, guide: guide,
                               commitments: commitments ? true : nil)
    }

    private static func scorecard(_ key: String, _ title: String, _ guide: String,
                                  _ criteria: [(String, String, String)]) -> ReportTemplate.Section {
        ReportTemplate.Section(key: key, title: title, type: "scorecard", guide: guide,
                               criteria: criteria.map { .init(key: $0.0, label: $0.1, guide: $0.2) })
    }

    private static func coach(_ role: String, _ focus: String) -> ReportTemplate.Coaching {
        ReportTemplate.Coaching(enabled: true, role: role, focus: focus)
    }

    /// The report each built-in ships with. Default and Generic keep the
    /// standard report. Kept short on purpose: every template here was
    /// checked on the default local model (see `--analyze-test` report mode).
    static let reportTemplates: [UUID: ReportTemplate] = [
        defaultProfileID: .standard,
        genericID: .standard,
        salesID: ReportTemplate(sections: [
            section("overview", "Overview", "prose", "2-3 sentences: what the call was about and where the deal stands."),
            section("pain", "Pain points", "bullets", "What the prospect is struggling with and why it matters to them."),
            section("budget", "Budget", "bullets", "What they said about budget, price or what they spend today."),
            section("decision", "Decision-maker", "bullets", "Who decides, who else is involved, and how they buy."),
            section("timeline", "Timeline", "bullets", "When they want to decide or start, and why then."),
            section("objections", "Objections", "bullets", "Concerns they raised, and whether each one was answered."),
            section("next", "Next steps", "bullets", "What someone said they'd do, with any date.", commitments: true),
        ], coaching: coach("sales coach", "Discovery: pain, budget, decision-maker and timeline. How objections were handled.")),
        interviewID: ReportTemplate(sections: [
            section("overview", "Overview", "prose", "2-3 sentences: the role, how the conversation went, and anything decided."),
            scorecard("scorecard", "Scorecard", "Only what the candidate said on this call.", [
                ("experience", "Relevant experience", "Has done similar work, with real examples"),
                ("problems", "Problem solving", "How they work through a problem"),
                ("communication", "Communication", "Explains clearly and answers the question asked"),
                ("teamwork", "Teamwork", "How they work with others and handle disagreement"),
            ]),
            section("strengths", "Strengths", "bullets", "Things the candidate showed they can do, with the moment it came up."),
            section("concerns", "Concerns", "bullets", "Gaps or doubts from what the candidate said. Only job-related points, never age, looks, accent or other personal traits."),
            section("uncovered", "Still to cover", "bullets", "Planned topics or questions that didn't come up."),
            section("next", "Next steps", "bullets", "What someone said they'd do, with any date.", commitments: true),
        ], coaching: coach("interview coach", "Question quality, fairness, and giving the candidate room to talk.")),
        supportID: ReportTemplate(sections: [
            section("issue", "Issue", "prose", "1-2 sentences: what the customer needed help with."),
            section("cause", "Cause", "bullets", "What caused the problem, if it came up."),
            section("resolved", "Resolved", "bullets", "What was fixed or answered on the call."),
            section("followups", "Follow-ups", "bullets", "What someone promised to do after the call, with any date.", commitments: true),
            section("mood", "Mood", "prose", "One line: how the customer felt at the start and at the end."),
        ], coaching: coach("support coach", "Clarity, empathy, and whether the issue was really solved.")),
        coachingID: ReportTemplate(sections: [
            // Starts with a paragraph like the others: bullets-only came back
            // ragged on gemma3:4b ("Wins - …", no colons) in two runs.
            section("overview", "Overview", "prose", "1-2 sentences: how the person is doing and what you talked about."),
            section("wins", "Wins", "bullets", "Progress or good news the person shared."),
            section("blockers", "Blockers", "bullets", "What is in their way or worrying them."),
            section("commitments", "Commitments", "bullets", "What either of you said you'd do, with any date.", commitments: true),
        ], coaching: coach("listening coach", "Listening, open questions, and letting the person lead.")),
        vendorID: ReportTemplate(sections: [
            section("offer", "Offer", "prose", "2-3 sentences: what the vendor offered and how the call ended."),
            section("pricing", "Pricing and terms", "bullets", "Every fee, rate, limit and timeline the vendor stated, word for word."),
            section("redflags", "Red flags", "bullets", "Risks, holds, exclusions, lock-in or conditions that could hurt you."),
            section("open", "Open questions", "bullets", "What you asked that wasn't answered clearly."),
            section("commitments", "Commitments", "bullets", "What either side said they'd do or send, with any date.", commitments: true),
        ], coaching: coach("negotiation coach", "Getting clear answers, firm numbers and promises in writing.")),
        investorID: ReportTemplate(sections: [
            section("overview", "Overview", "prose", "2-3 sentences: what the call was about and how it ended."),
            section("liked", "What they liked", "bullets", "Parts of the pitch the investor responded well to."),
            section("concerns", "Their concerns", "bullets", "Doubts about market, team, traction or terms."),
            section("asks", "What they asked for", "bullets", "Data, metrics or intros they requested."),
            scorecard("fit", "Fit", "How well this investor fits your round.", [
                ("stage", "Stage fit", "Do they invest at your stage?"),
                ("check", "Check size", "Does their usual check match your round?"),
            ]),
            section("next", "Next steps", "bullets", "What someone said they'd do, with any date.", commitments: true),
        ], coaching: coach("pitch coach", "Clarity of the story, handling tough questions, the ask.")),
        classroomID: ReportTemplate(sections: [
            section("overview", "课堂概要", "prose", "1-2 sentences in Simplified Chinese: what the lesson covered and how the class went."),
            section("questions", "学生提问", "bullets", "Each question a student asked, with the one-sentence answer given (or 未回答)."),
            section("misconceptions", "易错点", "bullets", "Common mistakes or confusions students showed, each with the correct idea."),
            section("followups", "课后跟进", "bullets", "Questions still open, homework or anything the teacher said they'd do, with any date.", commitments: true),
        ], coaching: coach("teaching coach", "Clear answers, checking understanding, and giving students time to ask.")),
        meetingZhID: ReportTemplate(sections: [
            section("overview", "会议结论", "prose", "1-2 sentences in Simplified Chinese: what the meeting was about and what was concluded."),
            section("decisions", "决定事项", "bullets", "Each decision made, one line each."),
            section("actions", "待办（负责人｜截止时间）", "bullets", "Who will do what, with any date.", commitments: true),
            section("open", "待确认问题", "bullets", "Questions raised but not settled."),
        ], coaching: coach("meeting coach", "Clear answers, staying on topic, and leaving with owners and dates.")),
        interviewZhID: ReportTemplate(sections: [
            section("overview", "面试概要", "prose", "1-2 sentences in Simplified Chinese: the role and how the interview went."),
            section("questions", "被问到的问题", "bullets", "Each question the interviewer asked, with a one-line note on how the user answered."),
            section("improve", "可以更好", "bullets", "Answers that could be stronger, each with a better one-sentence version."),
            section("next", "后续", "bullets", "Next steps or anything someone promised, with any date.", commitments: true),
        ], coaching: coach("interview coach", "Answering the question asked, concrete examples, and concise delivery.")),
        translateID: .standard,
        classScienceID: ReportTemplate(sections: [
            section("overview", "课堂概要", "prose", "1-2 sentences in Simplified Chinese: what the lesson covered."),
            section("questions", "学生提问", "bullets", "Each student question with the one-sentence answer given (or 未回答)."),
            section("misconceptions", "易错点", "bullets", "Common mistakes students showed, each with the correct idea."),
            section("followups", "课后跟进", "bullets", "Open questions or homework, with any date.", commitments: true),
        ], coaching: coach("teaching coach", "Clear steps, checking understanding, and giving students time to ask.")),
        classLanguageID: ReportTemplate(sections: [
            section("overview", "课堂概要", "prose", "1-2 sentences in Simplified Chinese: what the lesson covered."),
            section("questions", "学生提问", "bullets", "Each student question with the one-sentence answer given (or 未回答)."),
            section("misconceptions", "易错点", "bullets", "Typical errors students made, each with the right form."),
            section("followups", "课后跟进", "bullets", "Open questions or homework, with any date.", commitments: true),
        ], coaching: coach("teaching coach", "Clear explanations, good examples, and giving students time to ask.")),
    ]

    /// The built-in reports a profile can start from, by profile name.
    static let reportStarters: [(name: String, template: ReportTemplate)] =
        all().filter { !$0.reportTemplate.isStandard }.map { ($0.name, $0.reportTemplate) }

    /// A built-in's shipped report, nil for anything that isn't a built-in.
    static func reportTemplate(for id: UUID) -> ReportTemplate? { reportTemplates[id] }

    /// The framing scaffold the Default profile uses (mirrors today's hardcoded prompt intent).
    private static let defaultPersona = "你是实时通话助手。所有输出用简体中文，结论在前：给出我可以直接说的简短回答，提示阻碍，记下对方的承诺。"

    /// Vendor call persona — the user is buying, and the copilot protects their side.
    private static let vendorPersona = """
    这通电话里我是客户：银行、支付机构、供应商或代理商在介绍服务、回答问题或为我办理开通。我不是在推销，\
    对方也不是潜在客户。维护我的利益：原样记下对方承诺的内容和费用，提示风险、冻结、免责条款和没答清的问题，\
    并建议下一句该问什么。对方说的数字一字不改。所有输出用简体中文，结论在前。
    """

    /// Investor pitch persona — the user is the founder asking for money.
    private static let investorPersona = """
    你在实时辅导一位正在向投资人（风投或天使）路演的创始人。帮创始人用数字干脆地回答，面对质疑不防御，\
    抓住投资人真正关心的点，并确保通话以明确的下一步结束。每张卡片都要在 30 秒内用得上。所有输出用简体中文，结论在前。
    """

    /// Sales discovery persona — a real-time coach, not just a suggestion engine.
    private static let salesPersona = """
    你是嵌在实时销售沟通里的资深 B2B 销售教练，实时辅导我。重在判断客户资质而不是推销：帮我挖出痛点、预算、\
    决策人和时间表。不只是给台词，要辅导：我说得太多、错过购买信号、没回答客户的问题、没追问客户提到的痛点时直接指出。\
    每张卡片都要在 30 秒内用得上。所有输出用简体中文，结论在前。
    """
}
