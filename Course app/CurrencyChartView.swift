import SwiftUI
import Charts

struct CurrencyChartView: View {
    var currency: String
    var history: [String: Double]

    var body: some View {
        VStack {
            if history.isEmpty {
                Text("Нет данных для отображения графика")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                Chart {
                    ForEach(history.sorted(by: { $0.key < $1.key }), id: \.key) { entry in
                        LineMark(
                            x: .value("Дата", entry.key), // Передача даты как строки
                            y: .value("Курс", entry.value)
                        )
                    }
                }
                .frame(height: 300)
                .padding()
            }
        }
    }
}
