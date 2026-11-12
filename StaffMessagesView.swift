import SwiftUI
struct StaffMessagesView: View {
    @EnvironmentObject var session: SecureSession
    @State private var peer = ""
    @State private var bodyText = ""
    @State private var messages: [MobileMessage] = []
    @State private var notice = ""
    var body: some View {
        Group {
            if session.profile == nil {
                ContentUnavailableView("Üye girişi gerekli", systemImage: "lock.shield", description: Text("Mesajlar yalnızca okul tarafından doğrulanmış öğretmen ve yöneticilere açıktır."))
            } else if !["ogretmen", "yonetici"].contains(session.profile?.verified_role ?? "") {
                ContentUnavailableView("Kontrollü iletişim", systemImage: "shield", description: Text("Öğrenci ve veli mesajlaşması okul güvenliği kuralları tamamlanana kadar kapalıdır."))
            } else {
                Form {
                    Section("Alıcı") {
                        TextField("Doğrulanmış personel üye numarası", text: $peer).keyboardType(.numberPad)
                        Button("Konuşmayı görüntüle") { Task { await load() } }
                    }
                    Section("Mesajlar") {
                        ForEach(messages) { msg in
                            VStack(alignment: .leading) {
                                Text(msg.sender_id == session.profile?.id ? "Ben" : "Diğer personel").font(.caption).foregroundStyle(.secondary)
                                Text(msg.body)
                            }
                        }
                    }
                    Section("Yeni mesaj") {
                        TextField("Mesaj", text: $bodyText, axis: .vertical)
                        Button("Gönder") { Task {
                            guard let id = Int(peer) else { return }
                            do { try await session.send(to: id, body: bodyText); bodyText = ""; await load() }
                            catch { notice = error.localizedDescription }
                        }}.disabled(bodyText.isEmpty || Int(peer) == nil)
                    }
                    if !notice.isEmpty { Text(notice).foregroundStyle(.red) }
                }
            }
        }.navigationTitle("Personel Mesajları")
    }
    private func load() async {
        guard let id = Int(peer) else { return }
        do { messages = try await session.messages(peer: id); notice = "" }
        catch { notice = error.localizedDescription }
    }
}
