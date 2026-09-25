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
            VStack(alignment: .leading, spacing: 26) {
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
