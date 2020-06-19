//
//  ContentView.swift
//  HelloSwiftUI
//
//  Created by Stephen Cunningham on 12/06/2020.
//  Copyright © 2020 Cunningham Hall Consultancy. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State private var text = ""
    var body: some View {
        VStack{
            Button(action:{
                self.text = "Hello, SwiftUI!"
                
            }){
                Text("Button")
                    .padding(EdgeInsets(
                        top:10, leading: 10,
                        bottom: 10, trailing: 10)).foregroundColor(.red)
                
            }
            TextField("", text: $text)
                .multilineTextAlignment(TextAlignment.center)
            .padding(15)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(Color.black)
                .font(.custom("AppleSDGothicNeoBold", size: 20.0))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray, lineWidth: 2))
                .padding(.leading ,10)
                .padding(.trailing, 10)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
