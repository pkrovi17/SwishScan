import SwiftUI

// Square view
struct GridSquare: View {
    let id = UUID()
    let imageName: String
    let title: String
    let isUser: Bool
    
    init(imageName: String, title: String, isUser: Bool = false) {
        self.imageName = imageName
        self.title = title
        self.isUser = isUser
    }
    
    var body: some View {
        Button(action: {
            print("fill out later")
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
            .cornerRadius(15)
        }
        
        
    }
}

// Grid of squares
struct DatabaseView: View {
    let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: -12), count: 2)

    var body: some View {
        ZStack (alignment: .top){
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    GridSquare(imageName: "person.fill", title: "You", isUser: true)
                        .padding(.top, 32)
                    GridSquare(imageName: "person.fill", title: "Name")
                        .padding(.top, 32)
                    GridSquare(imageName: "person.fill", title: "Name")
                    GridSquare(imageName: "person.fill", title: "Name")
                    GridSquare(imageName: "person.fill", title: "Name")
                    GridSquare(imageName: "person.fill", title: "Name")
                    GridSquare(imageName: "person.fill", title: "Name")
                    GridSquare(imageName: "person.fill", title: "Name")
                    GridSquare(imageName: "person.fill", title: "Name")
                        .padding(.bottom, 32)
                    GridSquare(imageName: "person.fill", title: "Name")
                        .padding(.bottom, 32)
                }
                .padding()
            }
            .padding(.bottom, 8)
            Rectangle()
                .fill(Color(.systemBackground))
                .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60)
                .ignoresSafeArea(edges: .top)
        }
    }
}

#Preview {
    DatabaseView()
}
