import SwiftUI
import Charts

struct CurrencyChartView: View {
    let currency: String
    let history: [String: Double]

    var body: some View {
        VStack {
            Text("Динамика курса \(currency)")
                .font(.headline)

            Chart {
                ForEach(sortedHistory(), id: \.0) { date, value in
                    LineMark(
                        x: .value("Дата", date),
                        y: .value("Курс", value)
                    )
                }
            }
            .frame(height: 200)
            .padding()
        }
    }

    // 🔹 Сортировка и конвертация дат
    private func sortedHistory() -> [(Date, Double)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"

        return history.compactMap { (dateString, value) in
            if let date = formatter.date(from: dateString) {
                return (date, value)
            }
            return nil
        }
        .sorted { $0.0 < $1.0 }
    }
}
