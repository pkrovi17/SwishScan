//
//  ContentView.swift
//  ballin
//
//  Created by Noah Ham on 7/12/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                      // action to perform when the button is tapped
                    }) {
                        Image(systemName: "gear")
                        .resizable() // This allows the image to be resized
                        .frame(width: 30, height: 30) // This sets the size of the image
                    }
                Spacer()
                Text("Hello, Person")
                    .font(.title3) // Makes it bigger
                    .bold()       // Makes it bold
                Spacer()
            }
            Spacer()
            HStack {
                Button("Accuracy") {
                    /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Action@*/ /*@END_MENU_TOKEN@*/
                }
                .padding()
                .background(Color(red: 0, green: 0, blue: 0.5))
                .clipShape(RoundedRectangle(cornerRadius:15))

                Button("Form") {
                    /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Action@*/ /*@END_MENU_TOKEN@*/
                }
                .padding()
                .background(Color(red: 0, green: 0, blue: 0.5))
                .clipShape(RoundedRectangle(cornerRadius:15))
            }
            Spacer()
        }
    }
}

struct CameraView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(edges: .all)
            VStack {
                
                VStack {
                    Text("Put the instructions here.")
                        .padding(.horizontal, 20)
                        .colorInvert()
                    Spacer()
                    Button(action: {}, label: {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                    })
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
