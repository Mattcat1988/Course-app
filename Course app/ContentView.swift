import SwiftUI

struct ContentView: View {
    @ObservedObject var parser: ExchangeRateParser  // Теперь parser передаётся

    var body: some View {
        TabView {
            ExchangeRateListView(parser: parser)
                .tabItem {
                    Label("Курсы", systemImage: "dollarsign.circle")
                }

            CurrencyChartTabView(parser: parser)
                .tabItem {
                    Label("График", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .onAppear {
            parser.fetchExchangeRates() // Автоматическая загрузка данных
        }
    }
}
