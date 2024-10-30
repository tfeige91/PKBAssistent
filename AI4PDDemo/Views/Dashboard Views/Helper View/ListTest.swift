//
//  ListTest.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 16.06.23.
//

import SwiftUI

struct ListTest: View {
    let colors: [Color] = [.green, .blue, .purple]
    
    var body: some View {
        VStack {
            
            ForEach((1...10), id: \.self) { idx in
                DisclosureGroup(content: {
                    RoundedRectangle(cornerRadius: 8)
                        .frame(width: 50, height: 35)
                        .foregroundColor(self.colors[idx % 3])
                },
                                label: {
                    Text("Row #\(idx)")
                        .font(.largeTitle)
                })
                
            }
        }
        
        
    }
}

struct ListTest_Previews: PreviewProvider {
    static var previews: some View {
        ListTest()
    }
}
