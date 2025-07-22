import SwiftUI
import HorizonCalendar

// Sets up the calendar and is intialized with a markedDates object
struct CalendarView: View {
    let markedDates: [Date]
    @State private var selectedDate: Date?
    @State private var showResults = false
    @State private var dragOffset: CGFloat = 0
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        ZStack {
            CalendarViewRepresentable(
                markedDates: markedDates,
                onDateSelected: { date in
                    selectedDate = date
                    showResults = true
                }
            )
            
            if showResults {
                ResultsView(day: Date()) // fill in with real date
                    .frame(maxWidth: .infinity, minHeight: 600)
                    .padding()
                    .background(Color("secondaryButtonBackground"))
                    .cornerRadius(15)
                    .offset(y: dragOffset)
                    .onAppear {
                        dragOffset = UIScreen.main.bounds.height
                        withAnimation(.interpolatingSpring(stiffness: 250, damping: 24)) {
                            dragOffset = 0
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if value.translation.height > 0 {
                                    dragOffset = value.translation.height
                                }
                            }
                            .onEnded { value in
                                let dragDistance = value.translation.height
                                let predictedDistance = value.predictedEndTranslation.height
                                let dragVelocity = predictedDistance - dragDistance
                                
                                let shouldDismissByDistance = dragDistance > 300
                                let shouldDismissByVelocity = dragVelocity > 150
                                
                                if shouldDismissByDistance || shouldDismissByVelocity {
                                    withAnimation(.interpolatingSpring(stiffness: 500, damping: 50)) {
                                        dragOffset = UIScreen.main.bounds.height
                                    }

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        showResults = false
                                        dragOffset = 0
                                    }
                                } else {
                                    withAnimation {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: showResults)
            }
        }
    }
    
    private func isDateMarked(_ date: Date) -> Bool {
        markedDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }
}


// The actual calendar object
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
        // Setting endpoints for shown dates
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 7, day: 1)) ?? Date()
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
        .monthHeaderItemProvider { month in
            let date = calendar.date(from: month.components)!
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            let monthText = formatter.string(from: date)

            return CalendarItemModel<MonthHeaderView>(
                invariantViewProperties: .init(),
                viewModel: .init(text: monthText)
            )
        }
    }
}

final class MonthHeaderView: UIView {
    struct ViewModel: Equatable {
        let text: String
    }

    struct InvariantViewProperties: Hashable {}

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        label.textColor = .label
        addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setViewModel(_ viewModel: ViewModel) {
        label.text = viewModel.text
    }
}

extension MonthHeaderView: CalendarItemViewRepresentable {
    static func makeView(withInvariantViewProperties _: InvariantViewProperties) -> MonthHeaderView {
        MonthHeaderView()
    }

    static func setViewModel(_ viewModel: ViewModel, on view: MonthHeaderView) {
        view.setViewModel(viewModel)
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
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
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
        label.textColor = viewModel.isMarked ? .systemBlue : .label
        backgroundColor = viewModel.isMarked ? UIColor(named: "buttonBackground") : .clear
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 15
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

// This just initializes markedDates and calls CalendarView
struct CalendarViewWorking: View {
    let markedDates: [Date] = {
        let calendar = Calendar.current
        return [
            calendar.date(from: DateComponents(year: 2025, month: 7, day: 15))!,
            calendar.date(from: DateComponents(year: 2025, month: 7, day: 19))!,
            // REPLACE WITH REAL DATE DATA
        ]
    }()
    
    var body: some View {
        CalendarView(markedDates: markedDates)
            .padding()
    }
}

#Preview {
    CalendarViewWorking()
}
