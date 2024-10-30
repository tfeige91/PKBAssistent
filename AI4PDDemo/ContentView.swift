//
//  ContentView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 21.10.24.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var cameraModel: CameraViewModel = CameraViewModel()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    var body: some View {
        HomeScreen()
            .environmentObject(cameraModel)
            .environmentObject(speechRecognizer)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
