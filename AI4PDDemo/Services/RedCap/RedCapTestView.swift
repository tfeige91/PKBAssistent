//
//  RedCapTestView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 07.12.23.
//

import SwiftUI

struct RedCapTestView: View {
    let rc = RedCapAPIService.instance

    var body: some View {
        Button {
            Task{
                let allQuests = try await rc.fetchInstruments()
                let quest = try await rc.fetchInstrument(allQuests[0].instrumentLabel)
            }
            
        } label: {
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        }

        
    }
}

#Preview {
    RedCapTestView()
}
