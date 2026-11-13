import SwiftUI
import WebKit

// The independent IHM_Auth account is authenticated by the existing WordPress
// membership page. All PortalWebView instances use WKWebsiteDataStore.default(),
// so the same secure HttpOnly session cookie is shared across tabs.
struct MemberLoginView: View {
    @EnvironmentObject var session: SecureSession
    private let membershipURL = URL(string: "https://imamhatipliyiz.com.tr/uye-girisi/")!

    var body: some View {
        PortalWebView(url: membershipURL, session: session)
            .toolbar(.hidden, for: .navigationBar)
    }
}
