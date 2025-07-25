import SwiftUI

// Square view
struct GridSquare: View {
    let id = UUID()
    let imageName: String
    let title: String
    let isUser: Bool
    
    @Binding var showResults: Bool
    @State private var tapped = false
    
    init(imageName: String, title: String, isUser: Bool = false, showResults: Binding<Bool>) {
        self.imageName = imageName
        self.title = title
        self.isUser = isUser
        self._showResults = showResults  // <- IMPORTANT
    }
    
    var body: some View {
        Button(action: {
            tapped = true
            withAnimation(.easeInOut(duration: 0.5)) {
                tapped = false
            }
            showResults = true
        }) {
            VStack {
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(self.isUser ? .accentColor : Color("secondaryButtonText"))
                    .frame(height: 60)
                    .padding(.top)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(self.isUser ? .accentColor : Color("secondaryButtonText"))
                    .padding(.top, 8)
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
    let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: -12), count: 2)
    
    @Binding var showResults: Bool
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack (alignment: .top){
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    // Top two with 32 pix of top padding
                    GridSquare(imageName: "person.fill", title: "You", isUser: true, showResults: $showResults)
                        .padding(.top, 32)
                    GridSquare(imageName: "person.fill", title: "Name", showResults: $showResults)
                        .padding(.top, 32)
                    GridSquare(imageName: "person.fill", title: "Name", showResults: $showResults)
                    GridSquare(imageName: "person.fill", title: "Name", showResults: $showResults)
                    GridSquare(imageName: "person.fill", title: "Name", showResults: $showResults)
                    GridSquare(imageName: "person.fill", title: "Name", showResults: $showResults)
                    GridSquare(imageName: "person.fill", title: "Name", showResults: $showResults)
                    GridSquare(imageName: "person.fill", title: "Name", showResults: $showResults)
                    GridSquare(imageName: "person.fill", title: "Name", showResults: $showResults)
                        .padding(.bottom, 32)
                    GridSquare(imageName: "person.fill", title: "Name", showResults: $showResults)
                        .padding(.bottom, 32)
                    // Top two with 32 pix of bottom padding
                }
                .padding()
            }
            .padding(.bottom, 8)
            Rectangle()
                .fill(Color(.systemBackground))
                .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60)
                .ignoresSafeArea(edges: .top)
            
            if showResults {
                ResultsView(day: Date()) // fill in with real date
                    .frame(maxWidth: .infinity, minHeight: 650)
                    .padding()
                    .background(Color("secondaryButtonBackground"))
                    .cornerRadius(16)
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
