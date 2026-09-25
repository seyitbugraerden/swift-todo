import SwiftUI

struct TodoItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var isCompleted = false
    var isImportant = false
    var createdAt = Date()
}

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var items: [TodoItem] = []
    @Published var storageError: String?
    private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? URL.applicationSupportDirectory
            .appendingPathComponent("Odak", isDirectory: true)
            .appendingPathComponent("tasks.json")
        guard FileManager.default.fileExists(atPath: self.fileURL.path) else { return }
        do {
            items = try JSONDecoder().decode([TodoItem].self, from: Data(contentsOf: self.fileURL))
        } catch {
            storageError = "Kaydedilen görevler okunamadı. Verilerinin üzerine yazmamak için uygulamayı yeniden başlatmayı dene."
        }
    }

    func add(_ title: String, important: Bool = false) {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        update { $0.insert(TodoItem(title: title, isImportant: important), at: 0) }
    }

    func toggleCompletion(_ item: TodoItem) {
        update { items in
            guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
            items[index].isCompleted.toggle()
        }
    }

    func toggleImportance(_ item: TodoItem) {
        update { items in
            guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
            items[index].isImportant.toggle()
        }
    }

    func rename(_ item: TodoItem, to title: String) {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        update { items in
            guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
            items[index].title = title
        }
    }

    func delete(_ item: TodoItem) {
        update { $0.removeAll { $0.id == item.id } }
    }

    private func update(_ mutation: (inout [TodoItem]) -> Void) {
        guard storageError == nil else { return }
        var updated = items
        mutation(&updated)
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(updated).write(to: fileURL, options: .atomic)
            items = updated
        } catch {
            storageError = "Değişiklik kaydedilemedi. Disk alanını ve dosya erişimini kontrol edip yeniden dene."
        }
    }
}
