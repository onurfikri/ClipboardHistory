import SwiftUI

struct HistoryPanelView: View {
    @ObservedObject var store: HistoryStore
    @EnvironmentObject var updateChecker: UpdateChecker
    @State private var searchText = ""
    @State private var hoveredID: UUID?

    var filteredItems: [ClipItem] {
        guard !searchText.isEmpty else { return store.items }
        return store.items.filter {
            $0.textValue?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if updateChecker.hasUpdate { updateBanner }
            Divider()
            searchBar
            Divider()
            content
        }
        .frame(width: 380, height: 520)
        .background(Color(.windowBackgroundColor))
        // Panel açıldığında aramayı sıfırla
        .onReceive(NotificationCenter.default.publisher(for: .panelDidOpen)) { _ in
            searchText = ""
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "clipboard.fill")
                .foregroundColor(.accentColor)
            Text("Pano Geçmişi")
                .font(.headline)
            Spacer()
            Text("\(store.items.count) öğe")
                .font(.caption)
                .foregroundColor(.secondary)
            if !store.items.isEmpty {
                Button("Temizle") { store.clear() }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Update Banner

    private var updateBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(.white)
                .font(.system(size: 13))
            Text("Yeni sürüm mevcut: v\(updateChecker.latestVersion)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
            Spacer()
            Button("İndir") {
                updateChecker.openReleasePage()
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.accentColor)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 13))
            TextField("Ara...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if filteredItems.isEmpty {
            Spacer()
            emptyState
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                        ClipItemView(
                            item: item,
                            index: index,
                            isHovered: hoveredID == item.id,
                            onSelect: {
                                store.copyToPasteboard(item)
                                pasteToFrontApp()
                                closePanel()
                            },
                            onDelete: {
                                if let idx = store.items.firstIndex(of: item) {
                                    store.remove(at: IndexSet(integer: idx))
                                }
                            }
                        )
                        .onHover { hoveredID = $0 ? item.id : nil }
                        if index < filteredItems.count - 1 {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clipboard")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text(store.items.isEmpty ? "Henüz bir şey kopyalanmadı" : "Sonuç bulunamadı")
                .foregroundColor(.secondary)
                .font(.system(size: 13))
        }
    }

    // MARK: - Helpers

    private func closePanel() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let delegate = NSApp.delegate as? AppDelegate {
                delegate.togglePopover(nil)
            }
        }
    }

    private func pasteToFrontApp() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let src = CGEventSource(stateID: .hidSystemState)
            let keyDown = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true)
            let keyUp = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false)
            keyDown?.flags = .maskCommand
            keyUp?.flags = .maskCommand
            keyDown?.post(tap: .cgAnnotatedSessionEventTap)
            keyUp?.post(tap: .cgAnnotatedSessionEventTap)
        }
    }
}
