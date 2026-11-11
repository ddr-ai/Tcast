import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    @Binding var tab: BrowserTab
    var onTitleChange: (String) -> Void
    var onURLChange: (URL?) -> Void
    var onNavigationChange: (Bool, Bool) -> Void
    var onLongPress: (URL, String?) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        tab.webView = webView
        
        if let url = tab.url {
            webView.load(URLRequest(url: url))
        }
        
        // Long-press context for links/images/videos
        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        webView.addGestureRecognizer(longPress)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = tab.url, uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.onTitleChange(webView.title ?? "Untitled")
            parent.onURLChange(webView.url)
            parent.onNavigationChange(webView.canGoBack, webView.canGoForward)
        }
        
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            parent.onNavigationChange(webView.canGoBack, webView.canGoForward)
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began else { return }
            let point = gesture.location(in: gesture.view)
            guard let webView = gesture.view as? WKWebView else { return }
            
            webView.evaluateJavaScript("""
                (function(x, y) {
                    var el = document.elementFromPoint(x, y);
                    if (!el) return null;
                    var a = el.closest('a');
                    if (a && a.href) return {type: 'link', url: a.href, title: a.innerText || a.title || ''};
                    var img = el.closest('img');
                    if (img && img.src) return {type: 'image', url: img.src, title: img.alt || ''};
                    var video = el.closest('video');
                    if (video) {
                        var src = video.currentSrc || video.src || (video.querySelector('source') && video.querySelector('source').src);
                        if (src) return {type: 'video', url: src, title: video.title || ''};
                    }
                    return null;
                })(\(point.x), \(point.y))
            """) { result, error in
                if let dict = result as? [String: String], let urlStr = dict["url"], let url = URL(string: urlStr) {
                    self.parent.onLongPress(url, dict["title"])
                }
            }
        }
    }
}
