import SwiftUI
import HorizonCalendar

struct CalendarView: View {
    let markedDates: [Date]
    @State private var selectedDate: Date?
    @State private var showingSheet = false
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        CalendarViewRepresentable(
            markedDates: markedDates,
            onDateSelected: { date in
                selectedDate = date
                // Small delay to ensure state is updated before sheet presentation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    showingSheet = true
                }
            }
        )
        .sheet(isPresented: $showingSheet) {
            VStack(spacing: 20) {
                if let selectedDate = selectedDate {
                    Text("You clicked on: \(dateFormatter.string(from: selectedDate))")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("It \(isDateMarked(selectedDate) ? "is" : "is not") marked.")
                        .font(.subheadline)
                        .foregroundColor(isDateMarked(selectedDate) ? .green : .red)
                } else {
                    Text("Loading...")
                        .font(.headline)
                }
                
                Button("Close") {
                    showingSheet = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .presentationDetents([.medium])
        }
    }
    
    private func isDateMarked(_ date: Date) -> Bool {
        markedDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }
}

struct CalendarViewRepresentable: UIViewRepresentable {
    let markedDates: [Date]
    let onDateSelected: (Date) -> Void
    
    private let calendar = Calendar.current
    
    func makeUIView(context: Context) -> HorizonCalendar.CalendarView {
        let calendarView = HorizonCalendar.CalendarView(initialContent: makeContent())
        calendarView.daySelectionHandler = { day in
            let date = calendar.date(from: day.components) ?? Date()
            onDateSelected(date)
        }
        return calendarView
    }
    
    func updateUIView(_ uiView: HorizonCalendar.CalendarView, context: Context) {
        uiView.setContent(makeContent())
    }
    
    private func makeContent() -> CalendarViewContent {
        // July 1, 2025
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 7, day: 1)) ?? Date()
        // Present date (today)
        let endDate = Date()
        
        return CalendarViewContent(
            calendar: calendar,
            visibleDateRange: startDate...endDate,
            monthsLayout: .vertical(options: VerticalMonthsLayoutOptions())
        )
        .interMonthSpacing(24)
        .verticalDayMargin(8)
        .horizontalDayMargin(8)
        .dayItemProvider { day in
            let date = calendar.date(from: day.components) ?? Date()
            let isMarked = markedDates.contains { calendar.isDate($0, inSameDayAs: date) }
            
            return CalendarItemModel<DayView>(
                invariantViewProperties: .init(),
                viewModel: .init(
                    dayText: "\(day.day)",
                    isMarked: isMarked
                )
            )
        }
    }
}

final class DayView: UIView {
    struct ViewModel: Equatable {
        let dayText: String
        let isMarked: Bool
    }
    
    struct InvariantViewProperties: Hashable {
        
    }
    
    private var label: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func setViewModel(_ viewModel: ViewModel) {
        label.text = viewModel.dayText
        backgroundColor = viewModel.isMarked ? UIColor.systemBlue.withAlphaComponent(0.3) : UIColor.clear
        layer.borderWidth = viewModel.isMarked ? 2 : 0
        layer.borderColor = viewModel.isMarked ? UIColor.systemBlue.cgColor : UIColor.clear.cgColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
    }
}

extension DayView: CalendarItemViewRepresentable {
    static func makeView(
        withInvariantViewProperties invariantViewProperties: InvariantViewProperties
    ) -> DayView {
        return DayView()
    }
    
    static func setViewModel(
        _ viewModel: ViewModel,
        on view: DayView
    ) {
        view.setViewModel(viewModel)
    }
}

// Example usage
struct CalendarViewWorking: View {
    // Sample marked dates
    let markedDates: [Date] = {
        let calendar = Calendar.current
        let today = Date()
        return [
            today,
            calendar.date(byAdding: .day, value: 5, to: today) ?? today,
            calendar.date(byAdding: .day, value: -3, to: today) ?? today,
            calendar.date(byAdding: .day, value: 10, to: today) ?? today,
            calendar.date(byAdding: .day, value: -7, to: today) ?? today
        ]
    }()
    
    var body: some View {
        NavigationView {
            CalendarView(markedDates: markedDates)
                .navigationTitle("Calendar")
        }
    }
}

#Preview {
    CalendarViewWorking()
}
