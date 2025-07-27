import SwiftUI


struct HomeView: View {
    @Binding var isDarkMode: Bool
    @Binding var selectedTab: Int
    @State private var showCamera = false

    @AppStorage("units") var units: Units = .none
    @AppStorage("notificationTiming") var notificationTiming: ReminderFrequency = .none
    
    @State private var isAccuracyTest = false
    @State private var greetingAdjective: String?
    @State private var greetingTime = "night"
    @State private var greetingMessage = "le bon-bon is my king"
    
    @Binding var showResults: Bool
    @State private var showSetting: String = "none"
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            VStack {
                // Top settings and welcome
                VStack(alignment: .leading) {
                    Text("\(greetingAdjective ?? "Good") \(greetingTime).")
                        .font(.title)
                        .fontWeight(.regular)
                    Text(greetingMessage)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, -4)
                }
                .padding(.top, 32)
                Spacer()
                VStack {
                    // Accuracy and Form buttons
                    HStack(spacing: 16) {
                        ForEach(["Accuracy", "Form"], id: \.self) { title in
                            Button(action: {
                                if title == "Accuracy" {
                                    isAccuracyTest = true
                                } else {
                                    isAccuracyTest = false
                                }
                                showCamera = true
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }) {
                                VStack {
                                    Image(systemName: title == "Accuracy" ? "scope" : "scribble")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 64)
                                        .padding(.horizontal)
                                    Text(title)
                                        .bold()
                                        .padding(.top, 12)
                                }
                                .frame(maxWidth: 160, minHeight: 200)
                                .background(Color("buttonBackground"))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                    
                    // Steak counter
                    Button(action: {
                        selectedTab = 1
                        UISelectionFeedbackGenerator().selectionChanged()
                    }) {
                        VStack {
                            Text("99 Day Streak")
                                .foregroundColor(Color("secondaryButtonText"))
                                .bold()
                        }
                        .frame(maxWidth: 336, maxHeight: 60)
                        .background(Color("secondaryButtonBackground"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.vertical, 8)
                    
                    // Settings and dark mode buttons
                    HStack (spacing: 16) {
                        Button(action: {
                            showSetting = "units"
                            UISelectionFeedbackGenerator().selectionChanged()
                        }) {
                            VStack {
                                Image(systemName: "ruler.fill")
                                    .resizable()
                                    .foregroundColor(Color("secondaryButtonText"))
                                    .frame(width: 30, height: 24)
                            }
                            .frame(maxWidth: 101.33, maxHeight: 60)
                            .background(Color("secondaryButtonBackground"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        Button(action: {
                            showSetting = "alarm"
                            UISelectionFeedbackGenerator().selectionChanged()
                        }) {
                            VStack {
                                Image(systemName: "bell.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(Color("secondaryButtonText"))
                                    .frame(height: 24)
                            }
                            .frame(maxWidth: 101.33, maxHeight: 60)
                            .background(Color("secondaryButtonBackground"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        Button(action: {
                            isDarkMode.toggle()
                            UISelectionFeedbackGenerator().selectionChanged()
                        }) {
                            VStack {
                                Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(Color("secondaryButtonText"))
                                    .frame(height: 24)
                            }
                            .frame(maxWidth: 101.33, maxHeight: 60)
                            .background(Color("secondaryButtonBackground"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding(.bottom, 94)
            }
            
            if showResults {
                ResultsView(input: .date(Date())) // fill in with real date
                    .frame(width: UIScreen.main.bounds.width - 64, height: 640)
                    .padding()
                    .background(Color("secondaryButtonBackground"))
                    .cornerRadius(16)
                    .offset(y: dragOffset)
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
                                
                                let shouldDismissByDistance = dragDistance > 500
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
            
            if showSetting != "none" {
                Group {
                    if showSetting == "units" {
                        UnitsSettingView(units: $units)
                    } else if showSetting == "alarm" {
                        NotificationsSettingView(reminderFrequency: $notificationTiming)
                    }
                }
                .frame(width: 336, height: 120)
                .background(Color("secondaryButtonBackground"))
                .cornerRadius(16)
                .offset(y: dragOffset + 261)
                .onAppear {
                    dragOffset = 200
                    withAnimation(.interpolatingSpring(stiffness: 200, damping: 56)) {
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
                            
                            let shouldDismissByDistance = dragDistance > 50
                            let shouldDismissByVelocity = dragVelocity > 150
                            
                            if shouldDismissByDistance || shouldDismissByVelocity {
                                withAnimation(.interpolatingSpring(stiffness: 500, damping: 50)) {
                                    dragOffset = 200
                                }

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    showSetting = "none"
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
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(showResults: $showResults, isAccuracyTest: $isAccuracyTest)
                .preferredColorScheme(.dark)
        }
        .onAppear {
            // Determining the greeting by seeing the time
            let hour = Calendar.current.component(.hour, from: Date())
            if hour >= 6 && hour < 12 {
                greetingTime = "morning"
            } else if hour >= 12 && hour < 17 {
                greetingTime = "afternoon"
            } else if hour >= 17 && hour < 21 {
                greetingTime = "evening"
            } else {
                greetingTime = "night"
            }
            
            // Get random adjective
            let times = ["Nice", "Good", "Beautiful"]
            let messages = ["Want to get some practice in today?", "You in for some work today?", "Want to get some shots up today?"]
            
            greetingAdjective = times.randomElement()
            greetingMessage = messages.randomElement()!
        }
    }
}


struct NotificationsSettingView: View {
    @Binding var reminderFrequency: ReminderFrequency

    var body: some View {
        VStack(alignment: .leading) {
            Text("Reminders")
                .font(.headline)
            
            Picker("Reminder Frequency", selection: $reminderFrequency) {
                ForEach(ReminderFrequency.allCases, id: \.self) { frequency in
                    Text(frequency.rawValue).tag(frequency)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(EdgeInsets(top: 16, leading: 28, bottom: 16, trailing: 28))
    }
}


struct UnitsSettingView: View {
    @Binding var units: Units

    var body: some View {
        VStack(alignment: .leading) {
            Text("Units")
                .font(.headline)
            
            Picker("Units", selection: $units) {
                ForEach(Units.allCases, id: \.self) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(EdgeInsets(top: 16, leading: 28, bottom: 16, trailing: 28))
    }
}


enum ReminderFrequency: String, CaseIterable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
}


enum Units: String, CaseIterable {
    case none = "Yards"
    case daily = "Meters"
}
