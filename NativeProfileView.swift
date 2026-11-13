import SwiftUI

struct NativeProfileView: View {
    @EnvironmentObject private var session: SecureSession
    var body: some View {
        VStack(spacing: 16) {
            if let profile = session.profile {
                Image(systemName: "person.crop.circle.fill").font(.system(size: 55)).foregroundStyle(.teal)
                Text("Üyelik numarası: \(profile.id)").font(.headline)
                Text("Onaylı rol: \(profile.verified_role)")
                Text("Hesabınız İmam Hatipliyiz üyelik sistemiyle bağlantılıdır.").multilineTextAlignment(.center)
                Button("Güvenli çıkış yap") { Task { await session.logout() } }.buttonStyle(.borderedProminent)
            } else {
                Text("Web üyeliğinizle giriş yapın.").font(.headline)
                MemberLoginView().frame(maxHeight: .infinity)
            }
            if let error = session.errorText { Text(error).font(.caption).foregroundStyle(.red) }
        }.padding()
        .task { await session.refresh() }
    }
}
