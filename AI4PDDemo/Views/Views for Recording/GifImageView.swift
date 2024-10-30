//
//  GifImageView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 25.07.23.
//

import SwiftUI
import WebKit

struct GifImageView: UIViewRepresentable {
    
    let source: String
    
    init(_ source: String){
        self.source = source
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        guard let url = Bundle.main.url(forResource: source, withExtension: "gif") else {print("no valid URL"); return webView}
        guard let data = try? Data(contentsOf: url) else {
            print("data not valid")
            return webView
        }
        
        webView.load(data, mimeType: "image/gif", characterEncodingName: "UTF-8", baseURL: url)
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.backgroundColor = UIColor.clear
        
        return webView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        print("WebView updated")
    }
    
}

struct GifImageView_Previews: PreviewProvider {
    static var previews: some View {
        GifImageView("test")
    }
}
