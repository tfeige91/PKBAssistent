//
//  BodyBoundingBoxView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 09.05.23.
//

import SwiftUI

struct BodyBoundingBoxView: View {
    @EnvironmentObject var model: CameraViewModel

    var body: some View {
        switch model.bodyGeometryState {
        case .bodyNotFound:
        Rectangle().fill(Color.clear)
        case .bodyFound(let bodyGeometryModel):
            GeometryReader{geo in
                Rectangle()
//                  .stroke(.yellow, lineWidth: 2.0)
//                  .frame(width: bodyGeometryModel.boundingBox.width, height: bodyGeometryModel.boundingBox.height)
//                  .position(x: bodyGeometryModel.boundingBox.origin.x, y: 1-bodyGeometryModel.boundingBox.origin.y)
                  .path(in: CGRect(
                    x: bodyGeometryModel.boundingBox.origin.x * geo.size.width,
                    y: (1-bodyGeometryModel.boundingBox.origin.y) * geo.size.height,
                    width: bodyGeometryModel.boundingBox.width * geo.size.width,
                    height: bodyGeometryModel.boundingBox.height * geo.size.height
                  ))
                  .stroke(Color.yellow, lineWidth: 2.0)
            }

      case .errored:
        Rectangle().fill(Color.clear)
      }
    }
}

struct BodyBoundingBoxView_Previews: PreviewProvider {
    static var previews: some View {
        BodyBoundingBoxView()
    }
}
