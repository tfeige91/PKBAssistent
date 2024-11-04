//
//  TipViewHelper.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 26.07.23.
//

import SwiftUI

extension View {
    @ViewBuilder
    func showCase(order: Int, title: String, cornerRadius: CGFloat, style: RoundedCornerStyle = .continuous,scale: CGFloat) -> some View {
        self
            .anchorPreference(key: HighlightAnchorKey.self, value: .bounds) { anchor in
                let highlight = Highlight(anchor: anchor, title: title, cornerRadius: cornerRadius,style: style, scale: scale)
                return [order: highlight]
            }
    }
}

//Showcase Root
struct ShowCaseRoot: ViewModifier {
    @Binding var showHighlights: Bool
    var onFinished: () -> ()
    
    //View Properties
    @State private var highlightOrder: [Int] = []
    @Binding var currentHighlight: Int 
    @State private var showView:Bool = true
    
    @Namespace private var animation
    
    func body(content: Content) -> some View {
        content
            .onPreferenceChange(HighlightAnchorKey.self) { value in
                highlightOrder = Array(value.keys).sorted()
            }
            .overlayPreferenceValue(HighlightAnchorKey.self) { preferences in
                if highlightOrder.indices.contains(currentHighlight),showHighlights,showView {
                    if let highlight = preferences[highlightOrder[currentHighlight]]{
                        HighlightView(highlight)
                    }
                }
            }
    }
    
    @ViewBuilder
    func HighlightView(_ highlight: Highlight) -> some View {
        GeometryReader {proxy in
            let highlightRect = proxy[highlight.anchor]
            let safeArea = proxy.safeAreaInsets
            
            Rectangle()
                .fill(.black.opacity(0.5))
                .reverseMask {
                    Rectangle()
                        .frame(width: highlightRect.width, height: highlightRect.height)
                        .clipShape(RoundedRectangle(cornerRadius: highlight.cornerRadius,style: highlight.style))
                        .scaleEffect(highlight.scale)
                        .offset(x: highlightRect.minX, y: highlightRect.minY + safeArea.top)
                }
                .ignoresSafeArea()
                .onTapGesture {
                    if currentHighlight >= highlightOrder.count-1{
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showHighlights = false
                            
                            print("DEBUG: \(currentHighlight)")
                        }
                    }else{
                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.7)) {
                            if currentHighlight != -1 && currentHighlight <= highlightOrder.count-1{
                                currentHighlight += 1
                            }
                            
                        }
                    }
                }
                
    
        }
    }
}

//Masking the Views
extension View {
    @ViewBuilder
    func reverseMask<Content: View>(@ViewBuilder content: @escaping () -> Content)-> some View {
        self
            .mask{
                Rectangle()
                    .overlay(alignment: .topLeading) {
                        content()
                            .blendMode(.destinationOut)
                    }
            }
    }
}

struct TipView_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
            .environmentObject(SpeechRecognizer())
    }
}

//Anchor Key
struct HighlightAnchorKey: PreferenceKey {
    static var defaultValue: [Int: Highlight] = [:]
    
    static func reduce(value: inout [Int : Highlight], nextValue: () -> [Int : Highlight]) {
        //merge with the newValue and keep the new ($1)
        value.merge(nextValue()){$1}
    }
    
}
