import SwiftUI


struct ResultsView: View {
    var input: DayOrPlayer
    
    @State private var hasAccuracy = false
    @State private var hasForm = false
    
    @State private var playerData: Player?
    private var playerIDs: [String: String] {
        guard case .player = input else { return [:] }
        return [
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
    }
    
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
                        // DATA IS UP TO 564 BUT RECTANGLE HAS HEIGHT OF 300
                        GeometryReader { geo in
                            ZStack {
                                // 3-point arc (center adjusted upward by inset)
                                Path { path in
                                    let center = CGPoint(x: 165, y: 300)
                                    let radius: CGFloat = 170
                                    
                                    path.addArc(center: center,
                                                radius: radius,
                                                startAngle: .degrees(208),
                                                endAngle: .degrees(332),
                                                clockwise: false)
                                }
                                .stroke(Color("secondaryButtonText"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                
                                // 3-point line sides (inset applied to x and y)
                                Path { path in
                                    path.move(to: CGPoint(x: 15, y: 220))
                                    path.addLine(to: CGPoint(x: 15, y: 310))
                                    
                                    path.move(to: CGPoint(x: 315, y: 220))
                                    path.addLine(to: CGPoint(x: 315, y: 310))
                                }
                                .stroke(Color("secondaryButtonText"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                
                                // Key
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(.clear)
                                    .stroke(Color("secondaryButtonText"), lineWidth: 4)
                                    .frame(width: 96, height: 143)
                                    .offset(x: -5, y: 79)
                                
                                // Free throw circle
                                Path { path in
                                    let center = CGPoint(x: 31, y: 0) // half of width/height (72x72)
                                    let radius: CGFloat = 36
                                    
                                    path.addArc(center: center,
                                                radius: radius,
                                                startAngle: .degrees(180),
                                                endAngle: .degrees(0),
                                                clockwise: false)
                                }
                                
                                .stroke(Color("secondaryButtonText"), lineWidth: 4)
                                .frame(width: 72, height: 72)
                                .offset(y: 43)
                                
                                
                                
                                // Showing shots
                                if let shots = playerData?.shots {
                                    let frameWidth = geo.size.width
                                    let frameHeight = geo.size.height

                                    let xRange: CGFloat = 500.0 // -250 to 250
                                    let yRange: CGFloat = 450.0 // -282 to 282

                                    ForEach(shots.indices, id: \.self) { index in
                                        let shot = shots[index]

                                        let x = CGFloat(shot.LOC_X)
                                        let y = CGFloat(shot.LOC_Y)

                                        let scaledX = (x / xRange) * frameWidth + frameWidth / 2
                                        let scaledY = frameHeight / 2 - (y / yRange) * frameHeight

                                        Circle()
                                            .fill(shot.SHOT_MADE_FLAG == 1 ? .blue : .gray)
                                            .opacity(0.5)
                                            .frame(width: 6, height: 6)
                                            .position(x: scaledX, y: scaledY - 50)
                                    }
                                }
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width - 64, height: 320)
                        .background(Color("secondaryButtonBackground"))
                        .cornerRadius(16)
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
        case .player(let name):
            hasAccuracy = true
            hasForm = true
            
            if name != "You" { // FIXME: make this work with real player data. maybe cap the total shots in case they go crazy
                let playerID = playerIDs[name] ?? ""
                playerData = loadPlayerData(playerID: playerID)
            }
            
        case .date:
            hasAccuracy = true
            hasForm = true
        }
    }
}


func loadPlayerData(playerID: String) -> Player? {
    guard let url = Bundle.main.url(forResource: playerID, withExtension: "json") else {
        print("Missing file: data/\(playerID).json")
        return nil
    }
    
    do {
        let data = try Data(contentsOf: url)
        let player = try JSONDecoder().decode(Player.self, from: data)
        return player
    } catch {
        print("Failed to decode JSON for playerID \(playerID): \(error)")
        return nil
    }
}


// Datastructures for JSON unpacking
struct Shot: Codable {
    let SHOT_MADE_FLAG: Int
    let LOC_X: Double
    let LOC_Y: Double
}


struct Player: Codable {
    let name: String
    let shots: [Shot]
}


enum DayOrPlayer {
    case date(Date)
    case player(String)
}


#Preview {
    ResultsView(input: .player("Stephen Curry"))
}
