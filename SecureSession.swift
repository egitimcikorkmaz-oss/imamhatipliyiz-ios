import SwiftUI
import Foundation
import Security

struct MobileLoginResponse: Decodable {
    let token: String
    let expires_in: Int
    let member_id: Int
    let role: String
}
struct MobileProfile: Decodable {
    let id: Int
    let verified_role: String
    let school_verified: Bool
}
struct MobileMessage: Decodable, Identifiable {
    let id: Int
    let sender_id: Int
    let recipient_id: Int
    let body: String
    let created: Int
}
struct MobileMessagesResponse: Decodable { let items: [MobileMessage] }

@MainActor final class SecureSession: ObservableObject {
    @Published var profile: MobileProfile?
    @Published var errorText: String?
    @Published var isBusy = false
    private let base = URL(string: "https://imamhatipliyiz.com.tr/wp-json/ih-ios/v1/")!
    private let key = "tr.com.imamhatipliyiz.app.mobile-token"

    var loggedIn: Bool { profile != nil }
    private var token: String? {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key, kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne]
        var result: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    private func save(_ value: String) {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrAccount as String: key]
        SecItemDelete(q as CFDictionary)
        let attrs: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key, kSecValueData as String: Data(value.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        SecItemAdd(attrs as CFDictionary, nil)
    }
    private func clear() {
        SecItemDelete([kSecClass as String: kSecClassGenericPassword, kSecAttrAccount as String: key] as CFDictionary)
        profile = nil
    }
    private func call<T: Decodable>(_ path: String, method: String = "GET", payload: [String: Any]? = nil, authorized: Bool = true) async throws -> T {
        let parts = path.split(separator: "?", maxSplits: 1)
        var url = base.appendingPathComponent(String(parts[0]))
        if parts.count > 1, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.percentEncodedQuery = String(parts[1]); url = components.url ?? url
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if authorized, let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let payload {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
            throw NSError(domain: "ImamHatipliyiz", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message ?? "İşlem tamamlanamadı."])
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
    func login(identity: String, password: String) async {
        isBusy = true; defer { isBusy = false }
        do {
            let result: MobileLoginResponse = try await call("login", method: "POST", payload: ["identity": identity, "password": password], authorized: false)
            save(result.token)
            await refresh()
        } catch { errorText = error.localizedDescription }
    }
    func refresh() async {
        guard token != nil else { profile = nil; return }
        do { profile = try await call("me") }
        catch { clear(); errorText = error.localizedDescription }
    }
    func logout() async {
        if token != nil { let _: [String: Bool]? = try? await call("logout", method: "POST") }
        clear()
    }
    func nativeRequests() async throws -> NativeRequestsResponse { try await call("requests-native") }
    func nativeCategories() async throws -> NativeCategoriesResponse { try await call("request-categories") }
    func submitNativeRequest(_ payload: [String: Any]) async throws -> NativeSubmitResponse {
        try await call("requests-native", method: "POST", payload: payload)
    }
    func messages(peer: Int) async throws -> [MobileMessage] {
        let response: MobileMessagesResponse = try await call("messages?peer=\(peer)")
        return response.items
    }
    func send(to peer: Int, body: String) async throws {
        let _: [String: JSONValue] = try await call("messages", method: "POST", payload: ["recipient_id": peer, "body": body])
    }
}
// Minimal JSON scalar decoder for acknowledgement responses.
enum JSONValue: Decodable { case string(String), bool(Bool), int(Int)
    init(from decoder: Decoder) throws { let c = try decoder.singleValueContainer(); if let b = try? c.decode(Bool.self) { self = .bool(b) } else if let i = try? c.decode(Int.self) { self = .int(i) } else { self = .string(try c.decode(String.self)) } }
}
