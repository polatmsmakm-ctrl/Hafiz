import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var store: Store
    @State private var showAdd = false
    @State private var showQuran = false
    @State private var session: ReviewSession?
    @State private var editing: MemoItem?

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.items) { it in
                    Button {
                        session = ReviewSession(ids: [it.id])
                    } label: {
                        ItemRow(item: it)
                    }
                    .swipeActions(edge: .leading) {
                        Button("تعديل") { editing = it }
                            .tint(.blue)
                    }
                }
                .onDelete { store.delete(at: $0) }
            }
            .overlay {
                if store.items.isEmpty {
                    Text("لا توجد محفوظات بعد.\nاضغط + لإضافة نص أو جلب سورة.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle("محفوظاتي")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showQuran = true
                        } label: {
                            Label("جلب آيات من القرآن", systemImage: "book.closed")
                        }
                        Button {
                            showAdd = true
                        } label: {
                            Label("إضافة نص يدوياً", systemImage: "square.and.pencil")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
        }
        .sheet(isPresented: $showAdd) { EditItemView(item: nil) }
        .sheet(item: $editing) { it in EditItemView(item: it) }
        .sheet(isPresented: $showQuran) { QuranFetchView() }
        .fullScreenCover(item: $session) { s in ReviewView(session: s) }
    }
}

struct EditItemView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    let item: MemoItem?

    @State private var title = ""
    @State private var text = ""
    @State private var kind: MemoItem.Kind = .poem

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("العنوان") {
                    TextField("مثال: قصيدة، حديث، متن...", text: $title)
                }
                Section("النوع") {
                    Picker("النوع", selection: $kind) {
                        ForEach(MemoItem.Kind.allCases, id: \.self) { k in
                            Text(k.label).tag(k)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("النص") {
                    TextEditor(text: $text)
                        .frame(minHeight: 240)
                }
            }
            .navigationTitle(item == nil ? "إضافة محفوظ" : "تعديل المحفوظ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if let it = item {
                    title = it.title
                    text = it.text
                    kind = it.kind
                }
            }
        }
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if var it = item {
            it.title = t
            it.text = body
            it.kind = kind
            store.update(it)
        } else {
            store.add(MemoItem(title: t, text: body, kind: kind))
        }
        dismiss()
    }
}
