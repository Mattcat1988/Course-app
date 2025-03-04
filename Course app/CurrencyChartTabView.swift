import SwiftUI

struct CurrencyChartTabView: View {
    @ObservedObject var parser: ExchangeRateParser
    @State private var selectedCurrency: String = ""

    var availableCurrencies: [String] {
        parser.exchangeRates.keys.sorted().filter { parser.currencyNames.keys.contains($0) }
    }

    var body: some View {
        VStack {
            Picker("Выберите валюту", selection: $selectedCurrency) {
                ForEach(availableCurrencies, id: \.self) { currency in
                    Text(parser.currencyNames[currency] ?? currency).tag(currency)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()

            if let history = parser.exchangeHistory[selectedCurrency], !history.isEmpty {
                CurrencyChartView(currency: selectedCurrency, history: history)
            } else {
                Text("Нет данных для отображения графика")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .onAppear {
            updateSelectedCurrency()
        }
        .onChange(of: parser.exchangeRates) {
            updateSelectedCurrency()
        }
    }

    private func updateSelectedCurrency() {
        if selectedCurrency.isEmpty || !availableCurrencies.contains(selectedCurrency) {
            selectedCurrency = availableCurrencies.first ?? "USD"
        }
    }
}
