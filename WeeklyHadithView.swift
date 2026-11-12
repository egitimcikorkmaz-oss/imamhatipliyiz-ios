import SwiftUI

private struct HadithResponse: Decodable {
    let available: Bool
    let message: String?
    let hadith: WeeklyHadith?
}
private struct WeeklyHadith: Decodable {
    let id: Int
    let arabic: String?
    let turkish: String
    let source: String
    let note: String?
    let closes_at: String
}

struct WeeklyHadithView: View {
    @State private var hadith: WeeklyHadith?
    @State private var notice = "Haftanın hadisi yükleniyor…"
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Haftanın Hadis-i Şerifi").font(.title.bold())
                Text("Peygamberimin Sözü, Hayatımda İzi").foregroundStyle(.secondary)
                if let h = hadith {
                    if let ar = h.arabic, !ar.isEmpty {
                        Text(ar).font(.title2).multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    Text(h.turkish).font(.title3)
                    Text(h.source).font(.subheadline).foregroundStyle(.secondary)
                    if let note = h.note, !note.isEmpty { Text(note) }
                    Text("Son katılım: \(h.closes_at)").font(.caption)
                    Text("Ezberledim başvurusu, mevcut web sistemindeki veli onayı ve kontrollerle yapılır.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text("Başvuru için portalda Haftanın Hadisi sayfasını kullanın.").font(.footnote)
                } else { Text(notice).foregroundStyle(.secondary) }
            }.padding()
        }.navigationTitle("Haftanın Hadisi").task { await load() }
    }
    private func load() async {
        guard let url = URL(string: "https://imamhatipliyiz.com.tr/wp-json/ih-ios/v1/hadith-current") else { return }
        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            let result = try JSONDecoder().decode(HadithResponse.self, from: data)
            hadith = result.hadith
            notice = result.message ?? "Henüz aktif hadis yok."
        } catch { notice = "Hadis bilgisi alınamadı. Bağlantınızı kontrol edin." }
    }
}
