//
//  GuidingOverlayView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 25.07.23.
//

import SwiftUI

struct GuidingOverlayView: View {
    
    @EnvironmentObject var model: CameraViewModel
    
    var body: some View {
        
        GeometryReader {geo in
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.regularMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(.black.opacity(0.2))
                        }
                        
                    
                    VStack(spacing: 30) {
                        Text(model.updrsItems[model.currentItem].displayName)
                            .font(.largeTitle.bold())
                            .padding(50)
                        GifImageView(model.updrsItems[model.currentItem].itemName)
                            .frame(width: 470, height: 420)
                        
//                        Button {
//                            print("start Pressed")
//                        } label: {
//                            WideButton(title: "Start", color: .blue)
//                                .frame(width: geo.size.width * 0.4)
//                        }
                        Spacer()
                    }
                    .padding(.top, 100)
                }
                .frame(width: (geo.size.width * 0.8),height: geo.size.height * 0.8)
            }
            .frame(maxHeight: .infinity)
            .frame(maxWidth: .infinity)
            .offset(y: 50)
           
        }
        
        
       
    }
}

//struct Test_Previews: PreviewProvider {
//    static var previews: some View {
//        Test()
//    }
//}

//struct GuidingOverlayView_Previews: PreviewProvider {
//    static var previews: some View {
//        GuidingOverlayView()
//    }
//}
