import SwiftUI

// Square view
struct GridSquare: View {
    let id = UUID()
    let imageName: String
    let title: String
    
    var body: some View {
        Button(action: {
            print("fill out later")
        }) {
            VStack {
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
                    .padding(.top)
                
                Text(title)
                    .font(.headline)
                    .padding(.top, 8)
            }
            .frame(width: 160, height: 200)
            .background(Color("secondaryButtonBackground"))
            .cornerRadius(15)
        }
        
        
    }
}

// Grid of squares
struct DatabaseView: View {
    let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: -12), count: 2)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                GridSquare(imageName: "person", title: "le bon bon")
                GridSquare(imageName: "person", title: "Name")
                GridSquare(imageName: "person", title: "Name")
                GridSquare(imageName: "person", title: "Name")
                GridSquare(imageName: "person", title: "Name")
                GridSquare(imageName: "person", title: "Name")
                GridSquare(imageName: "person", title: "Name")
                GridSquare(imageName: "person", title: "Name")
                GridSquare(imageName: "person", title: "Name")
                GridSquare(imageName: "person", title: "Name")
            }
            .padding()
        }
    }
}

#Preview {
    DatabaseView()
}
