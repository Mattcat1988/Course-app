import SwiftUI
import Foundation

class ExchangeRateParser: NSObject, XMLParserDelegate, ObservableObject {
    @Published var exchangeRates: [String: Double] = [:]
    @Published var previousRates: [String: Double] = [:]
    @Published var lastUpdated: String = ""

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

    func fetchExchangeRates() {
        guard let url = URL(string: "https://www.cbr.ru/scripts/XML_daily.asp") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Ошибка загрузки: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            Task {
                await self.parse(data: data)
            }
        }.resume()
    }

    func parse(data: Data) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        DispatchQueue.main.async {
            self.lastUpdated = "Обновлено: \(formatter.string(from: Date()))"
        }

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
