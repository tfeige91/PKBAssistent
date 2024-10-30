//
//  TipView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 26.07.23.
//

import SwiftUI

struct Highlight: Identifiable, Equatable {
    let id = UUID()
    var anchor : Anchor<CGRect>
    let title: String
    let cornerRadius: CGFloat
    let style: RoundedCornerStyle
    let scale: CGFloat
}


