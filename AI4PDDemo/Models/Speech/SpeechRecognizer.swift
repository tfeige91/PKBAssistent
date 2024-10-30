//
//  SpeechRecognizer.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 24.07.23.
//

import Foundation
import Speech
import Combine

enum SpokenNavigation {
    case recording
    case diary
    case doctor
    case chat
    case main
    case questionnaire
    case none
}

class SpeechRecognizer: ObservableObject {
    
    // Property for spoken Routing
    @Published var spokenNavigation: SpokenNavigation = .main
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    let audioSession = AVAudioSession.sharedInstance()
    
    init(){}
    
    func askPermission(){
        audioSession.requestRecordPermission {granted in
            DispatchQueue.main.async {
                if granted {
                    print("Microphone usage authorized")
                } else {
                    print("Microphone usage unauthorized")
                }
            }
        }
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    print("Speech recognition authorized")
                } else {
                    print("Speech recognition unauthorized")
                }
            }
        }
    }
    
    func startRecording() throws{
        guard let speechRecognizer = speechRecognizer else {
            print("Speech recognizer not available")
            return
        }
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        
        try audioSession.setCategory(.record, mode: .default, options: [])
        try audioSession.setActive(true, options: [])
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create a recognition request")
            return
        }
        
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                let recognizedText = result.bestTranscription.formattedString
                print("Recognized text: \(recognizedText)")
                isFinal = result.isFinal
                
                // Process the recognized text here and trigger specific actions
                self.processVoiceCommand(recognizedText)
            }
            
            if error != nil || isFinal {
                self.stopRecording()
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        print("Recording started")
    }
    
    func stopRecording() {
        do {
            try audioSession.setCategory(.playAndRecord)
        } catch let error {
            print(error.localizedDescription)
        }
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        self.spokenNavigation = .none
        print("Recording stopped")
        //print("current value of voiceCommand \(voiceCommand)")
    }
    
    private func processVoiceCommand(_ command: String) {
        // Implement your logic to process recognized voice commands here.
        // For example, you can check the `command` string and perform different actions based on recognized words or phrases.
        if command.lowercased().contains("übung") {
            spokenNavigation = .recording
        } else if command.lowercased().contains("chat") {
            spokenNavigation = .chat
        } else if command.lowercased().contains("buch") {
            spokenNavigation = .diary
        } else if command.lowercased().contains("vorstellung") {
            spokenNavigation = .doctor
        }
        else if command.lowercased().contains("Fragebogen") {
            spokenNavigation = .questionnaire
        }
//       else {
//            spokenNavigation = .none
//            print("Could not find the target View Controller")
//            // Handle unrecognized voice commands or show feedback to the user.
//        }
        
        print(String(describing: self.spokenNavigation))
    }
    
}



