//
//  ContentView.swift
//  UninaConnect
//
//  Created by Valerio Domenico Conte on 02/09/23.
//

import SwiftUI
import MultipeerConnectivity

struct CustomColor {
    static let uninaColor = Color("unina_color")
}

struct ContentView: View {
    @ObservedObject var cm: ChatManager
    @State private var showSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                
                ZStack {
                    Image("unina_logo")
                        .resizable()
                        .scaledToFit()
                }
                .frame(width: 180)
                .padding(32)
                
                if !cm.isAdvertising {
                    Button {
                        cm.startAdvertising()
                    } label: {
                        ButtonView(text: "Annuncia una sessione")
                    }
                } else {
                    Button {
                        cm.stopAdvertising()
                    } label: {
                        ButtonView(text: "Interrompi annuncio")
                    }
                }
                
                
                Button {
                    cm.startBrowsing()
                    showSheet = true
                } label: {
                    ButtonView(text: "Cerca una sessione")
                }.sheet(isPresented: $showSheet) {
                    SheetView(cm: cm)
                }
                
                if let peer = cm.newPeer {
                    
                    Text("Connesso a \(peer.displayName)")
                        .foregroundColor(CustomColor.uninaColor)
                    
                    
                    HStack {
                        NavigationLink {
                            ChatView(cm: cm)
                        } label: {
                            OptionView(text: "Messaggi", icon: "message.fill")
                        }
                        
                        NavigationLink {
                            DocumentChatView(cm: cm)
                        } label: {
                            OptionView(text: "Documenti", icon: "doc.fill")
                        }
                    }
                    
                }
                
                
            }
            .navigationTitle("UninaConnect")
        }
    }
}

struct SheetView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var cm: ChatManager
    
    var body: some View {
        
        VStack {
            
            if cm.foundPeers.isEmpty {
                Text("In attesa di scoprire una sessione...")
            } else {
                List(cm.foundPeers, id: \.self) { peer in
                    Button {
                        cm.connectToPeer(peer)
                        dismiss()
                    } label: {
                        Text("Connetti a \(peer.displayName)")
                    }
                }
            }
            
            Button {
                cm.stopBrowsing()
                dismiss()
            } label: {
                Text("Annulla")
            }
        }
        
    }
}

struct ButtonView: View {
    var text: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(CustomColor.uninaColor)
            
            Text(text)
                .foregroundColor(.white)
        }
        .frame(width: 240, height: 60)
        .padding(8)
    }
}

struct OptionView: View {
    var text: String
    var icon: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(CustomColor.uninaColor)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                
                Text(text)
                    .foregroundColor(.white)
            }
            
        }
        .frame(width: 128, height: 60)
        .padding(4)
    }
}

struct ContentView_Previews: PreviewProvider {
    static let chatManager = ChatManager()
    
    static var previews: some View {
        ContentView(cm: chatManager)
    }
}
