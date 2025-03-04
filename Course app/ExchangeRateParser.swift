import SwiftUI
import Foundation

class ExchangeRateParser: NSObject, XMLParserDelegate, ObservableObject {
    @Published var exchangeRates: [String: Double] = [:]
    @Published var previousRates: [String: Double] = [:]
    @Published var lastUpdated: String = ""
    @Published var exchangeHistory: [String: [String: Double]] = [:]

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

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                print("Ошибка загрузки: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            Task { @MainActor in
                await self.parse(data: data)
            }
        }.resume()
    }
    
    func saveHistoryToJSON() {
        let fileURL = getDocumentsDirectory().appendingPathComponent("exchangeHistory.json")
        do {
            let jsonData = try JSONEncoder().encode(exchangeHistory)
            try jsonData.write(to: fileURL)
        } catch {
            print("Ошибка сохранения истории курсов: \(error)")
        }
    }

    func loadHistoryFromJSON() {
        let fileURL = getDocumentsDirectory().appendingPathComponent("exchangeHistory.json")
        do {
            let jsonData = try Data(contentsOf: fileURL)
            exchangeHistory = try JSONDecoder().decode([String: [String: Double]].self, from: jsonData)
        } catch {
            print("Ошибка загрузки истории курсов: \(error)")
        }
    }

    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
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

                    let date = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
                    if self.exchangeHistory[date] == nil {
                        self.exchangeHistory[date] = [:]
                    }
                    self.exchangeHistory[date]?[currency] = rate
                }
            }
        }
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    func predictFutureRates(for currency: String, daysAhead: Int = 7) -> [String: Double] {
        let sortedHistory = exchangeHistory
            .compactMapValues { $0[currency] }
            .sorted(by: { $0.key < $1.key })

        let history = sortedHistory.map { $0.value }
        guard history.count > 1 else { return [:] }

        let x = (0..<history.count).map { Double($0) }
        let y = history
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)

        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n

        var futureRates: [String: Double] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"

        for i in 1...daysAhead {
            let futureDate = Calendar.current.date(byAdding: .day, value: i, to: Date())!
            let futureDateString = formatter.string(from: futureDate)
            let predictedValue = intercept + slope * Double(history.count + i)
            futureRates[futureDateString] = predictedValue
        }

        return futureRates
    }
}
