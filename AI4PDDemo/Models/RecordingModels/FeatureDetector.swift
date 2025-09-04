//
//  FeatureDetector.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 20.04.23.
//

import Foundation
import AVFoundation
import Vision
import Combine
import UIKit

protocol FeatureDetectorDelegate: NSObjectProtocol {
  func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect
}

class FeatureDetector: NSObject {
    weak var viewDelegate: FeatureDetectorDelegate?
    weak var model: CameraViewModel? {
        didSet {
            model?.shouldRecord.sink { completion in
                switch completion {
                case .finished:
                    return
                case .failure(let error): break
//                    print("error: \(error)")
                }
            } receiveValue: { _ in
                self.shouldRecord = true
                self.isRecording = false
//                print("shouldrecord",self.shouldRecord)
            }
            .store(in: &subscriptions)
            
            model?.isRecording.sink { completion in
                switch completion {
                case .finished:
                    return
                case .failure(let error): break
//                    print("error: \(error)")
                }
            } receiveValue: { _ in
                self.isRecording = true
            }
            .store(in: &subscriptions)
            
            model?.didFinishWriting.sink { completion in
                switch completion {
                case .finished:
                    return
                case .failure(let error): break
//                    print("error: \(error)")
                }
            } receiveValue: { _ in
                self.modelFinishedWriting = true
                self.shouldRecord = false
            }
            .store(in: &subscriptions)
            
            model?.startedNextTrial.sink { completion in
                switch completion {
                case .finished:
                    return
                case .failure(let error): break
//                    print("error: \(error)")
                }
            } receiveValue: { _ in
                self.modelAssetWriterPrepared = false
            }
            .store(in: &subscriptions)
                
                                        
        }
    }
    var subscriptions = Set<AnyCancellable>()
    
    var sequenceHandler = VNSequenceRequestHandler()
    var currentFrameBuffer: CVImageBuffer?

    //make it less flickery
    var currentFrame = 0
    let detectionInterval = 10 //detect every 10 frames
    
    var orientation: CGImagePropertyOrientation = .up
    
    var performVisionRequests = true
    var shouldRecord = false
    var isRecording = false

    let imageProcessingQueue = DispatchQueue(
      label: "Image Processing Queue",
      qos: .userInitiated,
      attributes: [],
      autoreleaseFrequency: .workItem
    )
    
    //Writing File
    var modelAssetWriterPrepared = false
    
    //reaction Variables to writing status
    var modelFinishedWriting = false
    
}

extension FeatureDetector: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if output is AVCaptureVideoDataOutput {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }
            
            
            self.currentFrame += 1
            
            
            //since Writer Preparation might take some time, initiate it here already
            if !modelAssetWriterPrepared {
                modelAssetWriterPrepared = true
                Task { @MainActor in
                    model?.perform(action: .prepareWriter(sampleBuffer))
                }
            }
            
            if !shouldRecord {
                //perform vision Requests every 10 frames
                guard self.currentFrame % detectionInterval == 0 else {return}
                if performVisionRequests {
                    //save the current imageBuffer
                    self.currentFrameBuffer = imageBuffer
                    guard currentFrameBuffer != nil else {return}
                    
                    let detectHumanRectanglesRequest = VNDetectHumanRectanglesRequest(completionHandler: detectedHumanRectangle)
                    //Detect entire Body
                    detectHumanRectanglesRequest.upperBodyOnly = false
                    //ignore the left and right 10% of the image (in case there is a second person in the recording)
//                    let roi = CGRect(x: 0.1, y: 0.0, width: 0.8, height: 1.0)
//                    detectHumanRectanglesRequest.regionOfInterest = roi
                    detectHumanRectanglesRequest.revision = VNDetectHumanRectanglesRequestRevision2
                    
                    do {
                      try sequenceHandler.perform(
                        [detectHumanRectanglesRequest],
                        on: self.currentFrameBuffer!,
                        orientation: .upMirrored)
                      
                    } catch {
//                      print(error.localizedDescription)
                    }
                }
                
                
            }
            
            
            if shouldRecord && !isRecording {
                guard let model = model else {return}
    //            print("should record")
                Task {@MainActor in
                    model.perform(action: .writingVideo(sampleBuffer))
                }
                
            }
        }
        
        
        
        
    }
    
    
    
}
    
    
//completion Handlers
extension FeatureDetector {
    func detectedHumanRectangle(request: VNRequest, error: Error?) {
        guard let model = model, let viewDelegate = viewDelegate else {
            return
        }
        
        //DEBUG
//        print("DEBUG: detectedHumanRectangle")
        //check if there is a result
        guard let results = request.results as? [VNHumanObservation],
              let result = results.first else{
            //publish no human detected
//            print("no human detected")
            Task {@MainActor in
                model.perform(action: .noHumanDetected)
            }
            return
        }
//        print("human detected")
        //get the converted Boundingbox
        let convertedBoundingBox = viewDelegate.convertFromMetadataToPreviewRect(rect: result.boundingBox)
        //print(convertedBoundingBox)
        //Create a bodyObservationModel with the bounding Box
        
        //DEBUG: print boundingbox coordinates
//        print(convertedBoundingBox.origin.y-convertedBoundingBox.height)
        
        let bodyObservationModel = BodyGeometryModel(boundingBox: convertedBoundingBox)
        
        //send the new Model to the CameraViewModel and perform the detected function
//        print("DEBUG: Person Found, running next request")
        detectHumanBodyPose(in: self.currentFrameBuffer!, boundingBox: bodyObservationModel)
        
    }
}

extension FeatureDetector {
    func detectHumanBodyPose(in imageBuffer: CVImageBuffer, boundingBox: BodyGeometryModel) {
//        print("DEBUG: Perfomring HumanBodyPoseRequest")
        guard let model = self.model else {
            return
        }
        let detectHumanBodyPoseRequest = VNDetectHumanBodyPoseRequest { request, error in
            guard let observations = request.results as? [VNHumanBodyPoseObservation], !observations.isEmpty else {
//                print("No body pose detected.")
                return
            }
            guard let firstPerson = observations.first else {
                return
            }
            
            do {
                let recognizedPoints = try firstPerson.recognizedPoints(forGroupKey: .all)
                
                let leftAnkle: VNHumanBodyPoseObservation.JointName = .leftAnkle
                let rightAnkle: VNHumanBodyPoseObservation.JointName = .rightAnkle
                if let leftFoot = recognizedPoints[leftAnkle.rawValue], let rightFoot = recognizedPoints[rightAnkle.rawValue] {
                    // Ensure points have sufficient confidence
                    guard leftFoot.confidence > 0.1, rightFoot.confidence > 0.1 else {
//                        print("Low confidence for foot key points.")
                        return
                    }
//                    print("DEBUG: Left Foot at: \(leftFoot.location.y)")
                    // Check if feet are within image bounds
                    if leftFoot.location.y >= 0.04 && leftFoot.location.y <= 1 &&
                        rightFoot.location.y >= 0.04 && rightFoot.location.y <= 1 {
//                        print("Feet are within the image bounds.")
//                        print("DEBUG: Left Foot at: \(leftFoot.location.y)")
                        
                        //accept the position and return to recorder
                        model.perform(action: .humanObservationDetected(boundingBox))
                    } else {
//                        print("Feet are not within the image bounds.")
                        return
                    }
                    
                } else {
//                    print("Feet key points not detected.")
                    return
                }
                
            } catch {
//                print("Error extracting recognized points: \(error)")
            }
            
        }
        detectHumanBodyPoseRequest.revision = VNDetectHumanBodyPoseRequestRevision1
        
        
        
        do {
//            print("DEBUG: executed")
            try sequenceHandler.perform(
                [detectHumanBodyPoseRequest],
                on: self.currentFrameBuffer!,
                orientation: .upMirrored)
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
}
    


//        switch UIDevice.current.orientation {
//        case .portrait:
//            orientation = .right
//        case .portraitUpsideDown:
//            orientation = .left
//        case .landscapeLeft:
//            orientation = .up
//        case .landscapeRight:
//            orientation = .down
//        default:
//            orientation = .right
//        }
