//
//  RCTestStickyHeader.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 01.11.23.
//

import SwiftUI

struct FramePreference: PreferenceKey {
    static var defaultValue: [Namespace.ID:CGRect] = [:]
    
    static func reduce(value: inout [Namespace.ID:CGRect], nextValue: () -> [Namespace.ID:CGRect]) {
        value.merge(nextValue()) {$1}
    }
}

enum StickyRects: EnvironmentKey {
    static var defaultValue: [Namespace.ID : CGRect] = [:]
}

extension EnvironmentValues {
    var stickyRects: [Namespace.ID : CGRect] {
        get {self[StickyRects.self]}
        set {self[StickyRects.self] = newValue }
    }
}

struct Sticky: ViewModifier {
    @Environment(\.stickyRects ) var stickyRects: [Namespace.ID:CGRect]
    @State var frame: CGRect = .zero
    @Namespace private var id
    var isSticking: Bool {
        frame.minY < 0
    }
    var offset: CGFloat {
        guard isSticking else {return 0}
        var o = -frame.minY
        if let other = stickyRects.first(where: {(key,value) in
            value.minY > frame.minY && value.minY < frame.height && key != id}){

            o -= frame.height - other.value.minY
        }
        return o
        
    }
    func body(content: Content) -> some View {
        content
            .zIndex(isSticking ? .infinity : 1)
            .offset(y: offset)
            .overlay(GeometryReader {geo in
                let f = geo.frame(in: .named("container"))
                Color.clear
                    .onAppear{frame = f}
                    .onChange(of: f){frame = $0}
                    .preference(key: FramePreference.self, value: [id:frame] )
            })
    }
}

struct UseStickyHeaders: ViewModifier {
    @State private var frames: [Namespace.ID : CGRect] = [:]
    func body(content: Content) -> some View {
        content
            .onPreferenceChange(FramePreference.self, perform: { 
                frames = $0
            })
            .coordinateSpace(name: "container")
            .environment(\.stickyRects,frames)
    }
    
    
}

extension View {
    func useStickyHeaders() -> some View {
        modifier(UseStickyHeaders())
    }
}

extension View{
    func sticky() -> some View {
        modifier(Sticky())
    }
}

