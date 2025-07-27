import SwiftUI


struct ResultsView: View {
    var input: DayOrPlayer
    let playerIDs = [
        "Stephen Curry": "201939",
        "Kyrie Irving": "202681",
        "Kevin Durant": "201142",
        "Joel Embiid": "203954",
        "Nikola Jokić": "203999",
        "Giannis Antetokounmpo": "203507",
        "LeBron James": "2544",
        "Luka Dončić": "1629029",
        "Trae Young": "1629027",
        "Tyrese Haliburton": "1630169",
        "Victor Wembanyama": "1641705",
        "Anthony Edwards": "1630162",
        "Jayson Tatum": "1628369",
        "Donovan Mitchell": "1628378",
        "Devin Booker": "1626164",
        "Zion Williamson": "1629627",
        "Jamal Murray": "1627750",
        "Desmond Bane": "1630217",
        "Jaylen Brown": "1627759",
        "Kristaps Porziņģis": "204001",
        "Chet Holmgren": "1631096",
        "Jaren Jackson Jr.": "1628991",
        "Alperen Şengün": "1630578",
        "Fred VanVleet": "1627832",
        "Austin Reaves": "1630559",
        "Shai Gilgeous-Alexander": "1628983",
    ]
    
    @State private var hasAccuracy = false
    @State private var hasForm = false
    
    var body: some View {
        VStack {
            Group {
                switch input {
                case .date(let day):
                    Text(day.formatted(date: .abbreviated, time: .omitted))
                case .player(let name):
                    Text(name)
                        
                }
            }
            .font(.title)
            .fontWeight(.bold)
            .padding(.horizontal)
            .padding(.top, 24)
            .frame(width: 336, alignment: .leading)
            Spacer()
            VStack(spacing: 16) {
                if !hasAccuracy && !hasForm {
                } else {
                    if hasAccuracy {
                        // Rectangle to hold half-court accuracy data
                        // DATA IS UP TO 564 BUT RECTANGLE HAS HEIGHT OF 300
                        let inset: CGFloat = 12 // space between lines and outer border
                        
                        ZStack {
                            // Court perimeter (adjusted for inset)
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("secondaryButtonBackground"))
                                .stroke(Color("secondaryButtonBackground"), lineWidth: 4)
                            
                            // 3-point arc (center adjusted upward by inset)
                            Path { path in
                                let center = CGPoint(x: 170, y: 308 - inset)
                                let radius: CGFloat = 150 - inset
                                
                                path.addArc(center: center,
                                            radius: radius,
                                            startAngle: .degrees(214.5),
                                            endAngle: .degrees(325.5),
                                            clockwise: false)
                            }
                            .stroke(Color("secondaryButtonText"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            
                            // 3-point line sides (inset applied to x and y)
                            Path { path in
                                path.move(to: CGPoint(x: 44 + inset, y: 220))
                                path.addLine(to: CGPoint(x: 44 + inset, y: 320 - inset))
                                
                                path.move(to: CGPoint(x: 296 - inset, y: 220))
                                path.addLine(to: CGPoint(x: 296 - inset, y: 320 - inset))
                            }
                            .stroke(Color("secondaryButtonText"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            
                            // Key
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.clear)
                                .stroke(Color("secondaryButtonText"), lineWidth: 4)
                                .frame(width: 96, height: 114)
                                .offset(y: 103 - inset)
                            
                            // Free throw circle
                            Circle()
                                .fill(.clear)
                                .stroke(Color("secondaryButtonText"), lineWidth: 4)
                                .frame(width: 72, height: 72)
                                .offset(y: 46 - inset)
                        }
                        .frame(width: UIScreen.main.bounds.width - 64, height: 320)
                        .padding(.top)
                    }
                    if hasForm {
                        VStack {
                            Text("Form data will appear here.")
                        }
                        .frame(width: UIScreen.main.bounds.width - 64, height: 150)
                        .background((Color("secondaryButtonBackground")))
                        .cornerRadius(16)
                    }
                }
            }
        }
        .onAppear {
            initialize()
        }
    }
    
    func initialize() {
        switch input {
        case .player:
            hasAccuracy = true
            hasForm = true
        case .date:
            // make this actually initialize
            hasAccuracy = true
            hasForm = true
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

#Preview {
    ResultsView(input: .player("Lebron James"))
}
