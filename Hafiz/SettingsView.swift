import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store

    @AppStorage("remOn") private var remOn = false
    @AppStorage("remHour") private var remHour = 19
    @AppStorage("remMin") private var remMin = 0
    @AppStorage("fontSize") private var fontSize: Double = 26

    @State private var denied = false

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(hour: remHour, minute: remMin)) ?? Date()
            },
            set: { d in
                let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                remHour = c.hour ?? 19
                remMin = c.minute ?? 0
                if remOn {
                    let h = remHour
                    let m = remMin
                    Task { _ = await Reminder.schedule(hour: h, minute: m) }
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("التذكير اليومي") {
                    Toggle("ذكّرني بالمراجعة كل يوم", isOn: $remOn)
                    if remOn {
                        DatePicker("وقت التذكير", selection: timeBinding, displayedComponents: .hourAndMinute)
                    }
                }

                Section("حجم الخط في المراجعة") {
                    Slider(value: $fontSize, in: 18...40, step: 1)
                    Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
                        .font(.system(size: fontSize, weight: .medium, design: .serif))
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                Section("إحصاءات") {
                    LabeledContent("عدد المحفوظات", value: "\(store.items.count)")
                    LabeledContent("المتقنة", value: "\(store.masteredCount)")
                    LabeledContent("أيام المراجعة", value: "\(store.days.count)")
                }

                Section("كيف يعمل التطبيق") {
                    Text("كل محفوظ يبدأ بقراءة النص كاملاً، ثم تُخفى نسبة من الكلمات تزداد مع كل نجاح: ربع، نصف، ثلاثة أرباع، ثم كلها. اضغط على الكلمة المخفية لتظهر. كلما حفظتها صارت المراجعة أبعد: يوم، يومان، ٥ أيام، ١٠ أيام، ثم ٣٠ يوماً. وإن نسيت ينزل المستوى وتعود المراجعة قريباً.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle("الإعدادات")
            .onChange(of: remOn) { on in
                if on {
                    let h = remHour
                    let m = remMin
                    Task {
                        let ok = await Reminder.schedule(hour: h, minute: m)
                        if !ok {
                            remOn = false
                            denied = true
                        }
                    }
                } else {
                    Reminder.cancel()
                }
            }
            .alert("تعذر تفعيل التذكير", isPresented: $denied) {
                Button("حسناً", role: .cancel) {}
            } message: {
                Text("فعّل الإشعارات لتطبيق حافظ من إعدادات الآيفون ثم حاول مرة أخرى.")
            }
        }
    }
}
