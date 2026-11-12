import SwiftUI
struct MemberLoginView: View {
    @EnvironmentObject var session: SecureSession
    @State private var identity = ""
    @State private var password = ""
    var body: some View {
        Form {
            if let profile = session.profile {
                Section("Onaylı okul üyeliği") {
                    Label("Üye numarası: \(profile.id)", systemImage: "checkmark.shield")
                    Text("Doğrulanmış rol: \(profile.verified_role)")
                    Button("Güvenli çıkış") { Task { await session.logout() } }
                }
            } else {
                Section("Mevcut İmam Hatipliyiz hesabınız") {
                    TextField("E-posta veya telefon", text: $identity)
                        .textContentType(.username).textInputAutocapitalization(.never)
                    SecureField("Şifre", text: $password).textContentType(.password)
                    Button(session.isBusy ? "Giriş yapılıyor…" : "Giriş Yap") {
                        Task { await session.login(identity: identity, password: password); password = "" }
                    }.disabled(session.isBusy || identity.isEmpty || password.isEmpty)
                }
                Section { Text("iOS erişimi için okul yönetimi onayı gereklidir. Üyelik kaydınız mevcut web portalında oluşturulur.") }
            }
            if let error = session.errorText { Section { Text(error).foregroundStyle(.red) } }
        }.navigationTitle("Üyelik Girişi").task { await session.refresh() }
    }
}
