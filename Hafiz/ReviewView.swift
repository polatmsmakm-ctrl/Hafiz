import SwiftUI

struct WordChip: View {
    let word: String
    let hidden: Bool
    let size: CGFloat

    var body: some View {
        Text(word)
            .font(.system(size: size, weight: .medium, design: .serif))
            .foregroundStyle(Theme.ink)
            .opacity(hidden ? 0 : 1)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(hidden ? Theme.green.opacity(0.22) : Color.clear)
            )
    }
}

struct ReviewView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @AppStorage("fontSize") private var fontSize: Double = 26

    let session: ReviewSession

    @State private var index = 0
    @State private var hidden: Set<Int> = []
    @State private var revealAll = false
    @State private var done = false
    @State private var goodCount = 0

    private var ids: [UUID] {
        session.ids.filter { id in store.items.contains(where: { $0.id == id }) }
    }

    private var current: MemoItem? {
        guard index < ids.count else { return nil }
        let id = ids[index]
        return store.items.first(where: { $0.id == id })
    }

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()
            if done || current == nil {
                finishedView
            } else if let it = current {
                VStack(spacing: 0) {
                    header(it)
                    ScrollView {
                        VStack(spacing: 16) {
                            Text(it.title)
                                .font(.title3.bold())
                                .foregroundStyle(Theme.green)
                                .multilineTextAlignment(.center)
                            Text(it.levelName)
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            let words = it.words
                            FlowLayout {
                                ForEach(Array(words.indices), id: \.self) { i in
                                    WordChip(word: words[i], hidden: hidden.contains(i), size: fontSize)
                                        .onTapGesture {
                                            if hidden.contains(i) { hidden.remove(i) }
                                        }
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                    }
                    controls(it)
                }
            }
        }
        .onAppear { prepare() }
    }

    private func header(_ it: MemoItem) -> some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.gray.opacity(0.6))
                }
                Spacer()
                Text("\(index + 1) / \(ids.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: it.kind.icon)
                    .font(.title3)
                    .foregroundStyle(Theme.green)
            }
            ProgressView(value: Double(index), total: Double(max(ids.count, 1)))
                .tint(Theme.gold)
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    @ViewBuilder
    private func controls(_ it: MemoItem) -> some View {
        VStack(spacing: 10) {
            if it.level == 0 {
                Button {
                    finish(good: true)
                } label: {
                    Text("قرأتها وأبدأ الحفظ")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.green))
                        .foregroundStyle(.white)
                }
            } else {
                Button {
                    if revealAll {
                        prepare()
                    } else {
                        hidden = []
                        revealAll = true
                    }
                } label: {
                    Label(revealAll ? "إخفاء مرة أخرى" : "إظهار الكل",
                          systemImage: revealAll ? "eye.slash" : "eye")
                        .font(.subheadline)
                }

                HStack(spacing: 12) {
                    Button {
                        finish(good: false)
                    } label: {
                        Text("نسيت")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.red.opacity(0.85)))
                            .foregroundStyle(.white)
                    }
                    Button {
                        finish(good: true)
                    } label: {
                        Text("حفظتها")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.green))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.6))
    }

    private var finishedView: some View {
        VStack(spacing: 16) {
            Text("🌟")
                .font(.system(size: 64))
            Text("أحسنت!")
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.green)
            Text("أنهيت مراجعة \(ids.count) محفوظ، منها \(goodCount) تقدّمت فيها.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 30)
            Button {
                dismiss()
            } label: {
                Text("إغلاق")
                    .font(.headline)
                    .frame(maxWidth: 220)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.green))
                    .foregroundStyle(.white)
            }
            .padding(.top, 10)
        }
    }

    private func prepare() {
        guard let it = current else { return }
        revealAll = false
        let words = it.words
        let candidates = words.indices.filter { !words[$0].hasPrefix("﴿") }
        let n = Int((Double(candidates.count) * it.hiddenFraction).rounded())
        hidden = Set(candidates.shuffled().prefix(n))
    }

    private func finish(good: Bool) {
        guard let it = current else { return }
        store.grade(it.id, good: good)
        if good { goodCount += 1 }
        if index + 1 >= ids.count {
            done = true
        } else {
            index += 1
            prepare()
        }
    }
}
