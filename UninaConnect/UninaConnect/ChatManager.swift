//
//  ChatManager.swift
//  UninaConnect
//
//  Created by Valerio Domenico Conte on 14/07/23.
//

import MultipeerConnectivity

class ChatManager: NSObject, ObservableObject {
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiser: MCNearbyServiceAdvertiser!
    var mcBrowser: MCNearbyServiceBrowser!
    
    @Published var isAdvertising = false
    
    @Published var foundPeers: [MCPeerID] = []
    @Published var newPeer: MCPeerID!

    @Published var messages: [Message] = []
    @Published var documents: [ChatDocument] = []
    
    override init() {
        super.init()
        
        //Inizializza "peerID" con il valore relativo al dispositivo utente
        peerID = MCPeerID(displayName: UIDevice.current.name)
        
        //Inizializza l'oggetto session e delega la sua gestione alla classe ChatManager
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        
        //Inizializza l'oggetto advertiser per il servizio "peer-chat" e delega la sua gestione alla classe ChatManager
        mcAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "peer-chat")
        mcAdvertiser.delegate = self
        
        //Inizializza l'oggetto browser per il servizio "peer-chat" e delega la sua gestione alla classe ChatManager
        mcBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: "peer-chat")
        mcBrowser.delegate = self
    }
    
    //Funzione per avviare l'annuncio della sessione
    func startAdvertising() {
        isAdvertising = true
        mcAdvertiser.startAdvertisingPeer()
    }
    
    //Funzione per terminare l'annuncio della sessione
    func stopAdvertising() {
        isAdvertising = false
        mcAdvertiser.stopAdvertisingPeer()
    }
    
    //Funzione per avviare la scoperta di sessioni
    func startBrowsing() {
        isAdvertising = false
        mcBrowser.startBrowsingForPeers()
    }
    
    //Funzione per terminare la scoperta di sessioni
    func stopBrowsing() {
        foundPeers.removeAll()
        mcBrowser.stopBrowsingForPeers()
    }
    
    //Funzione per gestire gli inviti che l'oggetto advertiser ricceve
    func handleConnection(from peer: MCPeerID) {
        newPeer = peer
        stopAdvertising()
    }
    
    //Funzione utilizzata dall'oggetto browser per invitare un peer a connettersi
    func connectToPeer(_ peer: MCPeerID) {
        mcBrowser.invitePeer(peer, to: mcSession, withContext: nil, timeout: 10)
        newPeer = peer
        stopBrowsing()
    }
    
    //Funzione per l'invio di messaggi di testo
    func send(messageText: String) {
        if let data = messageText.data(using: .utf8) {
            do {
                try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
                let message = Message(text: messageText, isSentByCurrentUser: true)
                messages.append(message)
            } catch {
                print("Errore nell'invio del messaggio: \(error)")
            }
        }
    }
    
    //Funzione per gestire la ricezione di messaggi di testo
    func receive(messageData: Data) {
        let messageText = String(data: messageData, encoding: .utf8)
        let message = Message(text: messageText!, isSentByCurrentUser: false)
        self.messages.append(message)
    }
    
    //Funzione per l'invio di documenti
    func sendDocument(fileURL: URL) {
        do {
            let fileData = try Data(contentsOf: fileURL)
            let fileName = fileURL.lastPathComponent
            let chatDocument = ChatDocument(fileName: fileName, fileData: fileData, fileURL: fileURL, isSentByCurrentUser: true)
            let documentData = try JSONEncoder().encode(chatDocument)
            try mcSession.send(documentData, toPeers: mcSession.connectedPeers, with: .reliable)
            documents.append(chatDocument)
        } catch {
            print("Errore nell'invio del documento: \(error)")
        }
    }
    
    //Funzione per gestire la ricezione di documenti
    func receiveDocument(documentData: Data) {
        do {
            var chatDocument = try JSONDecoder().decode(ChatDocument.self, from: documentData)
            chatDocument.isSentByCurrentUser = false
            documents.append(chatDocument)
        } catch {
            print("Errore nella ricezione del documento: \(error)")
        }
    }
}

//Implementazione del protocollo MCSessionDelegate
extension ChatManager: MCSessionDelegate {
    //Funzione che stabilisce le azioni da intraprendere al variare dello stato di connessione di un peer
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("\(peerID) stato: connesso")
        case .connecting:
            print("\(peerID) stato: in connessione")
        case .notConnected:
            print("\(peerID) stato: non connesso")
        @unknown default:
            print("\(peerID) stato: sconosciuto")
        }
    }
    
    //Funzione che stabilisce le operazioni da effettuare a seconda di ciò che viene ricevuto (messaggio di testo o documento)
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    
        if let chatDocument = try? JSONDecoder().decode(ChatDocument.self, from: data) {
            print(chatDocument.fileName)
            DispatchQueue.main.async {
                self.receiveDocument(documentData: data)
            }
        } else if let messageText = String(data: data, encoding: .utf8) {
            print(messageText)
            DispatchQueue.main.async {
                self.receive(messageData: data)
            }
        }
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
}

//Implementazione del protocollo MCNearbyServiceAdvertiserDelegate
extension ChatManager: MCNearbyServiceAdvertiserDelegate {
    //Funzione che gestisce le operazioni da effettuare alla ricezione di un invito
    //In tal caso, è impostata in modo tale che gli inviti ricevuti vengano sempre accettati
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        handleConnection(from: peerID)
        invitationHandler(true, mcSession)
    }
}

//Implementazione del protocollo MCNearbyServiceBrowserDelegate
extension ChatManager: MCNearbyServiceBrowserDelegate {
    //Funzione che gestisce la scoperta di un peer annunciante una sessione
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        foundPeers.append(peerID)
    }
    
    //Funzione che gestisce la perdita di un peer annunciante una sessione precedentemente scoperto dall'oggetto browser
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        if let index = foundPeers.firstIndex(of: peerID) {
            foundPeers.remove(at: index)
        }
    }
}

struct Message: Identifiable {
    var id = UUID()
    var text: String
    var isSentByCurrentUser: Bool
}

struct ChatDocument: Identifiable, Encodable, Decodable {
    var id = UUID()
    var fileName: String
    var fileData: Data
    var fileURL: URL
    var isSentByCurrentUser: Bool
}

