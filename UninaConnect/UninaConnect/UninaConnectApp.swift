//
//  UninaConnectApp.swift
//  UninaConnect
//
//  Created by Valerio Domenico Conte on 14/07/23.
//

import SwiftUI

@main
struct UninaConnectApp: App {
    
    let chatManager = ChatManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView(cm: chatManager)
        }
    }
}
