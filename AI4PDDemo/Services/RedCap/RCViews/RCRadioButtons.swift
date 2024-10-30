//
//  RCRadioButtons.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 02.11.23.
//

import SwiftUI

//FOUND HERE https://stackoverflow.com/questions/58580027/how-to-create-radiobuttons-in-swiftui/61949896

import SwiftUI

struct ColorInvert: ViewModifier {

    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        Group {
            if colorScheme == .dark {
                content.colorInvert()
            } else {
                content
            }
        }
    }
}

struct RadioButton: View {

    @Environment(\.colorScheme) var colorScheme

    let id: String
    let label: String
    let callback: (String)->()
    @Binding var selectedID : String
    let size: CGFloat
    let color: Color
    let textSize: CGFloat

    init(
        _ id: String,
        label: String,
        callback: @escaping (String)->(),
        selectedID: Binding<String>,
        size: CGFloat = 22,
        color: Color = Color.primary,
        textSize: CGFloat = 14
        ) {
        self.id = id
        self.label = label
        self.size = size
        self.color = color
        self.textSize = textSize
        self._selectedID = selectedID
        self.callback = callback
    }

    var body: some View {
        Button(action:{
            self.callback(self.id)
        }) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: self.selectedID == self.id ? "largecircle.fill.circle" : "circle")
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: self.size, height: self.size)
                    .foregroundColor(.blue)
                Text(id)
                    .bold()
                    .font(Font.system(size: 15))
                    .lineLimit(2)
                    .lineSpacing(1)
                    .frame(width: 100)
                //label
                Text(label)
                    .font(Font.system(size: textSize))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    
                Spacer()
            }.foregroundColor(self.color)
                .padding(.horizontal)
        }
        .foregroundColor(self.color)
    }
}

struct RadioButtonGroup: View {

    let items : [String]
    let labels : [String]

    @Binding var selectedId: String

    let callback: (String) -> ()

    var body: some View {
        HStack {
            ForEach(0..<items.count) { index in
                RadioButton(self.items[index],label: self.labels[index], callback: self.radioGroupCallback, selectedID: self.$selectedId)
                    .frame(maxHeight: 65)
                    .background(index % 2 == 0 ? .white : .blue.opacity(0.2))
      
                    .cornerRadius(9)
                    .padding(.bottom, 12)

            }
        }
    }

    func radioGroupCallback(id: String) {
        selectedId = id
        callback(id)
    }
}

struct RCRadioButtons: View {
    @State private var selected: String = "3"
    var body: some View {
        VStack{
            RadioButtonGroup(items: ["1","2","3","4"],
                             labels: ["","","",""],
                             selectedId: $selected) { selected in
                self.selected = selected
            }
        }
    }
}

#Preview {
    RCRadioButtons()
}
