//
//  CameraController.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 19.04.23.
//

import SwiftUI
import AVFoundation

class CameraViewController: UIViewController {

    var featureDetector: FeatureDetector?
    var model: CameraViewModel?
    
    private var permissionGranted = false
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let audioDataOutput = AVCaptureAudioDataOutput()
    
    private var movieFileOutput = AVCaptureMovieFileOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    let videoOutputQueue = DispatchQueue(
        label: "Video Output Queue",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
    
    var preview: AVCaptureVideoPreviewLayer? {
        previewLayer
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        featureDetector?.viewDelegate = self
        checkPermission()
//        faceDetector?.viewDelegate = self
//        configureMetal()
        //configureCaptureSession()
        sessionQueue.async { [unowned self] in
            guard permissionGranted else {return}
            self.setupCaptureSession()
        }
        
        
    }
}
// MARK: - Setup video capture
extension CameraViewController {
    
    func checkPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            self.permissionGranted = true
            break
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
                if !granted {
                    fatalError("Camera permission is required.")
                }
                self.permissionGranted = true
                self.sessionQueue.resume()
            }
        default:
            fatalError("Camera permission is required.")
        }
    }
    
    func setDeviceFormat(for device: AVCaptureDevice, fps:Float64 = 60){
        let width: Int = 1920
        let height: Int = 1080
        let minFrameRate: Float64 = fps
        
        var bestFormat: AVCaptureDevice.Format?
        var currentFrameRateRange: AVFrameRateRange?
        print("setDeviceFormat")
        for format in device.formats {
            print("current checked format is: ", format)
            //first check for resolution (width)
            if format.formatDescription.dimensions.width == width && format.formatDescription.dimensions.height == height {
                for range in format.videoSupportedFrameRateRanges {
                    print("framerate-range: ",range)
                    
                    //if framerate is possible
                    if range.maxFrameRate == minFrameRate {
                        bestFormat = format
                        print(format)
                        currentFrameRateRange = range
                        
                        break //End if suitable format is found
                    }
                        
                }
            }
        }//end format loop
        
        if let bestFormat = bestFormat,
           let currentFrameRateRange = currentFrameRateRange {
            do {
                try device.lockForConfiguration()
                
                device.activeFormat = bestFormat
                let duration = currentFrameRateRange.minFrameDuration
                device.activeVideoMaxFrameDuration = duration
                device.activeVideoMinFrameDuration = duration
                print("duration \(duration)")
                device.unlockForConfiguration()
                
            } catch let error {
                print("error in setting Device Format with error: \(error.localizedDescription)")
            }
        }
    }
    
    func setupCaptureSession(){
        //capture device
        //session.sessionPreset = .hd1920x1080
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
        
        guard let videoDevice = discoverySession.devices.first(where: { device in
            device.position == .front
        }) else {
            print("could not find correct front-facing-camera")
            return
        }
        
        
        
        //setup Microphone
        guard let audioDevice = AVCaptureDevice.default(for: .audio)
        else {
            print("could not find microphone")
            return
        }
        
        //Add Input
        do {
            session.beginConfiguration()
            let cameraInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(cameraInput){
                session.addInput(cameraInput)
                setDeviceFormat(for: cameraInput.device,fps: 60)
                print(cameraInput.device.activeFormat)
            }
            
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            if session.canAddInput(audioInput){
                session.addInput(audioInput)
            }
            
        //add Output
        //Video Output
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            videoOutput.alwaysDiscardsLateVideoFrames = true
            // Add the video output to the capture session
            if session.canAddOutput(videoOutput) {
                videoOutput.setSampleBufferDelegate(featureDetector, queue: videoOutputQueue)
                session.addOutput(videoOutput)
            }
            
            //audio Output
            if session.canAddOutput(audioDataOutput) {
                audioDataOutput.setSampleBufferDelegate(featureDetector, queue: videoOutputQueue)
                session.addOutput(audioDataOutput)
            }
            
            // disabling mirroring
            if let connection = videoOutput.connection(with: .video) {
                if connection.isVideoMirroringSupported {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = false
                }
            }
            
            
            
            //preview Layer
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            if let connection = previewLayer?.connection {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
                // turn off mirroring (might be awkward)
                if connection.isVideoMirroringSupported {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = false
                }
            }
            previewLayer?.videoGravity = .resizeAspect
            // Adjust the contentsRect to specify which part of the video is visible
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self,
                      let layer = self.previewLayer else {return}
                previewLayer?.frame = view.bounds
                
                self.view.layer.addSublayer(layer)
            }
            //Commit Configuration and Start Session
            session.commitConfiguration()
            session.startRunning()
            
        } catch let error {
            print("something went wrong, configurong the session")
            print(error.localizedDescription)
        }
        
        
    }
}
    
// MARK: FaceDetectorDelegate methods

extension CameraViewController: FeatureDetectorDelegate {
  func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect {
    guard let previewLayer = previewLayer else {
      return CGRect.zero
    }

      return previewLayer.layerRectConverted(fromMetadataOutputRect: rect)
  }

}


struct CameraViewRepresentable: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = CameraViewController
    private(set) var model: CameraViewModel
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    func makeUIViewController(context: Context) -> CameraViewController {
      let featureDetector = FeatureDetector()
      featureDetector.model = model

      let viewController = CameraViewController()
      viewController.featureDetector = featureDetector
      viewController.model = model

      return viewController
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) { }
}
