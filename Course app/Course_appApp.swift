//
//  Course_appApp.swift
//  Course app
//
//  Created by 1234 on 26.02.2025.
//

import SwiftUI

@main
struct Course_appApp: App {
    @StateObject private var parser = ExchangeRateParser() // Создаём один экземпляр на всё приложение

    var body: some Scene {
        WindowGroup {
            ContentView(parser: parser)
                .frame(width: 300, height: 400) // Фиксируем размер окна
        }
        .windowResizability(.contentSize) // Запрет изменения размера окна
    }
}
