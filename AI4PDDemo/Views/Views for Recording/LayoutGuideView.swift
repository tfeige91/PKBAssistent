//
//  LayoutGuideView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 09.05.23.
//

import SwiftUI

struct LayoutGuideView: View {
    
    @EnvironmentObject var model: CameraViewModel
    
    var body: some View {
        
            RoundedRectangle(cornerRadius: 20)
                .stroke(model.hasDetectedValidBody ? Color.green : Color.red,lineWidth: 6.0)
                .frame(width: model.bodyLayoutGuideFrame.width, height: model.bodyLayoutGuideFrame.height)
                .offset(x:model.bodyLayoutGuideFrame.origin.x,y:model.bodyLayoutGuideFrame.origin.y)
        
    }
}

struct LayoutGuideView_Previews: PreviewProvider {
    static var previews: some View {
        LayoutGuideView()
    }
}
