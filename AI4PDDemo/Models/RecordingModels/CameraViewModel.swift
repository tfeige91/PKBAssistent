//
//  CameraViewModel.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 20.04.23.
//

import Combine
import CoreGraphics
import UIKit
import Vision
import AVFoundation

enum UPDRSItemName: String, CaseIterable {
    case Sitting
    case MovementTremor
    case Fingertap
    case ToeTapping
    case PronationSupination
    case Walking
    
}

enum Site: String, CaseIterable {
    case left
    case right
    case none
}
//Overall
enum BodyObservation<T> {
  case bodyFound(T)
  case bodyNotFound
  case errored(Error)
}

enum RecordingPosition{
    case sitting
    case standing
}

enum CameraViewModelAction {
    //View Setup and configuration action
    case windowSizeDetected(CGRect)
    
    //Body detection actions
    case noHumanDetected
    case humanObservationDetected(BodyGeometryModel)
    
    //Writing Video
    case prepareWriter(CMSampleBuffer)
    case writingVideo(CMSampleBuffer)
    case stopWriting
}

enum BodyDetectedState {
    case bodyDetected
    case noBodyDetected
    case BodyDetectionErrored
}

enum BodyBoundsState {
  case unknown
  case detectedBodyTooSmall
  case detectedBodyTooLarge
  case detectedBodyOffCentre
  case detectedBodyAppropriateSizeAndPosition
}

enum Instructions: String {
    case comeNear = "bitte kommen Sie noch einen Schritt näher"
    case goAway = "bitte gehen Sie etwas weiter zurück"
    case beginn = "Ich werde Ihnen helfen, die richtige Position einzunehmen. Bitte stellen Sie sich vor einen Stuhl so, dass Sie genau im roten Kästchen stehen. Sobald Sie gut positioniert sind, wird das Kästchen grün."
    case correct = "Sehr gut! Wir können nun mit der Aufgabe beginnen. Ich starte die Aufnahme in 3...2...1. Die Aufnahme läuft."
}


struct BodyGeometryModel {
    let boundingBox: CGRect
}

final class CameraViewModel: NSObject, ObservableObject {
    
    //MARK: - Show View Components
    @Published var showRecordingIndicator = false
    @Published var showInstructionOverlay = false
    @Published var showBodyBoundingBox = false
    @Published var showLayoutGuidingView = true
    @Published var showFinishedRecordingRatingView = false
    @Published var dismissRecordingView = false
    
    @Published var currentTip = -1
    //@Published var speakTip = false
    let mainScreenExplanations = [
        "Das ist der Hilfeknopf. Tippen Sie lange, und ich erkläre Ihnen alle Funktionen der einzelnen Knöpe noch einmal.",
        "Mit diesem Knopf können Sie die Sprachsteuerung starten. Sagen Sie Übung, um eine Aufnahme zu beginnen. Sagen Sie Chat mit einem Arzt, um die Fragefunktion zu öffnen. Sagen Sie Videotagebuch, um sich alle Aufnahmen nocheinmal anschauen zu können. Oder sagen Sie Visite Vorbereiten, um sich den Verlauf Ihrer Symptome anzusehen.",
        "Hier haben Sie die Möglichkeit, Ihrem Arzt Fragen zu stellen",
        "Hier können Sie eine neue Aufnahme starten",
        "Hier können Sie Ihre Aufnahmen ansehen",
        "Hier öffnen Sie die Ansicht für Ihren Arzt oder Ihre Ärztin. Sie haben auch die Möglichkeit, selbst einen Überblick über den Verlauf Ihrer Symptome zu gewinnen.",
        "Hier öffnen Sie den Abschlussfragebogen. Es ist wichtig, dass sie eine aktive Internetverbindung besitzen, um den Fragebogen ausfüllen zu können."
    ]
    
    let mainScreenExplanationFileNames = [
        "Helpbutton",
        "Speechbutton",
        //"Chatbutton",
        "RecordingButton",
        "ShowRecordsButton",
        "DoctorView",
        "QuestionnaireButton"
    ]
    
    // MARK: - Publishers of derived state
    @Published private(set) var hasDetectedValidBody: Bool
    
    @Published private(set) var isAcceptableBounds: BodyBoundsState {
      didSet {
        calculateDetectedBodyValidity()
      }
    }
    
    // MARK: - Publishers of Vision data directly
    @Published private(set) var bodyDetectedState: BodyDetectedState
    
    //Will be called when a Body-Observation was found
    @Published private(set) var bodyGeometryState: BodyObservation<BodyGeometryModel> {
      didSet {
          processUpdatedBodyGeometry()
      }
    }
    
    //MARK: - STATIC UPDRS Items
    var updrsItems = [
        UPDRSItem(orderNumber: 0,
                  date: nil,
                  itemName: UPDRSItemName.Sitting.rawValue,
                  displayName: "Ruhetremor",
                  recordingPosition: .sitting,
                  instructionTest: "Versuchen Sie nun einfach entspannt zu sitzen und von einhundert in siebener Schritten herunterzuzählen.",
                  site: .none,
                  url: nil,
                  rating: nil,
                  showInstructionByDefult: false,
                  recordingDuration: 5),
        UPDRSItem(orderNumber: 1,
                  date: nil,
                  itemName: UPDRSItemName.MovementTremor.rawValue,
                  displayName: "Bewegungstremor rechts",
                  recordingPosition: .sitting,
                  instructionTest: "Wir beginnen zunächst mit dem rechten Arm. Strecken Sie zunächst Ihren Arm mit ausgestrecktem Zeigefinger weit nach vorn und führen Sie anschließend den Zeigefinger an Ihre Nasenspitze. Danach strecken Sie den Arm wieder weit aus. Wiederholen Sie das bitte fünf mal.",
                  site: .right,
                  url: nil,
                  rating: nil,
                  showInstructionByDefult: false,
                  recordingDuration: 6
                 ),
        UPDRSItem(orderNumber: 2,
                  date: nil,
                  itemName: UPDRSItemName.MovementTremor.rawValue,
                  displayName: "Bewegungstremor links",
                  recordingPosition: .sitting,
                  instructionTest: "Bitte führen Sie die Übung nun genau so mit dem linken Arm aus.",
                  site: .left,
                  url: nil,
                  rating: nil,
                  showInstructionByDefult: false,
                  recordingDuration: 6
                 ),
        UPDRSItem(orderNumber: 3,
                  date: nil,
                  itemName: UPDRSItemName.Fingertap.rawValue,
                  displayName: "Finger Tippen rechts",
                  recordingPosition: .sitting,
                  instructionTest: "Wir beginnen zunächst mit der rechten Hand. Berühren Sie mit Ihrem rechten Zeigefinger die Kuppe Ihres Daumens. Öffnen Sie nun beide Finger soweit wie möglich von einander und führen Sie anschließend die Fingerkuppen wieder zusammen. Wiederholen Sie das nun bitte zehn mal und versuchen Sie bitte die Bewegung so schnell wie möglich und mit der größtmöglichen Amplitude auszuführen.",
                  site: .right,
                  url: nil,
                  rating: nil,
                  showInstructionByDefult: true,
                  recordingDuration: 4),
        UPDRSItem(orderNumber: 4,
                  date: nil,
                  itemName: UPDRSItemName.Fingertap.rawValue,
                  displayName: "Finger Tippen links",
                  recordingPosition: .sitting,
                  instructionTest: "Bitte führen Sie das Finger Tippen nun genau so mit der linken Hand aus.",
                  site: .left,
                  url: nil,
                  rating: nil,
                  showInstructionByDefult: false,
                  recordingDuration: 4),
        UPDRSItem(orderNumber: 5,
                  date: nil,
                  itemName: UPDRSItemName.PronationSupination.rawValue,
                  displayName: "Pronation und Supination rechts",
                  recordingPosition: .sitting,
                  instructionTest: "Strecken Sie den rechten Arm vor Ihrem Körper mit der Handfläche nach unten aus. Wenden Sie nun Ihre Handfläche mit größtmöglicher Amplitude alternierend zehn Mal nach oben und nach unten",
                  site: .right,
                  url: nil,
                  rating: nil,
                  showInstructionByDefult: false,
                  recordingDuration: 5),
        UPDRSItem(orderNumber: 6,
                  date: nil,
                  itemName: UPDRSItemName.PronationSupination.rawValue,
                  displayName: "Pronation und Supination links",
                  recordingPosition: .sitting,
                  instructionTest: "Bitte führen Sie die Übung nun genau so mit dem linken Arm aus.",
                  site: .left,
                  url: nil,
                  rating: nil,
                  showInstructionByDefult: false,
                  recordingDuration: 5),
        UPDRSItem(orderNumber: 7,
                  date: nil,
                  itemName: UPDRSItemName.ToeTapping.rawValue,
                  displayName: "Fußtippen rechts",
                  recordingPosition: .sitting,
                  instructionTest: "Setzen Sie sich dafür bitte möglichst aufrecht hin. Stellen Sie Ihre Füße so auf den Boden, dass sie eine Bequeme Position für ihre Ferse einnehmen. Nun Tippen Sie bitte mit den Zehen wieder zehn mal und mit größtmöglicher Amplitude und schnellstmöglich auf den Boden. Wir beginnen wieder mit dem rechten Fuß.",
                  site: .right,
                  url: nil,
                  rating: nil,
                  showInstructionByDefult: true,
                  recordingDuration: 5),
        UPDRSItem(orderNumber: 8,
                  date: nil,
                  itemName: UPDRSItemName.ToeTapping.rawValue,
                  displayName: "Fußtippen Links",
                  recordingPosition: .sitting,
                  instructionTest: "Bitte führen Sie die gleiche Übung nun einmal mit ihrem linken Fuß aus.",
                  site: .left,
                  url: nil,
                  rating: nil,
                  showInstructionByDefult: false,
                  recordingDuration: 5),
        UPDRSItem(orderNumber: 9,
                  date: nil,
                  itemName: UPDRSItemName.Walking.rawValue,
                  displayName: "Gehen",
                  recordingPosition: .standing,
                  instructionTest: "Laufen Sie auf die Kamera zu, solange Sie vollständig im Bild sind. Drehen Sie sich dann einmal um einhunderachtzig Grad und laufen wieder zurück.",
                  site: .none,
                  url: nil,
                  rating: nil,
                  showInstructionByDefult: false,
                  recordingDuration: 12
                 )
    ]
    
    //Published Variables TestItems
    @Published var currentItem: Int = 0
    
    //Trigger other Views
    @Published var showHelpOverlay = false
    
    
    // MARK: - Private variables
    //@Published var bodyLayoutGuideFrame = CGRect(x: 0, y: -30, width: 370, height: 660)
    @Published var bodyLayoutGuideFrame = CGRect(x: 0, y: -30, width: 370, height: 800)
    //@Published var bodyLayoutGuideFrame = CGRect(x: 0, y: -120, width: 370, height: 270)
    //Combine Streaming variables to propagate writing status back
    let shouldRecord = PassthroughSubject<Void, Never>()
    let isRecording = PassthroughSubject<Void, Never>()
    let didFinishWriting = PassthroughSubject<Void, Never>()
    let startedNextTrial = PassthroughSubject<Void, Never>()
    
    //Speech Synthesizer
    @Published var speakHelp: Bool = true
    var synthesizer = AVSpeechSynthesizer()
    var timer: Timer?
    var currentInstruction: String = ""
    
    //MARK: - Properties for the audioInstructions
    var audioPlayer: AVAudioPlayer?
    var currentAudioFile: String = ""
    
    func playAudio(subdirectory: String, fileName:String,fileExtension:String = "wav"){
        
        if let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) {
                    do {
                        audioPlayer = try AVAudioPlayer(contentsOf: url,fileTypeHint: "wav")
                        audioPlayer?.delegate = self
                        audioPlayer?.prepareToPlay()
                        audioPlayer?.play()
                        currentAudioFile = fileName
                    } catch {
                        print("Error loading audio file: \(error.localizedDescription)")
                    }
                }
        else{
            print("no audio File at \(fileName)")
        }
    }
    
    //MARK: - Properties for Recording
    var movieFileOutput: AVCaptureMovieFileOutput? = nil
    //hacky approach
    var videoPreviewLayerOrientation = AVCaptureVideoOrientation(rawValue: 1)
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?
    
    //Saving Video Files
    private var assetWriter: AVAssetWriter? = nil
    private var assetWriterInput: AVAssetWriterInput? = nil
    private let writingQueue = DispatchQueue(label: "videoWritingQueue")
    var sessionNumber: Int?
    var sessionURL: URL?
    var itemURL: URL?
    var sessionAtSourceTime: CMTime?
    var frame = 0
    var stopRecordingSet = false
    var stopped = false
    let fileManager = VideoFileManager.instance
    
    //CoreData
    private let viewContext = PersistenceController.shared.viewContext
    private var session: Session?
    
    override init() {
        
        self.hasDetectedValidBody = false
        self.isAcceptableBounds = .unknown
        self.bodyDetectedState = .noBodyDetected
        self.bodyGeometryState = .bodyNotFound
        
        super.init()
        
        synthesizer.delegate = self
    }
    
}

extension CameraViewModel {
    func perform(action: CameraViewModelAction){
        switch action {
        case .windowSizeDetected(let windowRect):
            handleWindowSizeChanged(toRect: windowRect)
        case .noHumanDetected:
            publishNoBodyObserved()
        case .humanObservationDetected(let bodyObservation):
            publishBodyObservation(bodyObservation)
        case .writingVideo(let sampleBuffer):
            //startRecording()
            writeVideo(sampleBuffer: sampleBuffer)
        case .prepareWriter(let sampleBuffer):
            prepareWriter(sampleBuffer: sampleBuffer)
        case .stopWriting:
            print("stop writing")
        }
    
    }
    
    // MARK: Action handlers

    private func handleWindowSizeChanged(toRect: CGRect) {
      bodyLayoutGuideFrame = CGRect(
        x: toRect.midX - bodyLayoutGuideFrame.width / 2,
        y: toRect.midY - bodyLayoutGuideFrame.height / 2,
        width: bodyLayoutGuideFrame.width,
        height: bodyLayoutGuideFrame.height
      )
    }
    
    private func publishNoBodyObserved() {
      DispatchQueue.main.async { [self] in
          bodyDetectedState = .noBodyDetected
          bodyGeometryState = .bodyNotFound
      }
    }
    
    private func publishBodyObservation(_ bodyGeometryModel: BodyGeometryModel) {
      DispatchQueue.main.async { [self] in
          bodyDetectedState = .bodyDetected
          //the didset above will call processUpdatedBodyGeometry
          bodyGeometryState = .bodyFound(bodyGeometryModel)
      }
    }
    
    
    //record Video to File
    
    //MARK: - Helpers
    func invalidateBodyGeometryState() {
      isAcceptableBounds = .unknown
    }
    
    func processUpdatedBodyGeometry() {
      switch bodyGeometryState {
      case .bodyNotFound:
        invalidateBodyGeometryState()
      case .errored(let error):
        print(error.localizedDescription)
        invalidateBodyGeometryState()
      case .bodyFound(let bodyGeometryModel):
          let boundingBox = bodyGeometryModel.boundingBox

        updateAcceptableBounds(using: boundingBox)
      }
    }
    
    func updateAcceptableBounds(using boundingBox: CGRect) {
        //get the Value from the lower end of the bounding box
        let origin = boundingBox.origin
        let originalSize = bodyLayoutGuideFrame.size
        switch updrsItems[currentItem].recordingPosition {
        case .sitting: self.bodyLayoutGuideFrame = CGRect(x: 0, y: -50, width: boundingBox.width*1.05, height: boundingBox.height*1.01)
        case .standing: self.bodyLayoutGuideFrame = CGRect(x: 0, y: updrsItems[currentItem].itemName == UPDRSItemName.Walking.rawValue ? -350:   -50, width: boundingBox.width*1.05, height: boundingBox.height * 1.01)
        }
        
        
        
        print("DEBUG: BOUNDING BOX: \(boundingBox.minY)")
        print("DEBUG: LayoutGuideFrame: \(self.bodyLayoutGuideFrame.minY)")
        
        let calculatedValue = boundingBox.minY * -1 - bodyLayoutGuideFrame.minY
        print("DEBUG: Calculated value \(calculatedValue)")

        
        // First, check face is roughly the same size as the layout guide
//        if boundingBox.width > 1.2 * bodyLayoutGuideFrame.width {
//            isAcceptableBounds = .detectedBodyTooLarge
//        } else if boundingBox.width * 2 < bodyLayoutGuideFrame.width {
//            isAcceptableBounds = .detectedBodyTooSmall
//        } else if boundingBox.height * 1.05 < bodyLayoutGuideFrame.height {
//            isAcceptableBounds = .detectedBodyTooSmall
//        } else if boundingBox.height > 1.05 * bodyLayoutGuideFrame.height {
//            isAcceptableBounds = .detectedBodyTooLarge
//        }
        //check if feet are at the bottom of the boundingBox
        if calculatedValue >= -10 {
            isAcceptableBounds = .detectedBodyTooLarge
        }
        else if calculatedValue < -40 {
            isAcceptableBounds = .detectedBodyTooSmall
        }
        else {
            isAcceptableBounds = .detectedBodyAppropriateSizeAndPosition
        }
//        else {
//        // Next, check face is roughly centered in the frame
//        if abs(boundingBox.midX - bodyLayoutGuideFrame.midX) > 50 {
//            isAcceptableBounds = .detectedBodyOffCentre
//        } else if abs(boundingBox.midY - bodyLayoutGuideFrame.midY) > 50 {
//            isAcceptableBounds = .detectedBodyOffCentre
//        } else {
//            isAcceptableBounds = .detectedBodyAppropriateSizeAndPosition
//        }
//      }
        calculateDetectedBodyValidity()
    }
    
    

}

    

//MARK: - Writing Video
extension CameraViewModel {
//    func prepareWriter(sampleBuffer: CMSampleBuffer) {
//                self.sessionAtSourceTime = nil
//                print("prepare Writer")
//                //get the correct URL
//                if self.sessionURL == nil {
//                    guard let (sessionNumber, sessionFolder) = fileManager.getNewSessionFolder() else  {print("could not create Session Folder"); return}
//                    self.sessionNumber = sessionNumber
//                    self.sessionURL = sessionFolder
//                    //Add the current Session to Core data
//                    addSessionToCoreData()
//                }
//                if self.itemURL == nil {
//                    self.itemURL = URL(filePath: self.sessionURL!.path())
//                        .appendingPathComponent("\(self.updrsItems[self.currentItem].itemName)_\(self.updrsItems[self.currentItem].site.rawValue)")
//                        //.appendingPathComponent(self.updrsItems[self.currentItem].site.rawValue)
//                        .appendingPathExtension("mov")
//                }
//        
//                guard let videoOutputUrl = self.itemURL else  {print("could not create FilePath"); return}
//        do {
//            assetWriter = try AVAssetWriter(url: videoOutputUrl, fileType: .mov)
//            
//            // Set Video Settings
//            guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else { return }
//            let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
//            let width = dimensions.width
//            let height = dimensions.height
//            print("width: ", width)
//            let videoOutputSettings: [String: Any] = [
//                AVVideoCodecKey: AVVideoCodecType.h264,
//                AVVideoWidthKey: Int(width),
//                AVVideoHeightKey: Int(height),
//                AVVideoCompressionPropertiesKey: [
//                    AVVideoAverageBitRateKey: 6000000,
//                    AVVideoExpectedSourceFrameRateKey: 60,
//                    //AVVideoMaxKeyFrameIntervalKey: 60,
//                    AVVideoProfileLevelKey: AVVideoProfileLevelH264High40
//                ]
//            ]
//            
//            assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoOutputSettings)
//            
//            guard let assetWriterInput = assetWriterInput, let assetWriter = assetWriter else { return }
//            assetWriterInput.expectsMediaDataInRealTime = true
//            
//            // Adapt to portrait mode
//            assetWriterInput.transform = CGAffineTransform(rotationAngle: .pi / 2)
//            
//            if assetWriter.canAdd(assetWriterInput) {
//                assetWriter.add(assetWriterInput)
//                print("Asset input added")
//            } else {
//                print("No input added")
//            }
//            
//            writingQueue.async { [weak self] in
//                guard let self = self, let writer = self.assetWriter else { return }
//                writer.startWriting()
//            }
//            
//            self.assetWriter = assetWriter
//            self.assetWriterInput = assetWriterInput
//            
//        } catch let error {
//            debugPrint(error.localizedDescription)
//        }
//    }
//
//    // Write Video
//    private func writeVideo(sampleBuffer: CMSampleBuffer) {
//        // Turn off the LayoutGuideFrame
//        DispatchQueue.main.async { [weak self] in
//            self?.showLayoutGuidingView = false
//            self?.showRecordingIndicator = true
//        }
//        
//        print("Write video called")
//        
//        guard !stopped else { return }
//        
//        guard let assetWriter = assetWriter else { return }
//        
//        switch assetWriter.status {
//        case .writing:
//            print("Status: writing")
//        case .failed:
//            if let error = assetWriter.error {
//                print("Status: failed with error: \(error.localizedDescription)")
//            }
//        case .cancelled:
//            print("Status: cancelled")
//        case .unknown:
//            print("Status: unknown")
//        default:
//            print("Status: completed")
//        }
//        
//        // Set the stop once
//        if !stopRecordingSet {
//            stopRecordingSet = true
//            DispatchQueue.main.asyncAfter(deadline: .now() + (updrsItems[currentItem].itemName == UPDRSItemName.Walking.rawValue ? 10 : 3)) {
//                print("Stop recording after")
//                self.stopRecording()
//                print("Stop recording scheduled")
//            }
//        }
//        
//        // Start Writing Session
//        if assetWriter.status == .writing && sessionAtSourceTime == nil {
//            let sessionAtSourceTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
//            self.assetWriter?.startSession(atSourceTime: sessionAtSourceTime)
//        }
//        
//        // Append current SampleBuffer
//        guard let assetWriterInput = self.assetWriterInput else { return }
//        if assetWriter.status == .writing, assetWriterInput.isReadyForMoreMediaData {
//            assetWriterInput.append(sampleBuffer)
//            self.frame += 1
//        }
//    }
    private func prepareWriter(sampleBuffer: CMSampleBuffer) {
        self.sessionAtSourceTime = nil
        print("prepare Writer")
        //get the correct URL
        if self.sessionURL == nil {
            print("generate session URK")
            guard let (sessionNumber, sessionFolder) = fileManager.getNewSessionFolder() else  {print("could not create Session Folder"); return}
            self.sessionNumber = sessionNumber
            self.sessionURL = sessionFolder
            //Add the current Session to Core data
            addSessionToCoreData()
        }
        if self.itemURL == nil {
            self.itemURL = URL(filePath: self.sessionURL!.path())
                .appendingPathComponent("\(self.updrsItems[self.currentItem].itemName)_\(self.updrsItems[self.currentItem].site.rawValue)")
                //.appendingPathComponent(self.updrsItems[self.currentItem].site.rawValue)
                .appendingPathExtension("mov")
        }
        
        guard let videoOutputUrl = self.itemURL else  {print("could not create FilePath"); return}
        
        print("VIDEOOUTPUTURL: ",videoOutputUrl)
        
        //Set Up AVAssetWriter
        do {
            assetWriter = try AVAssetWriter(url: videoOutputUrl, fileType: .mov)
            
            //set Video Settings
            //get samplebuffer properties
            guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {return}
            let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
            let width = dimensions.width
            let height = dimensions.height
            print("width: ",width)
            let videoOutputSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: Int(width),
                AVVideoHeightKey: Int(height)
//                AVVideoCompressionPropertiesKey: [
//                    AVVideoAverageBitRateKey: 6000000,
//                    AVVideoExpectedSourceFrameRateKey: 60,
//                    AVVideoMaxKeyFrameIntervalKey: 60,
//                    AVVideoProfileLevelKey: AVVideoProfileLevelH264High40
//                ]
            ]
            
            assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoOutputSettings)
            
            guard let assetWriterInput = assetWriterInput, let assetWriter = assetWriter else { return }
            assetWriterInput.expectsMediaDataInRealTime = true
            
            // Adapt to portrait mode
            assetWriterInput.transform = CGAffineTransform(rotationAngle: .pi/2)
            
            if assetWriter.canAdd(assetWriterInput) {
                assetWriter.add(assetWriterInput)
                print("asset input added")
            } else {
                print("no input added")
            }
            
            writingQueue.async {[weak self] in
                guard let self = self, let writer = self.assetWriter else {return}
                assetWriter.startWriting()
            }

           
            
            self.assetWriter = assetWriter
            self.assetWriterInput = assetWriterInput
            
            
        } catch let error {
            debugPrint(error.localizedDescription)
        }
            
    }
    
    //write Video
    private func writeVideo(sampleBuffer: CMSampleBuffer) {
        // turn off the LayoutGuideFrame
        DispatchQueue.main.async {[weak self] in
            self?.showLayoutGuidingView = false
            self?.showRecordingIndicator = true
        }
        
        print("old write Video called")
        
        guard !stopped else {return}
        
        switch self.assetWriter?.status {
                case .writing:
                    print("Status: writing")
                case .failed:
            if let error = self.assetWriter?.error {
                        print("Status: failed with error: \(error.localizedDescription)")
                    }
                case .cancelled:
                    print("Status: cancelled")
                case .unknown:
                    print("Status: unknown")
                default:
                    print("Status: completed")
                }
                
        
        //set the stop once
        if !stopRecordingSet {
            stopRecordingSet = true
            DispatchQueue.main.asyncAfter(deadline: .now() + updrsItems[currentItem].recordingDuration)  {
                print("stop recording after")
                self.stopRecording()
                print("stop recording scheduled")
            }
        }
        
        //start Writing Session
        if assetWriter?.status == .writing && self.sessionAtSourceTime == nil {
            let sessionAtSourceTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
            self.assetWriter?.startSession(atSourceTime: sessionAtSourceTime)
          
        }
        print("writer url",assetWriter?.outputURL)
        //append current Samplebuffer
        guard let assetWriterInput = self.assetWriterInput else {return}
        if assetWriter?.status == .writing, assetWriterInput.isReadyForMoreMediaData {
            assetWriterInput.append(sampleBuffer)
            self.frame += 1
//            print("assetwriter is writing frame \(frame)")
//            print("Writer appended Input")
        }
    }
    
//    private func stopRecording(){
//        
//        guard let movieFileOutput = self.movieFileOutput else {return}
//        print("recoring stop")
//        self.didFinishWriting.send()
//        movieFileOutput.stopRecording()
//        stopRecordingSet = false
//        frame = 0
//        stopped = false
//        //save Item to CoreData
//        addItemToCoreData()
//        showRecordingIndicator = false
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            self.nextTrial()
//        }
//    }
    
    private func stopRecording(){
        
        self.didFinishWriting.send()
        self.assetWriterInput?.markAsFinished()
        Task{
            await assetWriter?.finishWriting()
            //self.sessionAtSourceTime = nil
            
            print("Recording finished")
        }
        stopRecordingSet = false
        frame = 0
        stopped = false
        //save Item to CoreData
        addItemToCoreData()
        showRecordingIndicator = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.nextTrial()
        }
    }
    
}
//MARK: - Recording Routing
extension CameraViewModel {
    
    private func nextTrial() {
        
        if currentItem+1 < updrsItems.count {
            currentItem += 1
            itemURL = nil
            
            if updrsItems[currentItem].recordingPosition == .standing {
                showLayoutGuidingView = true
            }
            
            //set the guideFrame according to whether it's a standing or sitting recording
            switch updrsItems[currentItem].recordingPosition {
            case .sitting:
                self.bodyLayoutGuideFrame = CGRect(x: 0, y: -50, width: 370, height: 600)
            case .standing:
                self.bodyLayoutGuideFrame = CGRect(x: 0, y: updrsItems[currentItem].itemName == UPDRSItemName.Walking.rawValue ? -350:   -50, width: 370, height: 282)
            
            }
            startedNextTrial.send()
            guideNewVideo()
        }else {
            print("done")
            speakHelp = false
            showLayoutGuidingView = false
            showFinishedRecordingRatingView = true
            currentItem = 0
            
        }
        
    }
    
}

extension CameraViewModel {
    func calculateDetectedBodyValidity() {
        hasDetectedValidBody =
        isAcceptableBounds == .detectedBodyAppropriateSizeAndPosition
        
    }
}

//MARK: - Reading Home Screen
extension CameraViewModel {
    func explainMainScreen(){

        if currentTip <= mainScreenExplanationFileNames.count-1 {
            if currentTip > -1 {
                playAudio(subdirectory: "mainScreen", fileName: mainScreenExplanationFileNames[currentTip])
        }else {
                currentTip = -1
            }
         
        }
        
    }
}

//MARK: - Recording Guidance

//MARK: - AVAudioPlayerDelegate
extension CameraViewModel: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool){
        //Check if the player played a main Screen Button explanation and if so increase the index by 1
        if mainScreenExplanationFileNames.contains(currentAudioFile){
            if currentTip < mainScreenExplanationFileNames.count - 1{
                self.currentTip += 1
            }else{
                currentTip = -1
            }
        }
    }
    
    //helper function to stop the audio
    func stopAudioPlayer(){
        guard let audioPlayer = self.audioPlayer else { return }
        if audioPlayer.isPlaying {
            audioPlayer.stop()
        }
    }
    
}

//MARK: - AVSpeechSynthesizerDelegate
extension CameraViewModel: AVSpeechSynthesizerDelegate {
    
    func startInstruction() {
        
        synthesizer.speak(createUtterance(from: Instructions.beginn.rawValue))
        
        DispatchQueue.main.asyncAfter(deadline: .now()+8){
            self.guidanceInstruction()
        }
    }
    
    private func pauseSpeech(){
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
        }
    }
    
    //if the View leaves the screen
    func stopSpeech(){
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    func guidanceInstruction(){
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { (timer) in
            self.speakGuidanceInstruction()
        }
        
    }
    
    func guideNewVideo(){
        var newTask:String {
            var string = updrsItems[currentItem].itemName == UPDRSItemName.Walking.rawValue ? "Sehr gut, wir machen nun weiter mit der Aufgabe \(updrsItems[currentItem].displayName). Bitte rücken Sie den Stuhl zur Seite und gehen Sie soweit zurück, bis Sie wieder im Kästchen stehen. Ich sage Ihnen, sobald Sie richtig stehen." : "Sehr gut, wir machen nun weiter mit der Aufgabe \(updrsItems[currentItem].displayName)."
            
            if updrsItems[currentItem].recordingPosition == .standing {
                string += "Ich schaue zunächst wieder, ob sie gut zur Kamera positioniert sind."
            }
            return string
        }
        synthesizer.speak(createUtterance(from: newTask))
        
        if updrsItems[currentItem].recordingPosition == .standing {
            DispatchQueue.main.asyncAfter(deadline: .now()+5){
                self.guidanceInstruction()
            }
        }else {
            if currentItem == 0 {
                synthesizer.speak(createUtterance(from: "Sehr gut, bitte setzen Sie sich nun vorsichtig hin."))
                timer?.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now()+10) { [weak self] in
                    guard let self = self else {return}
                    self.currentInstruction = "Wir können nun mit der Aufgabe beginnen. \(updrsItems[currentItem].showInstructionByDefult ? "Für diese Übung zeige Ich Ihnen eine Vorschau, während ich sie erkläre." : "") \(updrsItems[currentItem].instructionTest). Ich starte die Aufnahme in Drei...Zwei...Eins. Die Aufnahme läuft."
                    
                    synthesizer.speak(createUtterance(from: self.currentInstruction))
                    timer?.invalidate()
                }
            }else{
                self.currentInstruction = "\(updrsItems[currentItem].showInstructionByDefult ? "Für diese Übung zeige Ich Ihnen eine Vorschau, während ich sie erkläre." : "") \(updrsItems[currentItem].instructionTest). Ich starte die Aufnahme in Drei...Zwei...Eins. Die Aufnahme läuft."
                
                synthesizer.speak(createUtterance(from: self.currentInstruction))
                timer?.invalidate()
            }
        }
        
    }
                                     
    func speakGuidanceInstruction(){
        switch isAcceptableBounds {
        case .detectedBodyTooLarge:
            synthesizer.speak(createUtterance(from: Instructions.goAway.rawValue))
        case .unknown:
            print("unknown")
        case .detectedBodyTooSmall:
            synthesizer.speak(createUtterance(from: Instructions.comeNear.rawValue))
        case .detectedBodyOffCentre:
            print("of center")
        case .detectedBodyAppropriateSizeAndPosition:
            
            if currentItem == 0 {
                synthesizer.speak(createUtterance(from: "Sehr gut, bitte setzen Sie sich nun vorsichtig hin."))
                timer?.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now()+10) { [weak self] in
                    guard let self = self else {return}
                    self.currentInstruction = "Wir können nun mit der Aufgabe beginnen. \(updrsItems[currentItem].showInstructionByDefult ? "Für diese Übung zeige Ich Ihnen eine Vorschau, während ich sie erkläre." : "") \(updrsItems[currentItem].instructionTest). Ich starte die Aufnahme in Drei...Zwei...Eins. Die Aufnahme läuft."
                    
                    synthesizer.speak(createUtterance(from: self.currentInstruction))
                    timer?.invalidate()
                }
            }else{
                self.currentInstruction = "Sehr gut! Wir können nun mit der Aufgabe beginnen. \(updrsItems[currentItem].showInstructionByDefult ? "Für diese Übung zeige Ich Ihnen eine Vorschau, während ich sie erkläre." : "") \(updrsItems[currentItem].instructionTest). Ich starte die Aufnahme in Drei...Zwei...Eins. Die Aufnahme läuft."
                
                synthesizer.speak(createUtterance(from: self.currentInstruction))
                timer?.invalidate()
            }
         
        }
        
    }
    
    func SpeakRatingExplanation(){
        let explanation = "Sie sehen hier die Aufnahmen, die Sie erstellt haben. bitte schätzen Sie auf einer Skala von Null, gar keine Probleme, bis Vier, sehr große Probleme, für jede Aufnahme ein, wie es Ihnen bei der jeweiligen Übung ergangen ist. Sie finden sämtliche Aufnahmen später im Videotagebuch. Wenn Sie alle Videos bewertet haben, tippen Sie bitte auf fertig."
        synthesizer.speak(createUtterance(from: explanation))
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        if utterance.speechString.contains(updrsItems[currentItem].instructionTest) {
            if updrsItems[currentItem].showInstructionByDefult {
                showInstructionOverlay = true
            }
        }
        
        if utterance.speechString.contains("Wir können nun mit der Aufgabe beginnen") {
            print("utterance contains: \(utterance.speechString)" )
            showLayoutGuidingView = false
        }
    }
    //turn off InstructionOverlay
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        //print(characterRange.location)
        //print(characterRange.length)
        let substringToCheck = "Ich starte die Aufnahme in Drei"
            if let range = utterance.speechString.range(of: substringToCheck) {
                let nsRange = NSRange(range, in: utterance.speechString)
                //print(nsRange.location)
                //print(nsRange.length)
                if nsRange.location == characterRange.location {
                    showInstructionOverlay = false
                }
            }
    }
    
    //start recording if it was an Instruction finished
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        //check if speaking correct is done
        if utterance.speechString == self.currentInstruction{
            DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                //tells FeatureDetector (RENAME) to initiate recording
                self.shouldRecord.send()
            }
        }
        
//        if utterance.speechString == self.mainScreenExplanations[currentTip] && currentTip < mainScreenExplanations.count - 1{
//            currentTip += 1
//        }
    }
    
    private func createUtterance(from string: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
        utterance.rate = 0.43 // slower speech rate for a relaxed and friendly tone
        utterance.pitchMultiplier = 1.53 // slightly higher pitch for a more upbeat and friendly tone
        utterance.volume = 1.0 // maximum volume for a clear and friendly voice
        return utterance
    }
}

//MARK: - CoreData

extension CameraViewModel {
    
    func getRelativeURL() -> URL? {
        guard let session = self.session,
              let fullUrl = self.itemURL?.absoluteString
        else {
            
            print("error getting session and itemURL")
            return nil
        }
        
        if let range = fullUrl.range(of: VideoFileManager.instance.documentsDirectory.absoluteString){
            let relativePath = String(fullUrl[range.upperBound...])
            return URL(string: relativePath)
        }else{
            return nil
        }
    }
    
    func addItemToCoreData() {
        print("Session_\(self.sessionNumber!)/\(itemURL!.lastPathComponent)")
        guard let session = self.session,
              let itemUrl = self.itemURL,
              let urlToSave = getRelativeURL()
        else {
            print("error saving to CoreData")
            return
        }
        print("urlToSave", itemUrl)
        let curIt = updrsItems[currentItem]
        let item = UPDRSRecordedItem(context: viewContext)
        item.orderNumber = Int16(curIt.orderNumber)
        item.date = Date()
        item.name = curIt.itemName
        item.rating = 0
        item.session = session
        item.videoURL = urlToSave
        item.site = curIt.site
        save()
    }
    
    func addSessionToCoreData() {
        let session = Session(context: viewContext)
        session.id = Int16(self.sessionNumber ?? 0)
        session.date = Date()
        self.session = session
        save()
    }
    
    func save() {
        do {
            try viewContext.save()
        }catch {
            print("Error saving")
        }
    }
    
}
