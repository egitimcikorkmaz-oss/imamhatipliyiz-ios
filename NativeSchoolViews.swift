import SwiftUI

struct NativeEvent: Decodable, Identifiable {
    let id: Int
    let title: String
    let date: String
    let time: String
    let place: String
    let description: String
    let category: String
    let image: String?
}
struct NativeEventsResponse: Decodable { let items: [NativeEvent]; let available: Bool }
struct NativeRequest: Decodable, Identifiable {
    let id: Int
    let category: String
    let status: String
    let created_at: String
    let admin_note: String
}
struct NativeRequestsResponse: Decodable { let items: [NativeRequest] }
struct NativeCategoriesResponse: Decodable { let items: [String] }
struct NativeSubmitResponse: Decodable { let ok: Bool; let id: Int; let message: String; let sms_status: String }

struct SchoolEventsView: View {
    @State private var events: [NativeEvent] = []
    @State private var error: String?
    var body: some View {
        List {
            if let error { Text(error).foregroundStyle(.red) }
            ForEach(events) { event in
                NavigationLink {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            if let image = event.image, let url = URL(string: image), url.scheme == "https" {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image { image.resizable().scaledToFit() }
                                    else { Color.gray.opacity(0.1).frame(height: 120) }
                                }
                            }
                            Text(event.title).font(.title2.bold())
                            Label(event.date.isEmpty ? "Tarih belirlenecek" : event.date, systemImage: "calendar")
                            if !event.time.isEmpty { Label(event.time, systemImage: "clock") }
                            if !event.place.isEmpty { Label(event.place, systemImage: "mappin") }
                            Text(event.description).font(.body)
                            Text("Etkinlik başvurusu ve yönetici onayı mevcut okul portalında yürütülür.").font(.caption).foregroundStyle(.secondary)
                        }.padding()
                    }.navigationTitle("Etkinlik Detayı")
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(event.category.isEmpty ? "Okul Etkinliği" : event.category).font(.caption).foregroundStyle(.teal)
                        Text(event.title).font(.headline)
                        Text(event.date.isEmpty ? "Tarih belirlenecek" : event.date).font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 5)
                }
            }
        }.navigationTitle("Okul Etkinlikleri")
         .overlay { if events.isEmpty && error == nil { ContentUnavailableView("Etkinlik bulunamadı", systemImage: "calendar") } }
         .refreshable { await load() }.task { await load() }
    }
    private func load() async {
        do { let result: NativeEventsResponse = try await APIClient.shared.nativeEvents(); events = result.items; if !result.available { error = "Okul Etkinlikleri eklentisi etkin değil." } }
        catch { self.error = error.localizedDescription }
    }
}

struct NativeRequestsView: View {
    @EnvironmentObject var session: SecureSession
    @State private var requests: [NativeRequest] = []
    @State private var error: String?
    @State private var showingForm = false
    var body: some View {
        Group {
            if !session.loggedIn {
                ContentUnavailableView("Üye girişi gerekli", systemImage: "lock.shield", description: Text("Başvurularınızı güvenli biçimde görmek için okul tarafından onaylanmış hesabınızla giriş yapın."))
            } else {
                List {
                    if let error { Text(error).foregroundStyle(.red) }
                    ForEach(requests) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Başvuru #\(item.id) · \(item.category)").font(.headline)
                            Text("Durum: \(statusName(item.status))")
                            Text(item.created_at).font(.caption).foregroundStyle(.secondary)
                            if !item.admin_note.isEmpty { Text("Yönetici açıklaması: \(item.admin_note)").font(.subheadline) }
                        }.padding(.vertical, 5)
                    }
                }.refreshable { await load() }
                 .toolbar { Button { showingForm = true } label: { Label("Yeni Başvuru", systemImage: "plus") } }
                 .sheet(isPresented: $showingForm, onDismiss: { Task { await load() } }) { NavigationStack { NewNativeRequestView() } }
            }
        }.navigationTitle("Başvur / Sonuç Al").task { await load() }
    }
    private func statusName(_ value: String) -> String {
        ["new":"Başvuru Alındı", "review":"Değerlendiriliyor", "resolved":"Çözüldü", "closed":"Sonuçlandırıldı"][value] ?? value
    }
    private func load() async {
        guard session.loggedIn else { return }
        do { requests = try await session.nativeRequests().items; error = nil }
        catch { self.error = error.localizedDescription }
    }
}

struct NewNativeRequestView: View {
    @EnvironmentObject var session: SecureSession
    @Environment(\.dismiss) private var dismiss
    @State private var categories: [String] = []
    @State private var category = ""
    @State private var applicantType = "parent"
    @State private var fullname = ""
    @State private var phone = ""
    @State private var studentName = ""
    @State private var className = ""
    @State private var message = ""
    @State private var consent = false
    @State private var busy = false
    @State private var result: String?
    var body: some View {
        Form {
            Section("Başvuru Bilgileri") {
                Picker("Başvuru Türü", selection: $applicantType) {
                    Text("Veli").tag("parent"); Text("Öğrenci").tag("student"); Text("Diğer").tag("other")
                }
                Picker("Konu", selection: $category) {
                    Text("Seçiniz").tag("")
                    ForEach(categories, id: \.self) { Text($0).tag($0) }
                }
                TextField("Ad Soyad", text: $fullname).textContentType(.name)
                TextField("Cep telefonu (05XXXXXXXXX)", text: $phone).keyboardType(.phonePad)
                if applicantType == "student" {
                    TextField("Öğrenci Adı Soyadı", text: $studentName)
                    TextField("Sınıf / Şube", text: $className)
                }
                TextField("Talep veya öneriniz (en az 10 karakter)", text: $message, axis: .vertical).lineLimit(5...10)
            }
            Section {
                Toggle("Kişisel verilerimin başvurunun değerlendirilmesi için işlenmesine ilişkin aydınlatma metnini okudum.", isOn: $consent)
                Link("Aydınlatma metni", destination: URL(string: "https://imamhatipliyiz.com.tr/gizlilik-politikasi/")!)
            }
            if let result { Section("İşlem Sonucu") { Text(result) } }
            Section {
                Button(busy ? "Gönderiliyor…" : "Başvuruyu Gönder") { Task { await submit() } }
                    .disabled(busy || !consent || category.isEmpty || fullname.count < 3 || message.count < 10)
            }
        }.navigationTitle("Yeni Başvuru")
         .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Kapat") { dismiss() } } }
         .task { do { categories = try await session.nativeCategories().items } catch { result = error.localizedDescription } }
    }
    private func submit() async {
        busy = true; defer { busy = false }
        do {
            let response = try await session.submitNativeRequest([
                "applicant_type":applicantType,"category":category,"fullname":fullname,"phone":phone,
                "student_name":studentName,"class_name":className,"message":message,"consent":consent
            ])
            result = "Başvurunuz kaydedildi. Takip numarası: #\(response.id). SMS gönderilmedi."
        } catch { result = "Başvuru kaydedilemedi: \(error.localizedDescription)" }
    }
}
