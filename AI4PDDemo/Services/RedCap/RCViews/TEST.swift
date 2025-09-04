//
//  TEST.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 08.01.25.
//

import SwiftUI

struct Park: Hashable {
  let name: String
  let imageName: String
  let description: String
}

extension Park: Identifiable {
  var id: String { name }
}

struct TEST: View {
  @State private var presentedParks: [Park] = []
  @State private var choosenPark: Park?
    @State private var shouldNavigate: Bool = false

  var parks: [Park] {
    [
      Park(name: "Yosemite", imageName: "yosemite", description: "Yosemite National Park"),
      Park(name: "Sequoia", imageName: "sequoia", description: "Sequoia National Park"),
      Park(name: "Point Reyes", imageName: "point_reyes", description: "Point Reyes National Seashore")
    ]
  }

  var body: some View {
    NavigationStack(path: $presentedParks) {
        VStack {
            List(parks) { park in
                HStack{
                    Text(park.name)
                    Button {
                        choosenPark = park
                        shouldNavigate = true
                    } label: {
                        Text("DAS IST EIN BUTTON")
                            .background(.blue)
                            .frame(width: 300,height:200)
                    }

                }
                
            }
            .navigationDestination(for: Park.self) { park in
                ParkDetailsView(park: park)
            }
            if choosenPark != nil {
                NavigationLink(choosenPark?.name ?? "", value: choosenPark!)
            }
            
        }
    }
  }
}

struct ParkDetailsView: View {
  let park: Park

  var body: some View {
    VStack {
      Image(park.imageName)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 200, height: 200)
      Text(park.name)
        .font(.title)
        .foregroundColor(.primary)
      Text(park.description)
        .font(.body)
        .foregroundColor(.secondary)
    }
    .padding()
  }
}


#Preview {
    NavigationStack{
        TEST()
            
    }
    .navigationViewStyle(.columns)
    
}
