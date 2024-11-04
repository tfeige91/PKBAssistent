//
//  RecordingView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 12.06.23.
//

import SwiftUI

struct RecordingView: View {
    
    @EnvironmentObject var model: CameraViewModel
    @Environment(\.dismiss) private var dismiss
    
    
    var body: some View {
        VStack{
            if !model.showFinishedRecordingRatingView{
                cameraView
                    .overlay {
                        if model.showInstructionOverlay{
                            GuidingOverlayView()
                        }
                    }
            }else{
                Color.blue.opacity(0.2)
                    .edgesIgnoringSafeArea(.all)
                    .overlay{
                        EndOfRecordingRatingView(sessionID: model.sessionNumber!)
                    }
            }
        }
        
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onChange(of: model.dismissRecordingView) { shouldDismiss in
            if shouldDismiss {
                self.dismiss()
            }
        }
        
        //.edgesIgnoringSafeArea(.all)
        
    }
}

extension RecordingView {
    private var cameraView: some View {
        CameraView()
            .overlay {
                BodyBoundingBoxView()
            }
            .overlay(alignment: .top) {
                
                //TopView with some information
                Text(model.updrsItems[model.currentItem].displayName)
                    .font(.title.bold())
                    .frame(height: 45)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)
                    .background(model.showRecordingIndicator ? .ultraThinMaterial : .thinMaterial)
                    .background {
                        if model.showRecordingIndicator {
                            Color.red.opacity(0.6)
                        }
                    }
            }
            .overlay {
                if model.showLayoutGuidingView{
                    VStack {
                        Spacer()
                        LayoutGuideView()
                        
                    }
                    .ignoresSafeArea(.all)
                    
                }
                
            }
            .background{
                Color.black
                    .ignoresSafeArea(.all)
            }
    }
}

struct RecordingView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingView()
            .environmentObject(CameraViewModel())
    }
}
