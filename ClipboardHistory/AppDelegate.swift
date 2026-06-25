import AppKit
import SwiftUI
import Carbon.HIToolbox

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: EventMonitor?
    let store = HistoryStore()
    let updateChecker = UpdateChecker()
    private var clipboardMonitor: ClipboardMonitor?
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()
        setupClipboardMonitor()
        registerGlobalHotkey()

        // Başlangıçtan 5sn sonra güncelleme kontrol et
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.updateChecker.checkForUpdates()
        }
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clipboard.fill", accessibilityDescription: "Pano Geçmişi")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 380, height: 520)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: HistoryPanelView(store: store)
                .environmentObject(updateChecker)
        )
        self.popover = popover

        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, self.popover?.isShown == true else { return }
            self.closePopover()
        }
    }

    // MARK: - Clipboard Monitor

    private func setupClipboardMonitor() {
        clipboardMonitor = ClipboardMonitor(store: store)
        clipboardMonitor?.start()
    }

    // MARK: - Global Hotkey (Cmd+Shift+V) via Carbon

    private func registerGlobalHotkey() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = 0x434C4850
        hotKeyID.id = 1

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), hotKeyHandler, 1, &eventSpec, selfPtr, &eventHandlerRef)
        RegisterEventHotKey(UInt32(kVK_ANSI_V), UInt32(cmdKey | shiftKey), hotKeyID,
                            GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    // MARK: - Popover

    @objc func togglePopover(_ sender: AnyObject?) {
        if popover?.isShown == true {
            closePopover()
        } else {
            openPopover()
        }
    }

    func openPopover() {
        guard let button = statusItem?.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        eventMonitor?.start()

        // Panel açılış bildirimi — HistoryPanelView aramayı sıfırlar
        NotificationCenter.default.post(name: .panelDidOpen, object: nil)

        // Arama TextField'ının otomatik focus almasını engelle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.popover?.contentViewController?.view.window?.makeFirstResponder(
                self.popover?.contentViewController?.view
            )
        }
    }

    func closePopover() {
        popover?.performClose(nil)
        eventMonitor?.stop()
    }
}

extension Notification.Name {
    static let panelDidOpen = Notification.Name("ClipboardHistory.panelDidOpen")
}

private let hotKeyHandler: EventHandlerUPP = { _, _, userData -> OSStatus in
    guard let ptr = userData else { return OSStatus(eventNotHandledErr) }
    let delegate = Unmanaged<AppDelegate>.fromOpaque(ptr).takeUnretainedValue()
    DispatchQueue.main.async { delegate.togglePopover(nil) }
    return noErr
}
