import SwiftUI
import AVKit

struct ContentView: View {
    @State private var tabs: [BrowserTab] = [BrowserTab(url: URL(string: "https://www.google.com"))]
    @State private var selectedTabId: UUID?
    @State private var address = "https://www.google.com"
    @State private var casting = CastingManager()
    @State private var showCastSheet = false
    @State private var contextURL: URL?
    @State private var contextTitle: String?
    @State private var showContextMenu = false
    @State private var preferredCastURL: URL?
    
    var selectedTab: BrowserTab? {
        tabs.first { $0.id == selectedTabId } ?? tabs.first
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Address bar + nav
            HStack {
                Button(action: goBack) { Image(systemName: "chevron.left") }
                    .disabled(selectedTab?.canGoBack != true)
                Button(action: goForward) { Image(systemName: "chevron.right") }
                    .disabled(selectedTab?.canGoForward != true)
                
                TextField("Search or enter URL", text: $address)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { loadAddress() }
                    .autocapitalization(.none)
                    .keyboardType(.webSearch)
                
                Button(action: loadAddress) { Image(systemName: "arrow.right.circle.fill") }
                Button(action: { prepareAndShowCast() }) { Image(systemName: "airplayvideo") }
            }
            .padding(8)
            .background(Color(.systemGray6))
            
            // Tab bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(tabs) { tab in
                        HStack {
                            Text(tab.title.prefix(20))
                                .lineLimit(1)
                            Button(action: { closeTab(tab) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(tab.id == selectedTabId ? Color.accentColor.opacity(0.3) : Color.clear)
                        .cornerRadius(8)
                        .onTapGesture { selectTab(tab) }
                    }
                    Button(action: newTab) {
                        Image(systemName: "plus")
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.horizontal)
            }
            .frame(height: 40)
            .background(Color(.systemGray5))
            
            // Web view
            if let tab = selectedTab, let binding = binding(for: tab) {
                WebView(
                    tab: binding,
                    onTitleChange: { title in
                        if let idx = tabs.firstIndex(where: { $0.id == tab.id }) {
                            tabs[idx].title = title
                        }
                    },
                    onURLChange: { url in
                        if let url { address = url.absoluteString }
                    },
                    onNavigationChange: { back, forward in
                        if let idx = tabs.firstIndex(where: { $0.id == tab.id }) {
                            tabs[idx].canGoBack = back
                            tabs[idx].canGoForward = forward
                        }
                    },
                    onLongPress: { url, title in
                        contextURL = url
                        contextTitle = title
                        showContextMenu = true
                    }
                )
            }
        }
        .onAppear {
            if selectedTabId == nil { selectedTabId = tabs.first?.id }
            Task { await casting.scan() }
        }
        .sheet(isPresented: $showCastSheet) {
            CastSheet(casting: casting, preferredURL: preferredCastURL ?? selectedTab?.url)
        }
        .confirmationDialog("Open Link", isPresented: $showContextMenu) {
            if let url = contextURL {
                Button("Open in New Tab") {
                    openInNewTab(url, title: contextTitle ?? url.host ?? "Tab")
                }
                Button("Copy URL") {
                    UIPasteboard.general.string = url.absoluteString
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private func prepareAndShowCast() {
        preferredCastURL = nil
        if let webView = selectedTab?.webView {
            webView.evaluateJavaScript("""
                (function() {
                    var v = document.querySelector('video');
                    if (v) {
                        var src = v.currentSrc || v.src || (v.querySelector('source') && v.querySelector('source').src);
                        if (src && src.startsWith('http')) return src;
                    }
                    return null;
                })()
            """) { result, _ in
                if let s = result as? String, let u = URL(string: s) {
                    preferredCastURL = u
                }
                showCastSheet = true
            }
        } else {
            showCastSheet = true
        }
    }
    
    private func binding(for tab: BrowserTab) -> Binding<BrowserTab>? {
        guard let idx = tabs.firstIndex(where: { $0.id == tab.id }) else { return nil }
        return $tabs[idx]
    }
    
    private func loadAddress() {
        var text = address.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.hasPrefix("http") {
            if text.contains(" ") || !text.contains(".") {
                text = "https://www.google.com/search?q=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text)"
            } else {
                text = "https://\(text)"
            }
        }
        if let url = URL(string: text) {
            selectedTab?.url = url
            selectedTab?.webView?.load(URLRequest(url: url))
        }
    }
    
    private func goBack() { selectedTab?.webView?.goBack() }
    private func goForward() { selectedTab?.webView?.goForward() }
    
    private func newTab() {
        let tab = BrowserTab(url: URL(string: "https://www.google.com"))
        tabs.append(tab)
        selectedTabId = tab.id
        address = "https://www.google.com"
    }
    
    private func closeTab(_ tab: BrowserTab) {
        tabs.removeAll { $0.id == tab.id }
        if tabs.isEmpty {
            let t = BrowserTab(url: URL(string: "https://www.google.com"))
            tabs.append(t)
            selectedTabId = t.id
        } else if selectedTabId == tab.id {
            selectedTabId = tabs.first?.id
        }
    }
    
    private func selectTab(_ tab: BrowserTab) {
        selectedTabId = tab.id
        address = tab.url?.absoluteString ?? ""
    }
    
    private func openInNewTab(_ url: URL, title: String) {
        let tab = BrowserTab(url: url)
        tab.title = title
        tabs.append(tab)
        selectedTabId = tab.id
        address = url.absoluteString
    }
}

struct CastSheet: View {
    @Bindable var casting: CastingManager
    var preferredURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Status") {
                    Text(casting.statusMessage)
                    if casting.isScanning { ProgressView() }
                    if let url = preferredURL {
                        Text("Casting: \(url.lastPathComponent.isEmpty ? url.absoluteString : url.lastPathComponent)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("AirPlay (incl. wireless HDMI adapters)") {
                    HStack {
                        Text("Select AirPlay device")
                        Spacer()
                        AirPlayPicker()
                            .frame(width: 44, height: 44)
                    }
                    Text("AirPlay is the supported path for Miracast-compatible adapters on iOS. You can also use Control Center → Screen Mirroring.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Chromecast") {
                    ForEach(Array(casting.chromecastDevices.enumerated()), id: \.offset) { _, device in
                        Button(device.name) {
                            if let url = preferredURL {
                                Task { await casting.castToChromecast(device, url: url, title: "Tcast") }
                            }
                        }
                    }
                    if casting.chromecastDevices.isEmpty {
                        Text("None found — tap Rescan")
                            .foregroundStyle(.secondary)
                    }
                }
                Section("DLNA / UPnP") {
                    ForEach(Array(casting.dlnaDevices.enumerated()), id: \.offset) { _, device in
                        Button(device.name) {
                            if let url = preferredURL {
                                Task { await casting.castToDLNA(device, url: url, title: "Tcast") }
                            }
                        }
                    }
                    if casting.dlnaDevices.isEmpty {
                        Text("None found — tap Rescan (multicast entitlement may be required)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Cast")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Rescan") { Task { await casting.scan() } }
                }
            }
        }
    }
}
