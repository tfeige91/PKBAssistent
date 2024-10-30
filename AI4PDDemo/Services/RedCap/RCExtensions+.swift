//
//  RCExtensions+.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 02.11.23.
//

import SwiftUI

//apply ViewModifiers programatically
extension View {
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            return AnyView(transform(self))
        } else {
            return AnyView(self)
        }
    }
}

extension Array where Element == RCField {
    func isStartOfNewMatrixGroup(at index: Int) -> Bool {
            guard index < self.count, let matrixGroupName = self[index].matrixGroupName, !matrixGroupName.isEmpty else {
                return false
            }
            return index == 0 || self[index - 1].matrixGroupName != matrixGroupName
        }
}
