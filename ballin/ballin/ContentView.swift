import SwiftUI
import AVFoundation
import PhotosUI

struct ContentView: View {
    var body: some View {
        // Basic TabView setup
        TabView {
            HomeView()
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, alignment: .center)
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
                Text("Nice afternoon.")
                    .font(.title)
                    .fontWeight(.regular)
                    .padding(.top, 42)
                Text("Want to get some practice in today?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, -4)
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
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = cameraManager.getPreviewLayer()
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        let screenWidth = UIScreen.main.bounds.width
        let height = screenWidth * (16.0 / 9.0)
        cameraManager.getPreviewLayer().frame = CGRect(x: 0, y: 0, width: screenWidth, height: height)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        let previewLayer = cameraManager.getPreviewLayer()
        previewLayer.frame = UIScreen.main.bounds
        controller.view.layer.addSublayer(previewLayer)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}


struct VideoPickerView: View {
    @State private var showPicker = false
    @State private var selectedVideoURL: URL?

    var body: some View {
        VStack(spacing: 20) {
            Button("Pick a Video") {
                showPicker = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if let url = selectedVideoURL {
                Text("Selected video: \(url.lastPathComponent)")
                    .font(.caption)
                    .padding()
            }
        }
        .sheet(isPresented: $showPicker) {
            VideoPicker(selectedVideoURL: $selectedVideoURL)
        }
    }
}


struct VideoPicker: UIViewControllerRepresentable {
    @Binding var selectedVideoURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VideoPicker

        init(_ parent: VideoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let itemProvider = results.first?.itemProvider,
                  itemProvider.hasItemConformingToTypeIdentifier("public.movie") else { return }

            itemProvider.loadFileRepresentation(forTypeIdentifier: "public.movie") { url, error in
                guard let url = url else {
                    print("Error loading video: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                // Create a unique filename to avoid collisions
                let fileName = UUID().uuidString + ".mov"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

                do {
                    // Remove if something with same name exists (super rare but safe)
                    if FileManager.default.fileExists(atPath: tempURL.path) {
                        try FileManager.default.removeItem(at: tempURL)
                    }

                    // Copy the video to your temp directory
                    try FileManager.default.copyItem(at: url, to: tempURL)

                    DispatchQueue.main.async {
                        self.parent.selectedVideoURL = tempURL
                    }
                } catch {
                    print("Error copying video file: \(error.localizedDescription)")
                }
            }

        }
    }
}


struct CameraView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var cameraManager = CameraManager()
    @State private var showPicker = false
    @State private var selectedVideoURL: URL?

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(edges: .all)
            CameraPreview(cameraManager: cameraManager)
                .frame(width: UIScreen.main.bounds.width,
                           height: UIScreen.main.bounds.width * (16.0 / 9.0))
                .clipped()
                .ignoresSafeArea()
                .offset(y: 10)
            VStack {
                Text("Have the instructions go here.")
                    .foregroundStyle(.white)
                    .font(.caption)

                Spacer()

                HStack {
                    Spacer()
                    Button(action: {
                        showPicker = true
                    }) {
                        Image(systemName: "square.on.square")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 27)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                    Button(action: {
                        cameraManager.toggleRecording()
                    }) {
                        RoundedRectangle(cornerRadius: cameraManager.isRecording ? 10 : 50)
                            .fill(.red)
                            .frame(width: 70, height: 70)
                    }
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 21, height: 21)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    cameraManager.startSession()
                }
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .sheet(isPresented: $showPicker) {
            VideoPicker(selectedVideoURL: $selectedVideoURL)
        }
    }
}

#Preview {
    CameraView()
}
