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
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            CalendarViewWorking(showResults: $showCalendarResults)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
                .tag(1)
            DatabaseView(showResults: $showDatabaseResults)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Database")
                }
                .tag(2)
        }
        .onAppear() {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(isDarkMode ? .black : .white)
            
            appearance.shadowImage = nil
            appearance.shadowColor = .clear
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .onChange(of: isDarkMode) { oldValue, newValue in
            UITabBar.appearance().scrollEdgeAppearance?.backgroundColor = UIColor(newValue ? .black : .white)
            UITabBar.appearance().standardAppearance.backgroundColor = UIColor(newValue ? .black : .white)
        }
        .id(isDarkMode)
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}



struct ScaledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.6 : 1.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.5), value: configuration.isPressed)
    }
}


#Preview {
    MainView()
}
