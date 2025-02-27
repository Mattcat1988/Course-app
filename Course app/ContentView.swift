import SwiftUI
import Foundation

struct ContentView: View {
    @StateObject private var parser = ExchangeRateParser()

    var body: some View {
        ScrollView {
            VStack {
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
        .background(Color.gray.opacity(0.2)) // Светло-серый фон
        .onAppear {
            fetchExchangeRates()
        }
    }

    func fetchExchangeRates() {
        let url = URL(string: "https://www.cbr.ru/scripts/XML_daily.asp")!
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Ошибка загрузки: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            Task {
                await parser.parse(data: data)
            }
        }.resume()
    }
}

class ExchangeRateParser: NSObject, XMLParserDelegate, ObservableObject {
    @Published var exchangeRates: [String: Double] = [:]
    @Published var previousRates: [String: Double] = [:]

    let currencyNames: [String: String] = [
        "USD": "Доллар США",
        "EUR": "Евро",
        "CNY": "Китайский юань",
        "GBP": "Фунт стерлингов",
        "JPY": "Японская иена",
        "PLN": "Польский злотый",
        "CZK": "Чешская крона",
        "TRY": "Турецкая лира",
        "INR": "Индийская рупия",
    ]

    private var currentCurrencyCode: String?
    private var currentValue: String = ""

    func parse(data: Data) async {
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = self
        xmlParser.parse()
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
        if elementName == "Valute" {
            currentCurrencyCode = nil
        } else if elementName == "CharCode" || elementName == "Value" {
            currentValue = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "CharCode" {
            currentCurrencyCode = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if elementName == "Value", let currency = currentCurrencyCode {
            let cleanedValue = currentValue.replacingOccurrences(of: ",", with: ".")
            if let rate = Double(cleanedValue) {
                DispatchQueue.main.async {
                    if let previousRate = self.exchangeRates[currency] {
                        self.previousRates[currency] = previousRate
                    }
                    self.exchangeRates[currency] = rate
                }
            }
        }
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}
