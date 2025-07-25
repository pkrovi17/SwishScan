import SwiftUI


struct MainView: View {
    @AppStorage("isDarkMode") var isDarkMode = false
    @State private var selectedTab = 0
    
    // Eventually look for tab reselection with these
    @State private var showHomeResults = false
    @State private var showCalendarResults = false
    @State private var showDatabaseResults = false
    
    var body: some View {
        // Basic tabview n shi
        TabView(selection: $selectedTab) {
            HomeView(isDarkMode: $isDarkMode, selectedTab: $selectedTab, showResults: $showHomeResults)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, alignment: .center)
                .tabItem {
                    VStack {
                        Image(systemName: "house.fill")
                            .padding(.top, 30)
                        Text("Home")
                    }
                }
                .tag(0)
            CalendarViewWorking(showResults: $showCalendarResults)
                .tabItem {
                    VStack {
                        Image(systemName: "clock.fill")
                        Text("Archive")
                    }
                }
                .tag(1)
            DatabaseView()
                .tabItem {
                    VStack {
                        Image(systemName: "person.fill")
                        Text("Database")
                    }
                }
                .tag(2)
        }
        .onAppear() {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(isDarkMode ? .black : .white)
            
            // 🧽 Remove the top border line ("shadow image")
            appearance.shadowImage = nil
            appearance.shadowColor = .clear
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}


struct HomeView: View {
    @Binding var isDarkMode: Bool
    @Binding var selectedTab: Int
    @State private var showCamera = false

    @State private var isAccuracyTest = false
    @State private var greetingAdjective: String?
    @State private var greetingTime = "night"
    
    @Binding var showResults: Bool
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            VStack {
                // Top settings and welcome
                VStack (alignment: .leading){
                    Text("\(greetingAdjective ?? "Good") \(greetingTime).")
                        .font(.title)
                        .fontWeight(.regular)
                        .padding(.top, 42)
                    Text("Want to get some practice in today?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, -4)
                }
                Spacer()
                // Accuracy and Form buttons
                HStack(spacing: 12) {
                    ForEach(["Accuracy", "Form"], id: \.self) { title in
                        Button(action: {
                            if title == "Accuracy" {
                                isAccuracyTest = true
                            } else {
                                isAccuracyTest = false
                            }
                            showCamera = true
                        }) {
                            VStack {
                                Image(systemName: title == "Accuracy" ? "scope" : "scribble")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 64)
                                    .padding(.horizontal)
                                Text(title)
                                    .bold()
                                    .padding(.top, 8)
                            }
                            .frame(maxWidth: 120, minHeight: 140)
                            .padding()
                            .background(Color("buttonBackground"))
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                    }
                }
                .offset(y: -100)
                
                Button(action: {
                    selectedTab = 1
                }) {
                    VStack {
                        Text("99 Day Streak")
                            .foregroundColor(Color("secondaryButtonText"))
                            .bold()
                    }
                    .frame(maxWidth: 282, maxHeight: 36)
                    .padding()
                    .background(Color("secondaryButtonBackground"))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .offset(y: -96) // -100 + 4 for equal spacing
                
                // Settings and dark mode buttons
                HStack (spacing: 12) {
                    Button(action: {
                        // find something for this
                    }) {
                        VStack {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(Color("secondaryButtonText"))
                                .frame(height: 24)
                        }
                        .frame(maxWidth: 120, maxHeight: 36)
                        .padding()
                        .background(Color("secondaryButtonBackground"))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    .offset(y: -92) // -100 + 8 for equal spacing
                    
                    Button(action: {
                        isDarkMode.toggle()
                    }) {
                        VStack {
                            Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(Color("secondaryButtonText"))
                                .frame(height: 24)
                        }
                        .frame(maxWidth: 120, maxHeight: 36)
                        .padding()
                        .background(Color("secondaryButtonBackground"))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    .offset(y: -92) // -100 + 8 for equal spacing
                }
            }
            
            if showResults {
                ResultsView(day: Date()) // fill in with real date
                    .frame(maxWidth: .infinity, minHeight: 600)
                    .padding()
                    .background(Color("secondaryButtonBackground"))
                    .cornerRadius(15)
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
            let items = ["Nice", "Good", "Beautiful"]
            greetingAdjective = items.randomElement()
        }
    }
}


struct IdentifiableDate: Identifiable {
    var id: Date { date }
    let date: Date
}


struct ResultsView: View {
    @State var day: Date
    @State private var hasAccuracy = false
    @State private var hasForm = false
    
    var body: some View {
        if !hasAccuracy && !hasForm {
            Text("No data on this day.")
        } else {
            if hasAccuracy {
                Text("Accuracy data will appear here.")
            }
            if hasForm {
                Text("Form data will appear here.")
            }
            Text("You are most similar to ___.")
        }
    }
    
    func initialize() {
        // in documents,
        // if directory doesn't exist, exit
        // check if accuracy_ or form_ exist
    }
}


#Preview {
    MainView()
}
