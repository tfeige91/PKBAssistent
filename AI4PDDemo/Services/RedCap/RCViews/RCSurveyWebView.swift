//
//  RCSurveyWebView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 08.01.25.
//

import SwiftUI
import WebKit

struct RCSurveyWebView: View {
    let url: URL
    var body: some View {
        RCSurveyWebViewRepresentable(url: url)
    }
}

struct RCSurveyWebViewRepresentable: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator

        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        webView.customUserAgent =
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }

    final class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {

        // JavaScript pro Navigation erlauben
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     preferences: WKWebpagePreferences,
                     decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {

            preferences.allowsContentJavaScript = true
            decisionHandler(.allow, preferences)
        }

        // target="_blank" im gleichen WebView laden
        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let js = """
            (function() {
              window.open = function(u){ location.href = u; };
              Array.from(document.forms).forEach(f => f.setAttribute('target','_self'));
            })();
            """
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}
