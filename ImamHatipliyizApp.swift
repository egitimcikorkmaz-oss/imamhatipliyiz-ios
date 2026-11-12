import SwiftUI

@main
struct ImamHatipliyizApp: App {
    @StateObject private var session = SecureSession()
    var body: some Scene {
        WindowGroup { HomeView().environmentObject(session) }
    }
}
