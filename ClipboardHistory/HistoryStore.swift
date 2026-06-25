import Foundation
import AppKit

class HistoryStore: ObservableObject {
    @Published var items: [ClipItem] = []
    private let maxItems = 50

    // clearContents() ve setString() farklı changeCount'lar üretebilir;
    // kendi yazdığımız her iki değeri de saklayıp monitörde atlıyoruz.
    private var ownedChangeCounts = Set<Int>()

    func consumeOwnedChangeCount(_ count: Int) -> Bool {
        ownedChangeCounts.remove(count) != nil
    }

    func add(_ item: ClipItem) {
        DispatchQueue.main.async {
            if let text = item.textValue {
                self.items.removeAll { $0.textValue == text }
            }
            self.items.insert(item, at: 0)
            if self.items.count > self.maxItems {
                self.items = Array(self.items.prefix(self.maxItems))
            }
        }
    }

    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }

    func clear() {
        items.removeAll()
    }

    func copyToPasteboard(_ item: ClipItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        ownedChangeCounts.insert(pb.changeCount)   // clearContents sonrası count

        switch item.content {
        case .text(let s):
            pb.setString(s, forType: .string)
        case .image(let img):
            pb.writeObjects([img])
        }
        ownedChangeCounts.insert(pb.changeCount)   // write sonrası count
    }
}
