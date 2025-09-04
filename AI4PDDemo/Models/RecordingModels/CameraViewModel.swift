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
    case RestingTremor
    case MovementTremor
    case Fingertap
    case ToeTapping
    case PronationSupination
    case Walking
    
}

enum Side: String, CaseIterable {
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

enum AudioSequenceType {
    case readMainScreen
    case recordingUPDRS
}

enum UPDRSInstructionStep {
    case startPositioning
    case sit
    case wait
    case readInstruction
    case countToRecord
    case startRecording
    case nextTask
    case introduceNextTask
    case guidance
    case guidanceSuccessfull
    case beginTask
}

enum InstructionsType {
    case full
    case short
}


struct BodyGeometryModel {
    let boundingBox: CGRect
}

//to make sure only one recording at the same time is possible
actor RecordingGate {
    static let shared = RecordingGate()
    private var isBusy = false

    func acquire() -> Bool {
        guard !isBusy else { return false }
        isBusy = true
        return true
    }

    func release() { isBusy = false }
}

@MainActor
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
    
    //adjust for the studyGroup if non is set return the voice over for the study group
    var mainScreenExplanationFileNames: [String] {
        var explanations = [String]()
        let studyGroupRaw = UserDefaults.standard.string(forKey: "userGroup") ?? ""
        guard let studyGroup = UserGroup(rawValue: studyGroupRaw) else { return [
            "Helpbutton",
            "Speechbutton",
            //"Chatbutton",
            "RecordingButton",
            "ShowRecordsButton",
            "DoctorView",
            "QuestionnaireButton"
        ] }
        if studyGroup == .intervention {
            explanations.append(contentsOf: [
                "Helpbutton",
                "Speechbutton",
                //"Chatbutton",
                "RecordingButton",
                "ShowRecordsButton",
                "DoctorView",
                "QuestionnaireButton"
            ])
        }else if studyGroup == .control {
            explanations.append(contentsOf: [
                "Helpbutton",
                "Speechbutton",
                "QuestionnaireButton"
            ])
        }
        return explanations
    }
    
    // MARK: - Publishers of derived state
    @Published private(set) var hasDetectedValidBody: Bool
    
    @Published private(set) var isAcceptableBounds: BodyBoundsState = .detectedBodyTooLarge {
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
                  itemName: UPDRSItemName.RestingTremor.rawValue,
                  displayName: "Ruhetremor",
                  recordingPosition: .sitting,
                  instructionTest: "Versuchen Sie nun einfach entspannt zu sitzen und von einhundert in siebener Schritten herunterzuzählen.",
                  side: .none,
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
                  side: .right,
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
                  side: .left,
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
                  side: .right,
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
                  side: .left,
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
                  side: .right,
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
                  side: .left,
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
                  side: .right,
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
                  side: .left,
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
                  side: .none,
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
    var currentAudioSequence: AudioSequenceType = .readMainScreen
    var currentUPDRSInstructionState: UPDRSInstructionStep = .sit
    var currentInstructionType :InstructionsType = .full
    
    
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
    //hacky approach
    var videoPreviewLayerOrientation = AVCaptureVideoOrientation(rawValue: 1)
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?
    
    //Saving Video Files
    var assetWriter: AVAssetWriter? = nil
    var assetWriterInput: AVAssetWriterInput? = nil
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
    var session: Session?
    
    override init() {
        
        self.hasDetectedValidBody = false
        self.isAcceptableBounds = .detectedBodyTooLarge
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
//        let origin = boundingBox.origin
//        let originalSize = bodyLayoutGuideFrame.size
        switch updrsItems[currentItem].recordingPosition {
        case .sitting: self.bodyLayoutGuideFrame = CGRect(x: 0, y: -50, width: boundingBox.width*1.05, height: boundingBox.height*1.01)
        case .standing: self.bodyLayoutGuideFrame = CGRect(x: 0, y: updrsItems[currentItem].itemName == UPDRSItemName.Walking.rawValue ? -350:   -50, width: boundingBox.width*1.05, height: boundingBox.height * 1.01)
        }
        
        
        
//        print("DEBUG: BOUNDING BOX: \(boundingBox.minY)")
//        print("DEBUG: LayoutGuideFrame: \(self.bodyLayoutGuideFrame.minY)")
        
        let calculatedValue = boundingBox.minY * -1 - bodyLayoutGuideFrame.minY
//        print("DEBUG: Calculated value \(calculatedValue)")

        
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

    private func prepareWriter(sampleBuffer: CMSampleBuffer) {
        print("prepare Writer started \n")
        print("Session", self.session ?? "no session")
        print("currentItemNumber",self.currentItem)
        print("current Item: ","\(self.updrsItems[self.currentItem].itemName)_\(self.updrsItems[self.currentItem].side.rawValue)")
        Task{
            //check if there already is a recording
            guard await RecordingGate.shared.acquire() else {
                        print("Recording already in progress – skipping prepareWriter")
                        return
                    }
            self.sessionAtSourceTime = nil
            //get the correct URL
    //        print(session?.id)
    //        print("DEBUG SESSION URL: \(self.sessionURL)")
    //        print("DEBUG SESSION URL: \(self.session?.url)")
            if self.session == nil {
                if self.sessionURL == nil {
                    print("generate session URK")
                    guard let (sessionNumber, sessionFolder) = fileManager.getNewSessionFolder() else  {print("could not create Session Folder"); return}
                    self.sessionNumber = sessionNumber
                    self.sessionURL = sessionFolder
    //                print("DEBUG SESSION URL: \(sessionURL)")
                    //Add the current Session to Core data
                    addSessionToCoreData()
                }
            }else{
                if let id = session?.sessionNumber{
                    self.sessionURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("recordings").appendingPathComponent("Session_\(id)")
                }
               
                
    //            print("DEBUG SESSION URL: \(self.sessionURL)")
            }
            
            self.itemURL = URL(filePath: self.sessionURL!.path())
                .appendingPathComponent("\(self.updrsItems[self.currentItem].itemName)_\(self.updrsItems[self.currentItem].side.rawValue)")
                //.appendingPathComponent(self.updrsItems[self.currentItem].site.rawValue)
                .appendingPathExtension("mov")
            
            //if already there delete it
            if FileManager.default.fileExists(atPath: self.itemURL!.path) {
                try? FileManager.default.removeItem(at: self.itemURL!  )
                print("item removed")
            }
        
            
    //        print("DEBUG SESSION URL: ItemURL\(self.itemURL)")
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
            
    }
    
    //write Video
    private func writeVideo(sampleBuffer: CMSampleBuffer) {
        // turn off the LayoutGuideFrame
        DispatchQueue.main.async {[weak self] in
            self?.showLayoutGuidingView = false
            self?.showRecordingIndicator = true
        }
        
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
            let ts = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
            self.assetWriter?.startSession(atSourceTime: ts)
            self.sessionAtSourceTime = ts
          
        }
        //append current Samplebuffer
        guard let assetWriterInput = self.assetWriterInput else {return}
        if assetWriter?.status == .writing, assetWriterInput.isReadyForMoreMediaData {
            assetWriterInput.append(sampleBuffer)
            self.frame += 1
        }
    }
    
    private func stopRecording(){
        Task{
            self.didFinishWriting.send()
            self.assetWriterInput?.markAsFinished()
            await assetWriter?.finishWriting()
            self.sessionAtSourceTime = nil
            //reset the RecordingGate
            await RecordingGate.shared.release()
            print("Recording finished")
            stopRecordingSet = false
            frame = 0
            stopped = false
            //save Item to CoreData
            addItemToCoreData()
            DispatchQueue.main.async {
                self.showRecordingIndicator = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.nextTrial()
            }
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
            currentUPDRSInstructionState = .nextTask
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
        currentAudioSequence = .readMainScreen
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
        //check what the player is playing
        switch currentAudioSequence {
        case .readMainScreen:
            //Check if the player played a main Screen Button explanation and if so increase the index by 1
            if mainScreenExplanationFileNames.contains(currentAudioFile){
                if currentTip < mainScreenExplanationFileNames.count - 1{
                    self.currentTip += 1
                }else{
                    currentTip = -1
                }
            }
        case .recordingUPDRS:
            proceedToNextStep()
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
        currentAudioSequence = .recordingUPDRS
        currentUPDRSInstructionState = .startPositioning
        playAudio(subdirectory: "position_instructions", fileName: "start_positioning")

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
        if timer == nil || !timer!.isValid {
            print("DEBUG: timer set)")
            timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { (timer) in
                self.speakGuidanceInstruction()
            }
        }
    }
    
    func guideNewVideo(){
        instructAndRecord(item: updrsItems[currentItem])
    }
                                     
    func speakGuidanceInstruction(){
        print("DEBUG: speakGuidanceInstruction called")
        switch isAcceptableBounds {
        case .detectedBodyTooLarge:
            print("DEBUG:Too large")
            playAudio(subdirectory: "position_instructions", fileName: "goAway")
            //synthesizer.speak(createUtterance(from: Instructions.goAway.rawValue))
        case .unknown:
            print("unknown")
        case .detectedBodyTooSmall:
            playAudio(subdirectory: "position_instructions", fileName: "comeNear")
        case .detectedBodyOffCentre:
            print("of center")
        case .detectedBodyAppropriateSizeAndPosition:
            currentUPDRSInstructionState = .guidanceSuccessfull
            stopAudioPlayer()
            proceedToNextStep()
        }
        
    }
    
    func proceedToNextStep() {
        let currentItem = updrsItems[currentItem]
        guard let itemName = UPDRSItemName(rawValue: currentItem.itemName) else {
            return
        }
        
        switch (itemName,currentUPDRSInstructionState) {
        //if it is in the initial guiding state start the positioning
        case (_,.startPositioning):
            print("DEBUG: startPositioning")
            self.guidanceInstruction()
        case(_,.guidanceSuccessfull):
            //invalidate Timer to stop guidance Instructions
            timer?.invalidate()
            DispatchQueue.main.async {[weak self] in
                //if position correct: turn off rectangle
                self?.showLayoutGuidingView = false
            }
            currentUPDRSInstructionState = .beginTask
            //not double "sehr gut"
            if itemName != .RestingTremor {
                playAudio(subdirectory: "", fileName: "position_correct")
            }else{
                proceedToNextStep()
            }
            
        case(_,.beginTask):
            instructAndRecord(item: currentItem)
        case (.RestingTremor, .sit):
            playAudio(subdirectory: "position_instructions", fileName: "pleaseSit")
            currentUPDRSInstructionState = .wait
        case (.RestingTremor, .wait):
            Task{
                try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
                //wait 10 seconds
                currentUPDRSInstructionState = .readInstruction
                proceedToNextStep()
            }
        case (.Walking,.introduceNextTask):
            playAudio(subdirectory: "", fileName: "Walking_guiding")
            currentUPDRSInstructionState = .guidance
        case (.Walking, .guidance):
            guidanceInstruction()
        case (_, .readInstruction):
            DispatchQueue.main.async {[weak self] in
                self?.showInstructionOverlay = false
            }
            
            let side = currentItem.side
            var audiofileName: String {
                var string = itemName.rawValue
                if side == .right {
                    string+="_right"
                }else if side == .left {
                    string+="_left"
                }
                if currentInstructionType == .short {
                    string+="_sh"
                }
                return string
            }
            playAudio(subdirectory: "", fileName: audiofileName)
            if currentItem.showInstructionByDefult {
                showInstructionOverlay = true
            }
            currentUPDRSInstructionState = .countToRecord
        case (_,.countToRecord):
            showInstructionOverlay = false
            playAudio(subdirectory: "position_instructions", fileName: "startRecording")
            currentUPDRSInstructionState = .startRecording
        case (_,.startRecording):
            //tells FeatureDetector (RENAME) to initiate recording
            self.shouldRecord.send()
        default:
            break
        }
    
        
    }
    
    func instructAndRecord(item: UPDRSItem) {
        
        
        //set the currentAudioSequence to recordingUPDRS
        currentAudioSequence = .recordingUPDRS
        //turn off guidance overlay
        showInstructionOverlay = false
        //convert String Name to enum Value to make switch possible
        let itemName = UPDRSItemName(rawValue: item.itemName)
        if itemName == .RestingTremor {
            currentUPDRSInstructionState = .sit
        }else if itemName == .Walking{
            if currentUPDRSInstructionState == .nextTask {
                currentUPDRSInstructionState = .introduceNextTask
            }else{
                currentUPDRSInstructionState = .readInstruction
            }
        }else {
            currentUPDRSInstructionState = .readInstruction
        }
        proceedToNextStep()
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
        item.side = curIt.side
        save()
    }
    
    func addSessionToCoreData() {
        let session = Session(context: viewContext)
        session.id = Int16(self.sessionNumber ?? 0)
        session.date = Date()
        session.url = self.sessionURL?.absoluteString
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
    
    //x 
    
}
