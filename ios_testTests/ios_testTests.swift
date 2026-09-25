import Foundation
import Testing
@testable import ios_test

@MainActor
struct ios_testTests {
    @Test func tasksPersistAcrossLaunches() throws {
        let directory = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("tasks.json")
        let store = TaskStore(fileURL: url)
        store.add("   ")
        #expect(store.items.isEmpty)
        store.add("  İlk görev  ", important: true)
        let item = try #require(store.items.first)
        #expect(item.title == "İlk görev")
        store.toggleCompletion(item)
        store.rename(item, to: "Yeni başlık")
        let restored = TaskStore(fileURL: url)
        #expect(restored.items.first?.title == "Yeni başlık")
        #expect(restored.items.first?.isCompleted == true)
        #expect(restored.items.first?.isImportant == true)
        restored.delete(item)
        #expect(TaskStore(fileURL: url).items.isEmpty)
    }

    @Test func corruptStorageIsNotOverwritten() throws {
        let url = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let original = Data("broken data".utf8)
        try original.write(to: url)
        let store = TaskStore(fileURL: url)
        #expect(store.storageError != nil)
        store.add("Yeni görev")
        #expect(try Data(contentsOf: url) == original)
    }
}
