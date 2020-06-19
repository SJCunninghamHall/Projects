//
//  ContentView.swift
//  NewsReader
//
//  Created by Stephen Cunningham on 16/06/2020.
//  Copyright © 2020 Cunningham Hall Consultancy. All rights reserved.
//

import SwiftUI

struct Result: Codable {
    var articles: [Article]
}

struct Article: Codable {
    var url: String
    var title: String
    var description: String?
    var urlToImage: String?
}

struct ContentView: View {
    
    private let url = "http://newsapi.org/v2/top-headlines?country=us&apiKey=69cef9c1922f4442a8435323915c5f22"
    // private let url = "https://www.apple.com"
    
        @State private var articles = [Article]()
    
    func fetchData() {
        guard let url = URL(string: url) else {
            print("URL is not valid")
            return
        }
        
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request)
        {
            data, response, error in
            if let data = data {
                if let decodedResult = try?
                    JSONDecoder().decode(Result.self, from: data) {
                    // Decoding is successful
                    DispatchQueue.main.async {
                        self.articles = decodedResult.articles
                    }
                    return
                }
            }

            print("Error: \(error?.localizedDescription ?? "Unknown error")")
            
        }.resume()
    }
    
    var body: some View {
        
        List(articles, id: \.url)
        { item in
            VStack(alignment: .leading)
            {
                Text(item.title).font(.headline)
                Text(item.description ?? "").font(.footnote)
            }
        }.onAppear(perform: fetchData)
            
        }
        
    }


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
