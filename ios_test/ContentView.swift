import SwiftUI

private enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "Tüm görevler", important = "Önemli", completed = "Tamamlananlar"
    var id: Self { self }
    var icon: String {
        switch self {
        case .all: "square.stack.3d.up"
        case .important: "star"
        case .completed: "checkmark.circle"
        }
    }
    var subtitle: String {
        switch self {
        case .all: "Zihnini boşalt. Bir sonraki adıma odaklan."
        case .important: "Senin için fark yaratacak işlere yer aç."
        case .completed: "Her küçük adım, bir ilerleme."
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var store: TaskStore
    @State private var filter: TaskFilter = .all
    @State private var search = ""
    @State private var newTitle = ""
    @State private var editingItem: TodoItem?
    @State private var editedTitle = ""
    @FocusState private var composerFocused: Bool
    private let accent = Color(red: 0.36, green: 0.36, blue: 0.84)

    private var completedCount: Int { store.items.filter(\.isCompleted).count }
    private var visibleItems: [TodoItem] {
        store.items.filter { item in
            matches(item, filter: filter) && (search.isEmpty || item.title.localizedStandardContains(search))
        }.sorted { !$0.isCompleted && $1.isCompleted }
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            VStack(alignment: .leading, spacing: 26) {
                header
                if let error = store.storageError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption).foregroundStyle(.red)
                }
                progressCard
                composer
                taskList
                footer
            }
            .padding(36)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .textBackgroundColor))
        }
        .tint(accent)
        .frame(minWidth: 800, minHeight: 580)
        .sheet(item: $editingItem) { item in
            VStack(alignment: .leading, spacing: 20) {
                Text("Görevi düzenle").font(.title2.bold())
                TextField("Görev adı", text: $editedTitle)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { saveEdit(item) }
                HStack {
                    Spacer()
                    Button("Vazgeç") { editingItem = nil }.keyboardShortcut(.cancelAction)
                    Button("Kaydet") { saveEdit(item) }
                        .buttonStyle(.borderedProminent)
                        .disabled(editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(28)
            .frame(width: 400)
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(accent.gradient, in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 2) {
                    Text("odak").font(.system(size: 24, weight: .bold, design: .rounded))
                    Text("Daha az karmaşa.").font(.caption).foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("ÇALIŞMA ALANIM")
                    .font(.system(size: 10, weight: .semibold)).tracking(1.6)
                    .foregroundStyle(.secondary).padding(.horizontal, 12).padding(.bottom, 6)
                ForEach(TaskFilter.allCases) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) { filter = option }
                    } label: {
                        HStack(spacing: 11) {
                            Image(systemName: option.icon).frame(width: 18)
                            Text(option.rawValue).fontWeight(filter == option ? .semibold : .regular)
                            Spacer()
                            Text("\(store.items.filter { matches($0, filter: option) }.count)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .foregroundStyle(filter == option ? accent : Color.primary)
                        .background(filter == option ? accent.opacity(0.11) : .clear, in: RoundedRectangle(cornerRadius: 10))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: "leaf").font(.title3).foregroundStyle(accent)
                Text("Küçük adımlar,\nbüyük değişimler.")
                    .font(.system(size: 15, weight: .medium)).lineSpacing(4)
                Text("Bugün bir şeyle başla.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(accent.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
            Label("Sadece bu Mac’te saklanır", systemImage: "lock.shield")
                .font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .padding(22)
        .frame(width: 226)
        .frame(maxHeight: .infinity)
        .background(.thinMaterial)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(Date.now.formatted(Date.FormatStyle().day().month(.wide).weekday(.wide).locale(Locale(identifier: "tr_TR"))).uppercased())
                    .font(.system(size: 10, weight: .semibold)).tracking(1.5).foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "sun.max").foregroundStyle(accent)
            }
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(filter.rawValue).font(.system(size: 32, weight: .bold, design: .rounded))
                    Text(filter.subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var progressCard: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle().stroke(accent.opacity(0.12), lineWidth: 5)
                Circle().trim(from: 0, to: store.items.isEmpty ? 0 : CGFloat(completedCount) / CGFloat(store.items.count))
                    .stroke(accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "checkmark").font(.system(size: 18, weight: .semibold)).foregroundStyle(accent)
            }.frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 5) {
                Text(store.items.isEmpty ? "Yeni bir başlangıç" : "İlerleme kaydediyorsun")
                    .font(.system(size: 14, weight: .semibold))
                Text(store.items.isEmpty ? "İlk görevini ekle, gerisini adım adım hallet." : "\(store.items.count) görevden \(completedCount) tanesi tamamlandı.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(store.items.isEmpty ? "0%" : "\(completedCount * 100 / store.items.count)%")
                .font(.system(size: 24, weight: .semibold, design: .rounded)).foregroundStyle(accent)
        }
        .padding(20)
        .background(accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
    }

    private var composer: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle").font(.title3).foregroundStyle(accent)
            TextField("Aklında ne var? Yeni bir görev ekle…", text: $newTitle)
                .textFieldStyle(.plain).focused($composerFocused).onSubmit(addTask)
                .accessibilityLabel("Yeni görev")
            Button(action: addTask) {
                Image(systemName: "arrow.up").fontWeight(.semibold).padding(5)
            }
            .buttonStyle(.borderedProminent).clipShape(RoundedRectangle(cornerRadius: 8))
            .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Görev ekle").help("Görev ekle (Return)")
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).strokeBorder(composerFocused ? accent : Color.primary.opacity(0.12), lineWidth: 1))
        .background {
            Button("Yeni görev") { composerFocused = true }
                .keyboardShortcut("n", modifiers: .command).hidden()
        }
    }

    private var taskList: some View {
        VStack(spacing: 14) {
            HStack {
                Text("GÖREVLER · \(visibleItems.count)")
                    .font(.system(size: 10, weight: .semibold)).tracking(1.3).foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Görev ara", text: $search).textFieldStyle(.plain)
                        .accessibilityLabel("Görev ara")
                    if !search.isEmpty {
                        Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }
                            .buttonStyle(.plain).accessibilityLabel("Aramayı temizle")
                    }
                }.font(.caption).frame(width: 160)
            }
            if visibleItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: search.isEmpty ? "tray" : "magnifyingglass")
                        .font(.system(size: 32, weight: .light)).foregroundStyle(accent.opacity(0.7))
                    Text(search.isEmpty ? "Burada henüz görev yok" : "Görev bulunamadı")
                        .font(.headline)
                    Text(search.isEmpty ? "Yeni bir görev ekle veya başka bir listeye göz at." : "Başka bir kelimeyle aramayı dene.")
                        .font(.caption).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(visibleItems) { item in taskRow(item) }
                    }.padding(.vertical, 2)
                }
            }
        }.frame(maxHeight: .infinity)
    }

    private func taskRow(_ item: TodoItem) -> some View {
        HStack(spacing: 13) {
            Button { withAnimation { store.toggleCompletion(item) } } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(item.isCompleted ? accent : Color.secondary.opacity(0.6))
            }.buttonStyle(.plain)
                .accessibilityLabel(item.isCompleted ? "Görevi yeniden aç" : "Görevi tamamla")
            Text(item.title).font(.system(size: 14))
                .strikethrough(item.isCompleted)
                .foregroundStyle(item.isCompleted ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
            Button { store.toggleImportance(item) } label: {
                Image(systemName: item.isImportant ? "star.fill" : "star")
                    .foregroundStyle(item.isImportant ? Color.orange : Color.secondary.opacity(0.55))
            }.buttonStyle(.plain).accessibilityLabel(item.isImportant ? "Önemli işaretini kaldır" : "Önemli olarak işaretle")
            Menu {
                Button("Düzenle", systemImage: "pencil") { editedTitle = item.title; editingItem = item }
                Button("Sil", systemImage: "trash", role: .destructive) { withAnimation { store.delete(item) } }
            } label: { Image(systemName: "ellipsis").foregroundStyle(.secondary) }
                .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
                .accessibilityLabel("Görev seçenekleri")
        }
        .padding(16)
        .background(Color.primary.opacity(item.isCompleted ? 0.015 : 0.035), in: RoundedRectangle(cornerRadius: 12))
    }

    private var footer: some View {
        HStack {
            Circle().fill(Color.green).frame(width: 5, height: 5)
            Text("\(store.items.count - completedCount) görev seni bekliyor")
            Spacer()
            Text("Yeni görev  ⌘N")
        }.font(.system(size: 10)).foregroundStyle(.secondary)
    }

    private func matches(_ item: TodoItem, filter: TaskFilter) -> Bool {
        switch filter {
        case .all: true
        case .important: item.isImportant && !item.isCompleted
        case .completed: item.isCompleted
        }
    }

    private func addTask() {
        store.add(newTitle, important: filter == .important)
        guard store.storageError == nil else { return }
        newTitle = ""
        if filter == .completed { filter = .all }
        search = ""
        composerFocused = true
    }

    private func saveEdit(_ item: TodoItem) {
        store.rename(item, to: editedTitle)
        if store.storageError == nil { editingItem = nil }
    }
}

#Preview {
    ContentView()
        .environmentObject(TaskStore(fileURL: URL.temporaryDirectory.appendingPathComponent("odak-preview.json")))
        .environment(\.locale, Locale(identifier: "tr_TR"))
}
