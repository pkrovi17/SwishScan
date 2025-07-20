import SwiftUI
import AVFoundation
import PhotosUI
import Photos


struct ContentView: View {
    @AppStorage("isDarkMode") var isDarkMode = false
    @State private var selectedTab = 0
    
    var body: some View {
        // Basic TabView setup
        TabView(selection: $selectedTab) {
            HomeView(isDarkMode: $isDarkMode, selectedTab: $selectedTab)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, alignment: .center)
                .tabItem {
                    Image(systemName: "house.fill")
                        .padding(.top, 30)
                    Text("Home")
                }
                .tag(0)
            CalendarView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("Archive")
                }
                .tag(1)
            DatabaseView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Database")
                }
                .tag(2)
        }
            .onAppear() {
                UITabBar.appearance().backgroundColor = UIColor.systemBackground
        }
            .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}


struct HomeView: View {
    @Binding var isDarkMode: Bool
    @Binding var selectedTab: Int
    @State private var showCamera = false
    @State private var showResults = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDismissing = false
    @State private var isAccuracyTest = false
    @State private var greetingAdjective: String?
    @State private var greetingTime = "night"
    
    var body: some View {
        ZStack {
            VStack {
                // Top settings and welcome
                VStack (alignment: .leading){
                    Text("\(greetingAdjective ?? "Good") \(greetingTime).")
                        .font(.title)
                        .fontWeight(.regular)
                        .padding(.top, 42)
                    Text("Want to get some practice in today?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, -4)
                }
                Spacer()
                // Accuracy and Form buttons
                HStack(spacing: 12) {
                    ForEach(["Accuracy", "Form"], id: \.self) { title in
                        Button(action: {
                            if title == "Accuracy" {
                                isAccuracyTest = true
                            } else {
                                isAccuracyTest = false
                            }
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
                
                Button(action: {
                    selectedTab = 1
                }) {
                    VStack {
                        Text("99 Day Streak")
                            .foregroundColor(Color("secondaryButtonText"))
                            .bold()
                    }
                    .frame(maxWidth: 282, maxHeight: 36)
                    .padding()
                    .background(Color("secondaryButtonBackground"))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .offset(y: -96) // -100 + 4 for equal spacing
                
                // Settings and dark mode buttons
                HStack (spacing: 12) {
                    Button(action: {
                        // find something for this
                    }) {
                        VStack {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(Color("secondaryButtonText"))
                                .frame(height: 24)
                        }
                        .frame(maxWidth: 120, maxHeight: 36)
                        .padding()
                        .background(Color("secondaryButtonBackground"))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    .offset(y: -92) // -100 + 8 for equal spacing
                    
                    Button(action: {
                        isDarkMode.toggle()
                    }) {
                        VStack {
                            Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(Color("secondaryButtonText"))
                                .frame(height: 24)
                        }
                        .frame(maxWidth: 120, maxHeight: 36)
                        .padding()
                        .background(Color("secondaryButtonBackground"))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    .offset(y: -92) // -100 + 8 for equal spacing
                }
            }
            
            if showResults {
                ResultsView(day: Date()) // fill in with real date
                    .frame(maxWidth: .infinity, minHeight: 600)
                    .padding()
                    .background(.thickMaterial)
                    .cornerRadius(15)
                    .offset(y: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if value.translation.height > 0 {
                                    dragOffset = value.translation.height
                                }
                            }
                            .onEnded { value in
                                let dragDistance = value.translation.height
                                let predictedDistance = value.predictedEndTranslation.height
                                let dragVelocity = predictedDistance - dragDistance

                                let shouldDismissByDistance = dragDistance > 150
                                let shouldDismissByVelocity = dragVelocity > 150

                                if shouldDismissByDistance || shouldDismissByVelocity {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        dragOffset = UIScreen.main.bounds.height
                                        isDismissing = true
                                    }

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        showResults = false
                                        dragOffset = 0
                                    }
                                } else {
                                    withAnimation {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: showResults)
                    .onDisappear {
                        dragOffset = 0
                        isDismissing = false
                    }
            }
        }
        .onChange(of: isDismissing) { oldValue, newValue in
            if oldValue == false && newValue == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    showResults = false
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(showResults: $showResults, isAccuracyTest: $isAccuracyTest)
                .preferredColorScheme(.dark)
        }
        .onAppear {
            // Determining the greeting by seeing the time
            let hour = Calendar.current.component(.hour, from: Date())
            if hour >= 6 && hour < 12 {
                greetingTime = "morning"
            } else if hour >= 12 && hour < 17 {
                greetingTime = "afternoon"
            } else if hour >= 17 && hour < 21 {
                greetingTime = "evening"
            } else {
                greetingTime = "night"
            }
            
            // Get random adjective
            let items = ["Nice", "Good", "Beautiful"]
            greetingAdjective = items.randomElement()
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
    
    let dateRange: Range<Date> = {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2025, month: 7, day: 1))!
        let end = Calendar.current.startOfDay(for: Date())
        return start..<calendar.date(byAdding: .day, value: 0, to: end)!
    }()

    var body: some View {
        MultiDatePicker("Calendar", selection: $selectedDates, in: dateRange)
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
                    Text("You clicked: \(date.formatted(.dateTime.month().day().year()))")
                }
                .presentationDetents([.large])
            }
    }
}


struct IdentifiableDate: Identifiable {
    var id: Date { date }
    let date: Date
}


struct DatabaseView: View {
    var body: some View {
        Text("Under Construction n shit")
    }
}


class CameraManager: NSObject, ObservableObject {
    private let session = AVCaptureSession()
    private var videoOutput = AVCaptureMovieFileOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentDevice: AVCaptureDevice?
    
    @Published var isRecording = false
    
    var recordingType: String = "raw"
    
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
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = formatter.string(from: Date())
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(recordingType)_\(timestamp).mov")
            videoOutput.startRecording(to: outputURL, recordingDelegate: self)
        }
        isRecording.toggle()
    }
}


extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("Finished recording to: \(outputFileURL)")

        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else {
                print("No permission to save to photo library!")
                return
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
            }) { success, error in
                if let error = error {
                    print("Error saving video to photo library: \(error)")
                } else {
                    print("Saved video to photo library!")
                }
            }
        }
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
    var recordingType: String = "raw"

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
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                let timestamp = formatter.string(from: Date())
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(self.parent.recordingType)_\(timestamp).mov")



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
                    print("Copied file to: \(tempURL.path)")
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
    @Binding var showResults: Bool
    @State private var selectedVideoURL: URL?
    @Binding var isAccuracyTest: Bool
    @State private var instructions: String?
    @State private var instructionsVisible = true
    @State private var timer: Timer?
    @State private var elapsedTime: Double = 0.0

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(edges: .all)
            CameraPreview(cameraManager: cameraManager)
                .frame(width: UIScreen.main.bounds.width,
                           height: UIScreen.main.bounds.width * (16.0 / 9.0))
                .clipped()
                .ignoresSafeArea()
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .offset(y: 10)
            VStack {
                Text(formattedTime)
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(.white)
                Text("\(instructions ?? "StupidScan™")")
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, 10)
                    .opacity(instructionsVisible ? 1 : 0)
                    .frame(maxWidth: 300, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            instructionsVisible.toggle()
                        }
                    }

                Spacer()

                HStack {
                    Spacer()
                    // Attach photos
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
                    // Record button
                    Button(action: {
                        instructionsVisible = false
                        cameraManager.recordingType = isAccuracyTest ? "accuracy" : "form"
                        cameraManager.toggleRecording()
                        if !cameraManager.isRecording {
                            dismiss()
                            stopTimer()
                            showResults = true
                        } else {
                            startTimer()
                        }
                    }) {
                        RoundedRectangle(cornerRadius: cameraManager.isRecording ? 10 : 50)
                            .fill(.red)
                            .frame(width: 70, height: 70)
                    }
                    Spacer()
                    // Close camera
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
            
            if isAccuracyTest {
                instructions = "Show the entire half-court and hoop in frame. Shoot from different spots on the court. Take 10-15 shots."
            } else {
                instructions = "Keep all of your arms in frame when shooting. The hoop doesn’t need to be shown. Take 5 shots."
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .sheet(isPresented: $showPicker) {
            VideoPicker(
                    selectedVideoURL: $selectedVideoURL,
                    recordingType: isAccuracyTest ? "accuracy" : "form"
                )
        }
        .onChange(of: selectedVideoURL) { oldValue, newValue in
            if oldValue == nil && newValue != nil {
                dismiss()
                showResults = true
            }
        }
    }
    var formattedTime: String {
            let totalHundredths = Int(elapsedTime * 100)
            let minutes = totalHundredths / 6000
            let seconds = (totalHundredths % 6000) / 100
            let hundredths = totalHundredths % 100
            return String(format: "%02d:%02d:%02d", minutes, seconds, hundredths)
        }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            elapsedTime += 0.01
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}


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


#Preview {
    ContentView()
}
