import SwiftUI

struct ReviewSession: Identifiable {
    let id = UUID()
    let ids: [UUID]
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

struct TodayView: View {
    @EnvironmentObject var store: Store
    @State private var session: ReviewSession?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        StatCard(title: "أيام متواصلة", value: "\(store.streak)", icon: "flame.fill", color: .orange)
                        StatCard(title: "مستحق اليوم", value: "\(store.dueItems.count)", icon: "clock.fill", color: Theme.green)
                        StatCard(title: "متقن", value: "\(store.masteredCount)", icon: "checkmark.seal.fill", color: Theme.gold)
                    }

                    if store.items.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "book.pages")
                                .font(.system(size: 50))
                                .foregroundStyle(Theme.green.opacity(0.6))
                            Text("ابدأ بإضافة أول محفوظ")
                                .font(.headline)
                            Text("من تبويب «محفوظاتي» أضف آيات من القرآن أو أبيات شعر أو أي نص تريد حفظه.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        .padding(.horizontal)
                    } else if store.dueItems.isEmpty {
                        VStack(spacing: 10) {
                            Text("🎉")
                                .font(.system(size: 54))
                            Text("أنجزت مراجعة اليوم")
                                .font(.headline)
                            Text("ارجع في موعد المراجعة القادم، أو افتح أي محفوظ من «محفوظاتي» للتدرب عليه.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        .padding(.horizontal)
                    } else {
                        Button {
                            session = ReviewSession(ids: store.dueItems.map { $0.id })
                        } label: {
                            Label("ابدأ المراجعة", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.green))
                                .foregroundStyle(.white)
                        }

                        VStack(spacing: 8) {
                            ForEach(store.dueItems) { it in
                                Button {
                                    session = ReviewSession(ids: [it.id])
                                } label: {
                                    ItemRow(item: it)
                                        .padding(12)
                                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle("حافظ")
        }
        .fullScreenCover(item: $session) { s in
            ReviewView(session: s)
        }
    }
}

struct ItemRow: View {
    let item: MemoItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.kind.icon)
                .font(.title3)
                .foregroundStyle(Theme.green)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { i in
                        Circle()
                            .fill(i <= item.level ? Theme.gold : Color.gray.opacity(0.25))
                            .frame(width: 8, height: 8)
                    }
                    Text(item.isDue ? "مستحق الآن" : "المراجعة \(relativeText(item.nextReview))")
                        .font(.caption)
                        .foregroundStyle(item.isDue ? Theme.green : .secondary)
                        .padding(.leading, 4)
                }
            }
            Spacer()
            Image(systemName: "chevron.left")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
    }
}
