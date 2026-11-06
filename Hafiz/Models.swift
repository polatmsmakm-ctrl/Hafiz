import Foundation
import SwiftUI
import UserNotifications

enum Theme {
    static let green = Color(red: 0.12, green: 0.43, blue: 0.36)
    static let gold = Color(red: 0.80, green: 0.62, blue: 0.20)
    static let paper = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let ink = Color(red: 0.12, green: 0.14, blue: 0.13)
}

struct MemoItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var text: String
    var kind: Kind
    var level: Int = 0
    var nextReview: Date = Date()
    var reviews: Int = 0
    var created: Date = Date()

    enum Kind: String, Codable, CaseIterable {
        case surah, poem, text

        var label: String {
            switch self {
            case .surah: return "آيات"
            case .poem: return "شعر"
            case .text: return "نص"
            }
        }

        var icon: String {
            switch self {
            case .surah: return "book.closed"
            case .poem: return "text.quote"
            case .text: return "doc.text"
            }
        }
    }

    static let fractions: [Double] = [0.0, 0.25, 0.5, 0.75, 1.0, 1.0]
    static let intervals: [Int] = [0, 1, 2, 5, 10, 30]
    static let levelNames: [String] = [
        "جديد: اقرأ وردّد النص",
        "المستوى ١: ربع الكلمات مخفية",
        "المستوى ٢: نصف الكلمات مخفية",
        "المستوى ٣: ثلاثة أرباع الكلمات مخفية",
        "المستوى ٤: كل الكلمات مخفية",
        "متقن: مراجعة كل ٣٠ يوماً"
    ]

    var words: [String] {
        text.split(whereSeparator: { $0.isWhitespace }).map { String($0) }
    }

    var hiddenFraction: Double {
        MemoItem.fractions[min(max(level, 0), 5)]
    }

    var isDue: Bool { nextReview <= Date() }
    var levelName: String { MemoItem.levelNames[min(max(level, 0), 5)] }
}

struct Persisted: Codable {
    var items: [MemoItem] = []
    var days: [String] = []
}

final class Store: ObservableObject {
    @Published var items: [MemoItem] = []
    @Published var days: Set<String> = []

    private let url: URL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("hafiz.json")

    init() { load() }

    static func key(_ d: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }

    var dueItems: [MemoItem] {
        items.filter { $0.isDue }.sorted { $0.nextReview < $1.nextReview }
    }

    var masteredCount: Int { items.filter { $0.level >= 5 }.count }

    var streak: Int {
        let cal = Calendar(identifier: .gregorian)
        var d = Date()
        if !days.contains(Store.key(d)) {
            d = cal.date(byAdding: .day, value: -1, to: d) ?? d
        }
        var n = 0
        while days.contains(Store.key(d)) {
            n += 1
            d = cal.date(byAdding: .day, value: -1, to: d) ?? d
        }
        return n
    }

    func add(_ item: MemoItem) {
        items.insert(item, at: 0)
        save()
    }

    func update(_ item: MemoItem) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[i] = item
        save()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    func markToday() {
        days.insert(Store.key(Date()))
        save()
    }

    func grade(_ id: UUID, good: Bool) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        var it = items[i]
        it.reviews += 1
        let cal = Calendar.current
        if good {
            it.level = min(it.level + 1, 5)
            let day = cal.date(byAdding: .day, value: MemoItem.intervals[it.level], to: Date()) ?? Date()
            it.nextReview = cal.startOfDay(for: day)
        } else {
            it.level = max(it.level - 1, 1)
            it.nextReview = Date().addingTimeInterval(6 * 3600)
        }
        items[i] = it
        days.insert(Store.key(Date()))
        save()
    }

    private func save() {
        let p = Persisted(items: items, days: Array(days))
        if let data = try? JSONEncoder().encode(p) {
            try? data.write(to: url, options: .atomic)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: url),
              let p = try? JSONDecoder().decode(Persisted.self, from: data) else { return }
        items = p.items
        days = Set(p.days)
    }
}

enum Reminder {
    static let identifier = "hafiz.daily"

    static func schedule(hour: Int, minute: Int) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return false }
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        let content = UNMutableNotificationContent()
        content.title = "حافظ"
        content.body = "حان وقت مراجعة محفوظاتك 📖"
        content.sound = .default
        var dc = DateComponents()
        dc.hour = hour
        dc.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
        return true
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

func relativeText(_ d: Date) -> String {
    let f = RelativeDateTimeFormatter()
    f.locale = Locale(identifier: "ar")
    f.unitsStyle = .full
    return f.localizedString(for: d, relativeTo: Date())
}

func arabicNumber(_ n: Int) -> String {
    let f = NumberFormatter()
    f.locale = Locale(identifier: "ar")
    return f.string(from: NSNumber(value: n)) ?? "\(n)"
}
