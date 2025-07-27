import SwiftUI

// Square view
struct GridSquare: View {
    let id = UUID()
    let imageName: String
    let title: String
    let isUser: Bool
    
    @Binding var showResults: Bool
    @Binding var selectedPlayer: String
    @State private var tapped = false
    
    init(imageName: String, title: String, isUser: Bool = false, showResults: Binding<Bool>, selectedPlayer: Binding<String>) {
        self.imageName = imageName
        self.title = title
        self.isUser = isUser
        self._showResults = showResults
        self._selectedPlayer = selectedPlayer
    }
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            tapped = true
            withAnimation(.easeInOut(duration: 0.5)) {
                tapped = false
            }
            selectedPlayer = title
            showResults = true
        }) {
            VStack {
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(self.isUser ? .accentColor : Color("secondaryButtonText"))
                    .frame(height: 64)
                
                if isUser {
                    Text(title)
                        .bold()
                        .foregroundColor(.accentColor)
                        .padding(.top, 12)
                        .padding(.horizontal)
                } else {
                    Text(title)
                        .font(.caption)
                        .bold()
                        .foregroundColor(Color("secondaryButtonText"))
                        .padding(.top, 12)
                        .padding(.horizontal)
                }
                
                
            }
            .frame(width: 160, height: 200)
            .background(self.isUser ? Color("buttonBackground") : Color("secondaryButtonBackground"))
            .cornerRadius(16)
        }
        .opacity(tapped ? 0.2 : 1)
    }
}

// Grid of squares
struct DatabaseView: View {
    let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: -10), count: 2)
    
    @Binding var showResults: Bool
    @State private var dragOffset: CGFloat = 0
    @State private var selectedPlayer = ""

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    square("You", isUser: true, top: true)
                    square("Giannis Antetokounmpo", top: true)
                    square("Devin Booker")
                    square("Jaylen Brown")
                    square("Stephen Curry")
                    square("Luka Dončić")
                    square("Kevin Durant")
                    square("Anthony Edwards")
                    square("Joel Embiid")
                    square("Shai Gilgeous-Alexander")
                    square("Tyrese Haliburton")
                    square("Chet Holmgren")
                    square("Kyrie Irving")
                    square("LeBron James")
                    square("Nikola Jokić")
                    square("Jaren Jackson Jr.")
                    square("Donovan Mitchell")
                    square("Jamal Murray")
                    square("Kristaps Porziņģis")
                    square("Austin Reaves")
                    square("Alperen Şengün")
                    square("Jayson Tatum")
                    square("Fred VanVleet")
                    square("Victor Wembanyama")
                    square("Zion Williamson", bottom: true)
                    square("Trae Young", bottom: true)
                }
                .padding()
            }
            .padding(.bottom, 8)
            Rectangle()
                .fill(Color(.systemBackground))
                .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60)
                .ignoresSafeArea(edges: .top)
            
            if showResults {
                ResultsView(input: .player(selectedPlayer)) // fill in with real date
                    .frame(width: UIScreen.main.bounds.width - 64, height: 640)
                    .padding()
                    .background(Color("inversePrimary"))
                    .cornerRadius(16)
                    .shadow(color: .gray.opacity(0.2), radius: 50, x: 0, y: 0)
                    .offset(y: dragOffset + 19)
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
                                
                                let shouldDismissByDistance = dragDistance > 500
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
}

extension DatabaseView {
    private func square(_ title: String, isUser: Bool = false, imageName: String = "person.fill", top: Bool = false, bottom: Bool = false) -> some View {
        GridSquare(imageName: imageName, title: title, isUser: isUser, showResults: $showResults, selectedPlayer: $selectedPlayer)
            .padding(.top, top ? 32 : 0)
            .padding(.bottom, bottom ? 32 : 0)
    }
}
