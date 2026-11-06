import SwiftUI

struct Surah: Codable, Identifiable {
    let number: Int
    let name: String
    let numberOfAyahs: Int
    var id: Int { number }
}

struct SurahListResponse: Codable {
    let data: [Surah]
}

struct Ayah: Codable {
    let numberInSurah: Int
    let text: String
}

struct SurahDetail: Codable {
    let number: Int
    let name: String
    let numberOfAyahs: Int
    let ayahs: [Ayah]
}

struct SurahResponse: Codable {
    let data: SurahDetail
}

struct QuranFetchView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var surahs: [Surah] = []
    @State private var loading = true
    @State private var failed = false
    @State private var query = ""

    private var filtered: [Surah] {
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return surahs }
        return surahs.filter { $0.name.contains(q) || "\($0.number)" == q }
    }

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView("جاري تحميل السور...")
                } else if failed {
                    VStack(spacing: 12) {
                        Text("تعذر التحميل. تأكد من اتصالك بالإنترنت.")
                            .foregroundStyle(.secondary)
                        Button("إعادة المحاولة") { Task { await loadList() } }
                    }
                } else {
                    List(filtered) { s in
                        NavigationLink {
                            SurahRangeView(surah: s, onDone: { dismiss() })
                        } label: {
                            HStack {
                                Text("\(arabicNumber(s.number))")
                                    .font(.footnote.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 34)
                                Text(s.name)
                                    .font(.system(size: 20, design: .serif))
                                Spacer()
                                Text("\(arabicNumber(s.numberOfAyahs)) آية")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .searchable(text: $query, prompt: "ابحث باسم السورة")
                }
            }
            .navigationTitle("اختر سورة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إغلاق") { dismiss() }
                }
            }
        }
        .task { await loadList() }
    }

    private func loadList() async {
        loading = true
        failed = false
        do {
            let url = URL(string: "https://api.alquran.cloud/v1/surah")!
            let (data, _) = try await URLSession.shared.data(from: url)
            surahs = try JSONDecoder().decode(SurahListResponse.self, from: data).data
        } catch {
            failed = true
        }
        loading = false
    }
}

struct SurahRangeView: View {
    @EnvironmentObject var store: Store

    let surah: Surah
    let onDone: () -> Void

    @State private var ayahs: [Ayah] = []
    @State private var loading = true
    @State private var failed = false
    @State private var from = 1
    @State private var to = 1

    var body: some View {
        Group {
            if loading {
                ProgressView("جاري تحميل الآيات...")
            } else if failed {
                VStack(spacing: 12) {
                    Text("تعذر التحميل. تأكد من اتصالك بالإنترنت.")
                        .foregroundStyle(.secondary)
                    Button("إعادة المحاولة") { Task { await load() } }
                }
            } else {
                Form {
                    Section("نطاق الآيات") {
                        Stepper(value: $from, in: 1...max(ayahs.count, 1)) {
                            Text("من الآية: \(arabicNumber(from))")
                        }
                        .onChange(of: from) { v in
                            if to < v { to = v }
                        }
                        Stepper(value: $to, in: 1...max(ayahs.count, 1)) {
                            Text("إلى الآية: \(arabicNumber(to))")
                        }
                        .onChange(of: to) { v in
                            if from > v { from = v }
                        }
                        Button("السورة كاملة") {
                            from = 1
                            to = ayahs.count
                        }
                    }
                    Section {
                        Button {
                            add()
                        } label: {
                            Label("إضافة إلى محفوظاتي", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .navigationTitle(surah.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        loading = true
        failed = false
        do {
            let url = URL(string: "https://api.alquran.cloud/v1/surah/\(surah.number)/quran-uthmani")!
            let (data, _) = try await URLSession.shared.data(from: url)
            ayahs = try JSONDecoder().decode(SurahResponse.self, from: data).data.ayahs
            from = 1
            to = min(ayahs.count, 5)
            if to < 1 { to = 1 }
        } catch {
            failed = true
        }
        loading = false
    }

    private func add() {
        let selected = ayahs.filter { $0.numberInSurah >= from && $0.numberInSurah <= to }
        let text = selected
            .map { "\($0.text) ﴿\(arabicNumber($0.numberInSurah))﴾" }
            .joined(separator: " ")
        var title = surah.name
        if !(from == 1 && to == ayahs.count) {
            title += " (\(arabicNumber(from))-\(arabicNumber(to)))"
        }
        store.add(MemoItem(title: title, text: text, kind: .surah))
        onDone()
    }
}
