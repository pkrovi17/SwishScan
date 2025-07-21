import SwiftUI
import UIKit
import HorizonCalendar

struct WorkoutCalendarView: View {
    let markedDates: Set<Date>  // Your workout dates

    @State private var selectedDate: Date? = nil
    @State private var isSheetPresented = false

    var body: some View {
        HorizonCalendarWrapper(markedDates: markedDates) { date in
            selectedDate = date
            isSheetPresented = true
        }
        .sheet(isPresented: $isSheetPresented) {
            if let selectedDate = selectedDate {
                VStack(spacing: 20) {
                    Text("You clicked on:")
                    Text(dateFormatter.string(from: selectedDate))
                        .bold()
                        .font(.title2)
                }
                .padding()
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .long
        return df
    }
}

struct HorizonCalendarWrapper: UIViewRepresentable {
    let markedDates: Set<Date>
    let onDateTap: (Date) -> Void

    func makeUIView(context: Context) -> CalendarView {
        CalendarView(initialContent: makeContent())
    }

    func updateUIView(_ uiView: CalendarView, context: Context) {
        uiView.setContent(makeContent())
    }

    private func makeContent() -> CalendarViewContent {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 7, day: 1))!
        let endDate = Date()

        return CalendarViewContent(
            calendar: calendar,
            visibleDateRange: startDate...endDate,
            monthsLayout: .vertical(options: VerticalMonthsLayoutOptions())
        )
        .withDayItemProvider { day in
            let date = day.date
            let isMarked = markedDates.contains(date.stripTime())

            return DayViewContent(
                dayText: "\(calendar.component(.day, from: date))",
                isMarked: isMarked,
                onTap: { onDateTap(date) }
            )
        }
    }
}

extension Date {
    func stripTime() -> Date {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: self)
        return Calendar.current.date(from: components)!
    }
}

struct DayViewContent {
    let dayText: String
    let isMarked: Bool
    let onTap: () -> Void
}

final class DayView: UIView {

    private let label = UILabel()
    private var tapHandler: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.widthAnchor.constraint(equalTo: widthAnchor),
            label.heightAnchor.constraint(equalTo: heightAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    func configure(with content: DayViewContent) {
        label.text = content.dayText
        label.textColor = .label
        backgroundColor = content.isMarked ? UIColor.systemGreen.withAlphaComponent(0.3) : .clear
        layer.cornerRadius = bounds.width / 2
        tapHandler = content.onTap
    }

    @objc private func handleTap() {
        tapHandler?()
    }
}


extension CalendarViewContent {
    func withDayItemProvider(
        _ provider: @escaping (Day) -> DayViewContent
    ) -> CalendarViewContent {
        withDayItemViewProvider { day -> UIView in
            let content = provider(day)
            let view = DayView()
            view.configure(with: content)
            return view
        }
    }
}


struct ContentView: View {
    var body: some View {
        WorkoutCalendarView(
            markedDates: [
                Date(), // today
                Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                Calendar.current.date(from: DateComponents(year: 2025, month: 7, day: 5))!
            ]
        )
    }
}

#Preview {
    ContentView()
}
