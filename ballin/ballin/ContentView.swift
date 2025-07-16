import SwiftUI
import AVFoundation

struct ContentView: View {
    
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 30)
                    Text("Home")
                }
            CalendarView()
                .tabItem {
                    Image(systemName: "clock")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 30)
                    Text("Archive")
                }
            DatabaseView()
                .tabItem {
                    Image(systemName: "person")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 30)
                    Text("Database")
                }
        }
    }
}

struct HomeView: View {
    @State private var showCamera = false
    
    var body: some View {
        VStack {
            // Top settings and welcome
            VStack (alignment: .leading){
                Text("Hi, [name].")
                    .font(.title)
                    .fontWeight(.medium)
                    .padding(.top, 50)
                    .padding(.horizontal, 4)
                Text("What should we work on today?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 4)
                    .padding(.horizontal, 4)
            }
            
            Spacer()
            
            // Actual buttons
            HStack(spacing: 12) {
                ForEach(["Accuracy", "Form"], id: \.self) { title in
                    Button(action: {
                        showCamera = true
                    }) {
                        VStack {
                            Image(systemName: title == "Accuracy" ? "scope" : "scribble")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 64)
                                .padding(.horizontal)
                            Text(title)
                                .bold()
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: 120, minHeight: 140)
                        .padding()
                        .background(Color("buttonBackground"))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                }
            }
            .padding(.horizontal)
            .offset(y: -100)
            Spacer()
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView()
        }
    }
}

struct CalendarView: View {
    let eventDates: Set<DateComponents> = [
        // FILL THIS IN WITH ACTUAL DATE DATA
        DateComponents(year: 2025, month: 7, day: 10),
    ]

    @State private var selectedDates: Set<DateComponents> = []
    @State private var previouslySelected: Set<DateComponents> = []
    @State private var activeDate: IdentifiableDate? = nil
    @State private var isInitializing = true


    var body: some View {
        MultiDatePicker("Calendar", selection: $selectedDates, in: ..<Date())
            .onAppear {
                selectedDates = eventDates
                previouslySelected = eventDates
                
                DispatchQueue.main.async {
                    isInitializing = false
                }
            }
            .onChange(of: selectedDates.count) { oldCount, newCount in
                guard !isInitializing else { return }
                
                print(oldCount, newCount)
                
                // Compare with the "canonical" state (eventDates)
                let userAddedDates = selectedDates.subtracting(eventDates)
                let userRemovedDates = eventDates.subtracting(selectedDates)
                
                var tappedDate: Date?
                
                if let addedComponents = userAddedDates.first {
                    tappedDate = Calendar.current.date(from: addedComponents)
                    print("User tried to select: \(String(describing: tappedDate))")
                } else if let removedComponents = userRemovedDates.first {
                    tappedDate = Calendar.current.date(from: removedComponents)
                    print("User tried to deselect: \(String(describing: tappedDate))")
                }
                
                if let date = tappedDate {
                    activeDate = IdentifiableDate(date: date)
                }
                
                // Reset to original
                selectedDates = eventDates
            }
            .padding(.horizontal)
            .sheet(item: $activeDate) { wrapper in
                let date = wrapper.date
                VStack {
                    Text("Workout on \(date.formatted(.dateTime.month().day().year()))")
                }
                .presentationDetents([.medium, .large])
            }
    }
}

struct IdentifiableDate: Identifiable {
    var id: Date { date }
    let date: Date
}

struct DatabaseView: View {
    var body: some View {
        Text("Under Construction n shit numba 2")
    }
}

class CameraManager: NSObject, ObservableObject {
    private let session = AVCaptureSession()
    private var videoOutput = AVCaptureMovieFileOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentDevice: AVCaptureDevice?
    
    @Published var isRecording = false
    
    override init() {
        super.init()
        configureSession()
    }
    
    private func configureSession() {
        session.beginConfiguration()

        session.sessionPreset = .hd1280x720  // 720p resolution

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            print("Failed to set up input")
            return
        }
        currentDevice = device
        session.addInput(input)

        // Set framerate to 30fps
        try? device.lockForConfiguration()
        device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
        device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
        device.unlockForConfiguration()

        // Add output (no audio)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        session.commitConfiguration()
    }

    
    func startSession() {
        if !session.isRunning {
            session.startRunning()
        }
    }
    
    func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        previewLayer = layer
        return layer
    }
    
    func toggleRecording() {
        if isRecording {
            videoOutput.stopRecording()
        } else {
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
            videoOutput.startRecording(to: outputURL, recordingDelegate: self)
        }
        isRecording.toggle()
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("Finished recording to: \(outputFileURL)")
    }
}

struct CameraPreview: UIViewControllerRepresentable {
    @ObservedObject var cameraManager: CameraManager

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        let previewLayer = cameraManager.getPreviewLayer()
        previewLayer.frame = UIScreen.main.bounds
        controller.view.layer.addSublayer(previewLayer)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

struct CameraView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var cameraManager = CameraManager()

    var body: some View {
        ZStack {
//            CameraPreview(cameraManager: cameraManager)
//                .ignoresSafeArea()
            Color.black
                .ignoresSafeArea(edges: .all)

            VStack {
                Text("Have the instructions go here.")
                    .foregroundStyle(.white)
                    .padding(.top, 50)

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
//                        cameraManager.toggleRecording()
                    }) {
                        Circle()
                            .fill(cameraManager.isRecording ? .gray : .red)
                            .frame(width: 70, height: 70)
                    }
                    Spacer()
                    Button(action: {
                        // Placeholder for a future action
                    }) {
                        Image(systemName: "square.on.square")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
//            AVCaptureDevice.requestAccess(for: .video) { granted in
//                if granted {
//                    cameraManager.startSession()
//                }
//            }
        }
        .onDisappear {
//            cameraManager.stopSession()
        }
    }
}


#Preview {
    ContentView()
}
