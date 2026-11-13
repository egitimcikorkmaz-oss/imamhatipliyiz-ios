import SwiftUI
import WebKit

@MainActor enum WebSessionStore {
    static func clearCookies() async {
        let store = WKWebsiteDataStore.default()
        let types: Set<String> = [WKWebsiteDataTypeCookies, WKWebsiteDataTypeSessionStorage, WKWebsiteDataTypeLocalStorage]
        await withCheckedContinuation { continuation in
            store.removeData(ofTypes: types, modifiedSince: .distantPast) { continuation.resume() }
        }
    }
}


struct PortalWebView: UIViewRepresentable {
    let url: URL
    @ObservedObject var session: SecureSession
    final class Coordinator: NSObject, WKScriptMessageHandler {
        weak var session: SecureSession?
        init(session: SecureSession) { self.session = session }
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.frameInfo.isMainFrame, message.frameInfo.securityOrigin.host == "imamhatipliyiz.com.tr", let code = message.body as? String else { return }
            Task { @MainActor [weak self] in await self?.session?.exchangeWebSession(code: code) }
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(session: session) }
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.userContentController.add(context.coordinator, name: "ihSession")
        // Hide only the website's duplicate fixed bottom navigation inside iOS.
        // The native SwiftUI TabView remains visible and functional.
        let script = #"""
        (function () {
          const expected = ['ana sayfa', 'hizmetler', 'katılım', 'ara', 'hesabım'];
          const normalize = s => (s || '').toLocaleLowerCase('tr-TR').replace(/\s+/g, ' ').trim();
          function hideDuplicateNavigation() {
            const candidates = document.querySelectorAll('nav, [role="navigation"], footer, div, section');
            for (const node of candidates) {
              if (node.dataset && node.dataset.ihIosHiddenNav === '1') continue;
              const text = normalize(node.innerText);
              if (text.length > 180 || !expected.every(label => text.includes(label))) continue;
              const rect = node.getBoundingClientRect();
              const style = window.getComputedStyle(node);
              if (rect.width < window.innerWidth * 0.65 || rect.height > 150 || rect.height < 35) continue;
              if (!['fixed', 'sticky'].includes(style.position)) continue;
              if (rect.bottom < window.innerHeight - 170) continue;
              node.style.setProperty('display', 'none', 'important');
              node.dataset.ihIosHiddenNav = '1';
            }
          }
          if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', hideDuplicateNavigation);
          } else { hideDuplicateNavigation(); }
          window.addEventListener('load', hideDuplicateNavigation);
          let queued = false;
          const observer = new MutationObserver(() => {
            if (queued) return;
            queued = true;
            requestAnimationFrame(() => { queued = false; hideDuplicateNavigation(); });
          });
          observer.observe(document.documentElement, {childList: true, subtree: true});
        })();
        """#
        config.userContentController.addUserScript(
            WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        )
        // Same-origin cookie authentication -> one-time code -> native Keychain.
        // Never expose the native bearer token to JavaScript.
        let bridge = #"""
        (() => {
          if (location.origin !== 'https://imamhatipliyiz.com.tr') return;
          if (window.__ihBridgeStarted) return;
          window.__ihBridgeStarted = true;
          const root = '/wp-json/ih-ios/v1/';
          async function sync() {
            try {
              const n = await fetch(root+'bridge-nonce', {credentials:'same-origin', cache:'no-store'});
              if (!n.ok) return;
              const nonce = (await n.json()).nonce;
              if (!nonce) return;
              const r = await fetch(root+'web-bridge', {
                method:'POST', credentials:'same-origin', cache:'no-store',
                headers:{'Content-Type':'application/json','X-IHM-CSRF':nonce},
                body:'{}'
              });
              if (!r.ok) return;
              const code = (await r.json()).code;
              if (/^[a-f0-9]{48}$/.test(code || '')) window.webkit.messageHandlers.ihSession.postMessage(code);
            } catch (_) {}
          }
          // The membership login reloads the page on success.
          // One attempt per document, preventing repeated code generation.
          if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', sync, {once:true});
          else sync();
        })();
        """#
        config.userContentController.addUserScript(WKUserScript(source: bridge, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        let web = WKWebView(frame: .zero, configuration: config)
        web.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1 IH-iOS-App/1"
        web.allowsBackForwardNavigationGestures = true
        web.load(URLRequest(url: url))
        return web
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct HomeView: View {
    @EnvironmentObject var session: SecureSession
    private let base = URL(string: "https://imamhatipliyiz.com.tr")!
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    @State private var services: [SchoolService] = []
    @State private var status = "Servisler yükleniyor…"
    var body: some View {
        TabView {
            NavigationStack {
                // Show the live WordPress homepage on app launch, rather than the
                // native API-dependent service dashboard.
                PortalWebView(url: base, session: session)
                    .toolbar(.hidden, for: .navigationBar)
            }.tabItem { Label("Ana Sayfa", systemImage: "house") }
            NavigationStack {
                PortalWebView(url: base, session: session)
                    .toolbar(.hidden, for: .navigationBar)
            }.tabItem { Label("Portal", systemImage: "square.grid.2x2") }
            NavigationStack {
                StaffMessagesView()
            }.tabItem { Label("Mesajlar", systemImage: "message") }
            NavigationStack {
                NativeProfileView()
            }.tabItem { Label("Profilim", systemImage: "person.crop.circle") }
        }.tint(.teal)
    }
    private func serviceCard(_ item: SchoolService) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: (item.status == "web_active" || item.status == "native_active" || item.status == "login_required") ? "checkmark.circle" : "clock")
                .foregroundStyle((item.status == "web_active" || item.status == "native_active" || item.status == "login_required") ? .green : .secondary)
            Text(item.title).font(.headline).foregroundStyle(.primary)
            Text(item.status == "coming_soon" ? "Yakında" : (item.status == "web_active" || item.status == "native_active" || item.status == "login_required" ? "Aç" : "Geliştiriliyor"))
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 105, alignment: .leading)
        .padding(12).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
    private func load() async {
        do {
            services = try await APIClient.shared.services().items
            status = "Üyelik mevcut portal üzerinden çalışır. Diğer modüller aşamalı olarak bağlanacak."
        } catch {
            status = "Hizmet listesi şu anda yüklenemiyor. Portal sekmesinden hizmetlere ulaşabilirsiniz."
            #if DEBUG
            print("İmam Hatipliyiz services API error: \(error)")
            #endif
        }
    }
}
