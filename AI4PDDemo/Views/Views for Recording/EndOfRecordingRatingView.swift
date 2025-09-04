//
//  EndOfRecordingRatingView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 16.08.23.
//

import SwiftUI

struct EndOfRecordingRatingView: View {
    
    @EnvironmentObject var model: CameraViewModel
    @FetchRequest var session: FetchedResults<Session>
    
    init(sessionID:Int){
        _session = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Session.date, ascending: true)],
                                     predicate: NSPredicate(format: "id == %@", "\(sessionID)"),
                                     animation: .default)
    }
    
    var body: some View {
        
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                GeometryReader {geo in
                    VStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(.thickMaterial)
                            
                            
                            VStack(spacing: 30) {
                                Text("Ihre Einschätzung")
                                    .font(.largeTitle.bold())
                                
                                
                                ScrollView(.horizontal, showsIndicators: true){
                                    HStack(spacing:20) {
                                        ForEach(session.first!.recordedItemsArray) {item in
                                            SingleItemView(recoredItem: item)
                                                .padding()
                                        }
                                    }
                                }
                                
                                Button {
                                    print("start Pressed")
                                    model.showFinishedRecordingRatingView = false
                                    model.dismissRecordingView = true
                                } label: {
                                    WideButton(title: "Fertig", color: .blue)
                                        .frame(width: geo.size.width * 0.4)
                                }
                                Spacer()
                            }
                            .padding(.top, 100)
                        }
                        .frame(width: (geo.size.width * 0.9),height: geo.size.height * 0.7)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                }
            }
            .onAppear {
                if session.first!.sessionNumber <= 2 {
                    model.playAudio(subdirectory: "rating_view_instructions", fileName: "RatingViewInstruction")
                }
            }.onDisappear{
                //model.stopAudioPlayer()
            }
    }
}

//struct EndOfRecordingRatingView_Previews: PreviewProvider {
//    static var previews: some View {
//        EndOfRecordingRatingView(sessionID: 1)
//    }
//}
