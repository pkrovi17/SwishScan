import SwiftUI


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


// Datastructures for JSON unpacking
struct Shot: Codable {
    let shot_made: Bool
    let x: Double
    let y: Double
}


struct Player: Codable {
    let name: String
    let id: String
    let bio: String
    let shots: [Shot]
}
