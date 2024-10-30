//
//  Testview.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 28.07.23.
//

import SwiftUI

struct Testview: View {
    
        var message1: AttributedString {
            var result = AttributedString(OnboardingData.functionalityText)
            result.font = .largeTitle
            result.foregroundColor = .black
            //result.backgroundColor = .red
            result.underlineStyle = .double
            result.underlineColor = .blue
            result.strokeColor = .yellow
            let range = result.range(of: "Medikation")!
            result[range].foregroundColor = .green
            return result
        }

        var message2: AttributedString {
            var result = AttributedString("World!")
            result.font = .largeTitle
            result.underlineStyle = .patternDashDotDot
            
            
            //result.underlineStyle = .single
            result.foregroundColor = .black
            //result.backgroundColor = .blue
            return result
        }

        var body: some View {
            Text(message1 + message2)
        }
    
}

struct Testview_Previews: PreviewProvider {
    static var previews: some View {
        Testview()
    }
}
