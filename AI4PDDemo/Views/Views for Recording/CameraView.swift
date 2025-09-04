//
//  CameraView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 12.06.23.
//

import SwiftUI

struct CameraView: View {
    
    @EnvironmentObject var model: CameraViewModel
    
    
    
    var body: some View {
        CameraViewRepresentable(model: model)
            .onAppear {
                if model.speakHelp {
                    DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                        model.startInstruction()
                    }
                }
            }
            .onDisappear{
                //model.stopSpeech()
                model.timer?.invalidate()
                model.timer = nil
            }
            
        
        //        .edgesIgnoringSafeArea(.all)
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
