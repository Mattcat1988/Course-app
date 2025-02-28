import SwiftUI

struct ContentView: View {
    @ObservedObject var parser: ExchangeRateParser  // Теперь parser передаётся

    var body: some View {
        ScrollView {
            VStack {
                // Дата обновления курса
                if !parser.lastUpdated.isEmpty {
                    Text(parser.lastUpdated)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                }

                if parser.exchangeRates.isEmpty {
                    Text("Загрузка курса...")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(parser.currencyNames.keys.sorted(), id: \.self) { currency in
                        if let rate = parser.exchangeRates[currency] {
                            let previousRate = parser.previousRates[currency] ?? rate
                            let rateChange = rate - previousRate
                            let changeSymbol = rateChange > 0 ? "🔼" : (rateChange < 0 ? "🔽" : "➡️")
                            let changeColor = rateChange > 0 ? Color.green : (rateChange < 0 ? Color.red : Color.gray)

                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(parser.currencyNames[currency] ?? currency) (\(currency))")
                                        .font(.headline)
                                    Text("Текущий: \(rate, specifier: "%.2f") ₽")
                                        .font(.subheadline)
                                    Text("Предыдущий: \(previousRate, specifier: "%.2f") ₽")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text(changeSymbol)
                                    .font(.title)
                                    .foregroundColor(changeColor)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).shadow(radius: 3))
                            .padding(.horizontal)
                            .animation(.easeInOut(duration: 0.3), value: rate)
                        }
                    }
                }
            }
            .padding(.top)
        }
        .background(Color.gray.opacity(0.2))
        .onAppear {
            parser.fetchExchangeRates() // Теперь вызываем метод из parser
        }
    }
}
