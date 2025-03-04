import SwiftUI

@main
struct Course_appApp: App {
    @StateObject private var parser = ExchangeRateParser() // Создаём один экземпляр на всё приложение

    var body: some Scene {
        WindowGroup {
            ContentView(parser: parser)
                .frame(minWidth: 400, minHeight: 400) // Минимальный размер окна
        }
        .windowResizability(.contentSize)
    }
}
