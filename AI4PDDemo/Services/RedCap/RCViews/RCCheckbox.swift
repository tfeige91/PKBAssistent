//
//  RCCheckbox.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 01.11.23.
//

import SwiftUI

struct CheckToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Label {
                configuration.label
            } icon: {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundStyle(configuration.isOn ? Color.accentColor : .secondary)
                    .accessibility(label: Text(configuration.isOn ? "Checked" : "Unchecked"))
                    .imageScale(.large)
            }
        }
        .buttonStyle(.plain)
    }
}
@ViewBuilder
func RCMultipleChoiceField(number: Int) -> some View {
    
    HStack{
        ForEach(0...number, id: \.self) {number in
        Text("\(number)")
        }
    }
    
}

struct RCCheckbox: View {
    @State private var selectedOptions: [Bool] = Array(repeating: false, count: 5)
    let scaleLabels = ["","Strongly Disagree", "Disagree", "Neutral", "Agree", "Strongly Agree"]
    
    var body: some View {
        VStack {
            HStack {
                ForEach(scaleLabels, id: \.self) { label in
                    Text(label)
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
            }
            
            HStack {
                ForEach(0..<5) { index in
                    Checkbox(isChecked: $selectedOptions[index])
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .onTapGesture {
                            selectedOptions = Array(repeating: false, count: 5)
                            selectedOptions[index].toggle()
                        }
                }
            }
        }
    }
}

struct Checkbox: View {
    @Binding var isChecked: Bool
    
    var body: some View {
        Image(systemName: isChecked ? "checkmark.square" : "square")
            .resizable()
            .frame(width: 24, height: 24)
    }
}


//struct RCCheckbox: View {
//    @State private var isOn = false
//
//    var body: some View {
////        Toggle("Switch Me", isOn: $isOn)
////            .toggleStyle(CheckToggleStyle())
//        RCMultipleChoiceField(number: 5)
//    }
//}

#Preview {
    RCCheckbox()
}
