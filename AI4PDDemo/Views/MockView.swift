//
//  MockView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 25.09.23.
//

import SwiftUI

struct MockView: View {
    
    var body: some View {
        Text("hello")
            .task {
                do{
                    try await RedCapAPIService.instance.fetchInstruments()
                }catch {
                    print(error)
                }
                
            }
    }
}

struct MockView_Previews: PreviewProvider {
    static var previews: some View {
        MockView()
    }
}
