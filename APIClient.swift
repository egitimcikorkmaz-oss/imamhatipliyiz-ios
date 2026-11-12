import Foundation

struct HealthResponse: Decodable { let status: String; let api_version: String }
struct ServiceResponse: Decodable { let items: [SchoolService] }
struct SchoolService: Decodable, Identifiable {
    let id: String
    let title: String
    let status: String
    let path: String?
}

struct APIClient {
    static let shared = APIClient()
    private let base = URL(string: "https://imamhatipliyiz.com.tr/wp-json/ih-ios/v1/")!

    func nativeEvents() async throws -> NativeEventsResponse { try await request("events-native") }
    func health() async throws -> HealthResponse {
        try await request("health")
    }
    func services() async throws -> ServiceResponse {
        try await request("services")
    }
    private func request<T: Decodable>(_ path: String) async throws -> T {
        let url = base.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
