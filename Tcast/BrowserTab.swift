import Foundation
import WebKit

@Observable
class BrowserTab: Identifiable {
    let id = UUID()
    var title: String = "New Tab"
    var url: URL?
    var webView: WKWebView?
    var canGoBack = false
    var canGoForward = false
    
    init(url: URL? = nil) {
        self.url = url
    }
}
