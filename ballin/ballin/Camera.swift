import SwiftUI
import AVFoundation
import PhotosUI
import Photos


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
