import Foundation
import AppKit

struct ClipItem: Identifiable, Equatable {
    let id: UUID
    let content: Content
    let date: Date

    init(content: Content) {
        self.id = UUID()
        self.content = content
        self.date = Date()
    }

    enum Content {
        case text(String)
        case image(NSImage)
    }

    var previewText: String {
        switch content {
        case .text(let s): return s
        case .image: return "[Görsel]"
        }
    }

    var isText: Bool {
        if case .text = content { return true }
        return false
    }

    var textValue: String? {
        if case .text(let s) = content { return s }
        return nil
    }

    static func == (lhs: ClipItem, rhs: ClipItem) -> Bool {
        lhs.id == rhs.id
    }
}
