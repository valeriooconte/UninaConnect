//
//  ChatView.swift
//  UninaConnect
//
//  Created by Valerio Domenico Conte on 14/07/23.
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var cm: ChatManager
    @State private var messageText = ""

    var body: some View {
        VStack {
            List(cm.messages, id: \.id) { message in
                MessageView(message: message)
            }
            
            HStack {
                TextField("Messaggio", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button {
                    sendMessage()
                } label: {
                    Text("Invia")
                }
            }
            .padding()
        }
        .navigationTitle("Messaggi")
    }
    
    func sendMessage() {
        if cm.newPeer != nil && !messageText.isEmpty {
            cm.send(messageText: messageText)
            messageText = ""
        }
    }
}

struct MessageView: View {
    var message: Message
    
    var body: some View {
        HStack {
            if message.isSentByCurrentUser {
                Spacer()
            }
            
            Text(message.text)
                .padding(10)
                .background(message.isSentByCurrentUser ? CustomColor.uninaColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            
            if !message.isSentByCurrentUser {
                Spacer()
            }
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static let cm = ChatManager()
    static var previews: some View {
        ChatView(cm: cm)
    }
}
