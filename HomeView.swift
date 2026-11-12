import SwiftUI
import WebKit

struct PortalWebView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        let web = WKWebView(frame: .zero, configuration: config)
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
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("İmam Hatipliyiz").font(.largeTitle.bold())
                            Text("Çayırova Kız Anadolu İmam Hatip Lisesi")
                            Text("Yeniden İmam Hatip Ruhu ve Şuuru ile")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(22).foregroundStyle(.white)
                        .background(Color(red: 0.06, green: 0.25, blue: 0.31), in: RoundedRectangle(cornerRadius: 20))
                        Text("Dijital Okul Hizmetleri").font(.title2.bold())
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(services) { service in
                                if service.id == "etkinlik" {
                                    NavigationLink { SchoolEventsView() } label: { serviceCard(service) }
                                } else if service.id == "basvur" {
                                    NavigationLink { NativeRequestsView() } label: { serviceCard(service) }
                                } else if service.status == "native_active" && service.id == "hadis" {
                                    NavigationLink { WeeklyHadithView() } label: { serviceCard(service) }
                                } else if service.status == "web_active", let path = service.path, !path.isEmpty,
                                   let url = URL(string: path, relativeTo: base)?.absoluteURL {
                                    NavigationLink {
                                        PortalWebView(url: url).navigationTitle(service.title).navigationBarTitleDisplayMode(.inline)
                                    } label: { serviceCard(service) }
                                } else { serviceCard(service) }
                            }
                        }
                        Text("Rehberlik ve öğrenci kayıtları için portal yetkilendirmesi gereklidir. Web oturumu iOS API oturumundan ayrıdır.").font(.caption).foregroundStyle(.secondary)
                        Text(status).font(.caption).foregroundStyle(.secondary)
                    }.padding()
                }.navigationTitle("Ana Sayfa").task { await load() }
            }.tabItem { Label("Ana Sayfa", systemImage: "house") }
            NavigationStack {
                PortalWebView(url: base).navigationTitle("Okul Portalı")
            }.tabItem { Label("Portal", systemImage: "square.grid.2x2") }
            NavigationStack {
                StaffMessagesView()
            }.tabItem { Label("Mesajlar", systemImage: "message") }
            NavigationStack {
                MemberLoginView()
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
        } catch { status = "API bağlantısı kurulamadı. Sunucu ve eklentiyi kontrol edin." }
    }
}
