//
//  NewsView.swift
//  NewsReader
//
//  Created by Stephen Cunningham on 21/06/2020.
//  Copyright © 2020 Cunningham Hall Consultancy. All rights reserved.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let request: URLRequest
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(request)
    }
    
}

struct NewsView: View {
    
    let url: String
    
    var body: some View {
        WebView(request: URLRequest(url: URL(string:url)!))
    }
}

struct NewsView_Previews: PreviewProvider {
    static var previews: some View {
        NewsView(url: "https://codemag.com/Magazine")
    }
}
