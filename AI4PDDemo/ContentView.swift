//
//  ContentView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 21.10.24.
//

import SwiftUI

struct PreviewUserDefaults {
    static let previewUserDefaults: UserDefaults = {
        let d = UserDefaults(suiteName: "preview_user_defaults")!
        d.set("control", forKey: "userGroup")
        d.set("157", forKey: "RecordID")
        return d
    }()
}

struct ContentView: View {
    @AppStorage("RecordID") var recordID: String?
    @AppStorage("userGroup") var userGroup: String?
    @StateObject var cameraModel: CameraViewModel = CameraViewModel()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    var body: some View {
        if recordID == nil {
            StudyGroupView()
        } else if userGroup != nil {
            HomeScreen()
                .environmentObject(cameraModel)
                .environmentObject(speechRecognizer)
        } else {
            //StudyGroupView()
            HomeScreen()
                .environmentObject(cameraModel)
                .environmentObject(speechRecognizer)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .defaultAppStorage(PreviewUserDefaults.previewUserDefaults)
    }
}
