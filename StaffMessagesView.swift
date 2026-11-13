import SwiftUI

// Messaging is restricted by the server to approved school staff.
struct StaffMessagesView: View {
    @EnvironmentObject private var session: SecureSession
    @State private var peerText = ""
    @State private var draft = ""
    @State private var items: [MobileMessage] = []
    @State private var notice = ""
    @State private var busy = false
    private var peer: Int? { Int(peerText.trimmingCharacters(in: .whitespacesAndNewlines)) }
    private var isStaff: Bool { ["ogretmen", "yonetici"].contains(session.profile?.verified_role ?? "") }

    var body: some View {
        Group {
            if !session.loggedIn {
                ContentUnavailableView("Giriş gerekli", systemImage: "lock", description: Text("Önce Profilim bölümünden web hesabınızla giriş yapın."))
            } else if !isStaff {
                ContentUnavailableView("Mesajlaşma yetkisi yok", systemImage: "person.crop.circle.badge.xmark", description: Text("Mesajlaşma yalnızca okul tarafından onaylanmış personel hesaplarına açıktır."))
            } else {
                VStack(spacing: 12) {
                    TextField("Alıcının üye numarası", text: $peerText).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                    Button("Mesajları getir") { Task { await load() } }.disabled(peer == nil || busy)
                    List(items) { message in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(message.sender_id == session.profile?.id ? "Ben" : "Üye #\(message.sender_id)").font(.caption).foregroundStyle(.secondary)
                            Text(message.body)
                        }
                    }
                    HStack {
                        TextField("Mesajınız", text: $draft, axis: .vertical).lineLimit(1...4).textFieldStyle(.roundedBorder)
                        Button("Gönder") { Task { await send() } }.disabled(peer == nil || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || busy)
                    }
                    if !notice.isEmpty { Text(notice).font(.caption).foregroundStyle(.secondary) }
                }.padding()
            }
        }
        .navigationTitle("Mesajlar")
        .task { await session.refresh() }
    }
    @MainActor private func load() async {
        guard let peer else { return }; busy = true; defer { busy = false }
        do { items = Array(try await session.messages(peer: peer).reversed()); notice = "" }
        catch { notice = error.localizedDescription }
    }
    @MainActor private func send() async {
        guard let peer else { return }; busy = true; defer { busy = false }
        do {
            try await session.send(to: peer, body: draft.trimmingCharacters(in: .whitespacesAndNewlines))
            draft = ""; items = Array(try await session.messages(peer: peer).reversed()); notice = ""
        } catch { notice = error.localizedDescription }
    }
}
