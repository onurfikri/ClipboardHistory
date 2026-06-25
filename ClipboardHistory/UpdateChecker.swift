import Foundation
import AppKit

class UpdateChecker: ObservableObject {
    @Published var hasUpdate = false
    @Published var latestVersion = ""
    @Published var releaseURL: URL?
    @Published var isChecking = false

    let githubRepo = "onurfikri/ClipboardHistory"

    let currentVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }()

    func checkForUpdates(showAlertIfUpToDate: Bool = false) {
        guard !isChecking else { return }
        guard let url = URL(string: "https://api.github.com/repos/\(githubRepo)/releases/latest") else { return }

        isChecking = true

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self else { return }

            DispatchQueue.main.async {
                self.isChecking = false

                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String,
                      let htmlURL = json["html_url"] as? String,
                      let releaseURL = URL(string: htmlURL) else {
                    if showAlertIfUpToDate { self.showAlert("Kontrol edilemedi", "İnternet bağlantısını kontrol edin.") }
                    return
                }

                let remote = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
                self.latestVersion = remote
                self.releaseURL = releaseURL
                self.hasUpdate = self.isNewer(remote, than: self.currentVersion)

                if showAlertIfUpToDate && !self.hasUpdate {
                    self.showAlert("Güncelsin ✓", "v\(self.currentVersion) en son sürüm.")
                }
            }
        }.resume()
    }

    func openReleasePage() {
        guard let url = releaseURL else { return }
        NSWorkspace.shared.open(url)
    }

    private func isNewer(_ remote: String, than current: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let c = current.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(r.count, c.count) {
            let rv = i < r.count ? r[i] : 0
            let cv = i < c.count ? c[i] : 0
            if rv != cv { return rv > cv }
        }
        return false
    }

    private func showAlert(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Tamam")
        alert.runModal()
    }
}
