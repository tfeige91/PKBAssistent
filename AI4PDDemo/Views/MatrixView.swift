//
//  MatrixView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 25.09.23.
//

import SwiftUI
import WebKit

struct MatrixViewRepresentable: UIViewRepresentable {
    
    
    func makeUIView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        
        let url = URL(string: "https://matrix.tu-dresden.de/#/home")!
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
}

struct MatrixView: View {
    var body: some View {
        MatrixViewRepresentable()
    }
}

struct MatrixView_Previews: PreviewProvider {
    static var previews: some View {
        MatrixView()
    }
}
