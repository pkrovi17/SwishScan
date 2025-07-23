import SwiftUI
import HorizonCalendar


// Sets up the calendar and is intialized with a markedDates object
struct CalendarView: View {
    let markedDates: [Date]
    @State private var selectedDate: Date?
    @State private var currentYear: Int = Calendar.current.component(.year, from: Date())

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
            VStack(alignment: .leading, spacing: 16) {
                Text(String(currentYear))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.leading)
                    .padding(.top)
                    .contentTransition(.numericText(value: Double(currentYear)))
                    .animation(.easeInOut, value: currentYear)
                
                CalendarViewRepresentable(
                    markedDates: markedDates,
                    onDateSelected: { date in
                        selectedDate = date
                        showResults = true
                    },
                    currentYear: $currentYear
                )
            }
            
            if showResults {
                ResultsView(day: Date()) // fill in with real date
                    .frame(maxWidth: .infinity, minHeight: 650)
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
                                    withAnimation(.interpolatingSpring(stiffness: 800, damping: 100)) {
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
    @Binding var currentYear: Int
    
    private let calendar = Calendar.current
    
    func makeUIView(context: Context) -> HorizonCalendar.CalendarView {
        let calendarView = HorizonCalendar.CalendarView(initialContent: makeContent())

        calendarView.daySelectionHandler = { day in
            let date = calendar.date(from: day.components) ?? Date()
            if date <= Date() {
                onDateSelected(date)
            }
        }

        DispatchQueue.main.async {
            calendarView.scroll(
                toMonthContaining: Date(),
                scrollPosition: .firstFullyVisiblePosition,
                animated: false
            )
        }

        calendarView.didScroll = { visibleDayRange, _ in
            let firstDay = visibleDayRange.lowerBound
            if let date = calendar.date(from: firstDay.components) {
                let year = calendar.component(.year, from: date)
                context.coordinator.currentYear.wrappedValue = year
            }
        }

        return calendarView
    }
    
    func updateUIView(_ uiView: HorizonCalendar.CalendarView, context: Context) {
        uiView.setContent(makeContent())
    }
    
    private func makeContent() -> CalendarViewContent {
        // Setting endpoints for shown dates
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 7, day: 1)) ?? Date() // SET THIS TO JULY 1 2025 WHEN DONE
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
                    isMarked: isMarked,
                    date: date,
                )
            )
        }
        .monthHeaderItemProvider { month in
            let date = calendar.date(from: month.components)!
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM"
            let monthText = formatter.string(from: date)

            return CalendarItemModel<MonthHeaderView>(
                invariantViewProperties: .init(),
                viewModel: .init(text: monthText)
            )
        }
        .interMonthSpacing(48)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(currentYear: $currentYear)
    }

    class Coordinator {
        var currentYear: Binding<Int>
        
        init(currentYear: Binding<Int>) {
            self.currentYear = currentYear
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
        label.font = UIFont.systemFont(ofSize: 32, weight: .semibold)
        label.textColor = .label

        addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
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
        let date: Date
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
        let calendar = Calendar.current
        let isToday = calendar.isDate(Date(), inSameDayAs: viewModel.date)
        
        if isToday {
            label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        }
        label.text = viewModel.dayText
        label.textColor = viewModel.isMarked ? .systemBlue : isToday ? .label : viewModel.date > Date() ? UIColor(named: "secondaryButtonBackground") : UIColor(named: "secondaryButtonText")
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
