import SwiftUI

struct ContentView: View {
    
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 30)
                    Text("Home")
                }
            CalendarView()
                .tabItem {
                    Image(systemName: "clock")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 30)
                    Text("Archive")
                }
            DatabaseView()
                .tabItem {
                    Image(systemName: "person")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 30)
                    Text("Database")
                }
        }
    }
}

struct HomeView: View {
    @State private var showCamera = false
    
    var body: some View {
        VStack {
            // Top settings and welcome
            VStack (alignment: .leading){
                Text("Hi, [name].")
                    .font(.title)
                    .fontWeight(.medium)
                    .padding(.top, 50)
                Text("What should we work on today?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 4)
            }
            
            Spacer()
            
            // Actual buttons
            HStack(spacing: 12) {
                ForEach(["Accuracy", "Form"], id: \.self) { title in
                    Button(action: {
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
                        .background(Color(red: 0, green: 0, blue: 0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                }
            }
            .padding(.horizontal)
            Spacer()
            Spacer()
            // Use most recent data to fill this out
            Text("Last session was _ days ago.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView()
        }
    }
}

struct CalendarView: View {
    let eventDates: Set<DateComponents> = [
        // FILL THIS IN WITH ACTUAL DATE DATA
        DateComponents(year: 2025, month: 7, day: 10),
    ]

    @State private var selectedDates: Set<DateComponents> = []
    @State private var previouslySelected: Set<DateComponents> = []
    @State private var activeDate: IdentifiableDate? = nil
    @State private var isInitializing = true


    var body: some View {
        MultiDatePicker("Calendar", selection: $selectedDates)
            .onAppear {
                selectedDates = eventDates
                previouslySelected = eventDates
                
                DispatchQueue.main.async {
                    isInitializing = false
                }
            }
            .onChange(of: selectedDates) { oldValue, newValue in
                guard !isInitializing else { return }
                
                let changed = newValue.symmetricDifference(oldValue)
                if let tapped = changed.first, let date = Calendar.current.date(from: tapped) {
                    activeDate = IdentifiableDate(date: date)

                    // Let SwiftUI finish observing the change first
                    DispatchQueue.main.async {
                        selectedDates = oldValue
                    }
                }
            }


            .padding(.horizontal)
            .sheet(item: $activeDate) { wrapper in
                let date = wrapper.date
                VStack {
                    Text("Workout on \(date.formatted(.dateTime.month().day().year()))")
                }
                .presentationDetents([.medium, .large])
            }

    }
}

struct IdentifiableDate: Identifiable {
    var id: Date { date }
    let date: Date
}

struct DatabaseView: View {
    var body: some View {
        Text("Under Construction n shit numba 2")
    }
}

struct CameraView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(edges: .all)
            VStack {
                    Text("Have the instructions go here.")
                    .foregroundStyle(.white)
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                          // action to perform when the button is tapped
                        }) {
                            Image(systemName: "square.on.square")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30)
                                .foregroundColor(.white)
                        }
                    Spacer()
                    Button(action: {
                        
                    }, label: {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 70, height: 70)
                    })
                    Spacer()
                    
                    Button(action: {
                          dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .resizable()
                                .frame(width: 22, height: 22)
                                .foregroundColor(.white)
                        }
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
