import SwiftUI

struct ContentView: View {
    @State private var showCamera = false
    
    var body: some View {
        VStack {
            // Top settings and welcome
            ZStack {
                HStack {
                    Button(action: {
                        // SETTINGS MENU
                    }) {
                        Image(systemName: "ellipsis.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 27)
                            .padding(.horizontal)
                    }
                    Spacer()
                }
                Text("Hello, Person!")
                    .font(.title3)
                    .bold()
                Spacer()
            }
            
            Spacer()
            
            // Actual buttons
            HStack(spacing: 12) {
                ForEach(["Accuracy", "Form"], id: \.self) { title in
                    Button(action: {
                        showCamera = true
                    }) {
                        VStack {
                            Image(systemName: title == "Accuracy" ? "target" : "waveform")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 60)
                                .padding(.horizontal)
                            Text(title)
                                .bold()
                                .padding(.top, 7)
                        }
                        .frame(maxWidth: 120, minHeight: 120) // 👈 Equal sizing
                        .padding()
                        .background(Color(red: 0, green: 0, blue: 0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                }
            }
            .padding(.horizontal)
            Spacer()
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView()
        }
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
                          dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .resizable()
                                .frame(width: 21, height: 21)
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
                          // action to perform when the button is tapped
                        }) {
                            Image(systemName: "square.on.square")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30)
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
