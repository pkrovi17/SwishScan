import SwiftUI


struct ResultsView: View {
    var input: DayOrPlayer
    
    @State private var hasAccuracy = false
    @State private var hasForm = false
    
    var body: some View {
        VStack {
            switch input {
                case .date(let day):
                    Text(day.formatted(date: .abbreviated, time: .omitted))
                        .bold()
                case .player(let name):
                    Text(name)
                        .bold()
            }

            if !hasAccuracy && !hasForm {
//                Text("No data on this day.")
            } else {
                if hasAccuracy {
                    Text("Accuracy data will appear here.")
                }
                if hasForm {
                    Text("Form data will appear here.")
                }
            }
        }
    }
}


// Datastructures for JSON unpacking
struct Shot: Codable {
    let SHOT_MADE_FLAG: Bool
    let LOC_X: Double
    let LOC_Y: Double
}


struct Player: Codable {
    let name: String
//    let bio: String
    let shots: [Shot]
}

enum DayOrPlayer {
    case date(Date)
    case player(String)
}
