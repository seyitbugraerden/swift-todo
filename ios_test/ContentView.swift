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
                Spacer()
            }
            .padding(36)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .textBackgroundColor))
        }
        .tint(accent)
        .frame(minWidth: 800, minHeight: 580)

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

    private func matches(_ item: TodoItem, filter: TaskFilter) -> Bool {
        switch filter {
        case .all: true
        case .important: item.isImportant && !item.isCompleted
        case .completed: item.isCompleted
        }
    }


}

#Preview {
    ContentView()
        .environmentObject(TaskStore(fileURL: URL.temporaryDirectory.appendingPathComponent("odak-preview.json")))
        .environment(\.locale, Locale(identifier: "tr_TR"))
}
