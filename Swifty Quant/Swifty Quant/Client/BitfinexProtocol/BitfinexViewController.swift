//
//  BitfinexViewController.swift
//  Swifty Quant
//
//  Created by Cameron de Bruyn on 2020/07/29.
//  Copyright © 2020 HINTON AI (PTY) LTD. All rights reserved.
//

import AppKit
import SwiftUI
import Network
import CryptoKit

    
extension BitfinexViewController : BitfinexConnectionDelegate
{
    internal func prepareWebSocket() throws -> Data
    {
        let dir = try? FileManager.default.url(for: .sharedPublicDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true
        )
        
        var apiKey    = ""
        var apiSecret = ""
        
        if let fileUrl = dir?.appendingPathComponent("").appendingPathExtension("bitfinex")
        {
            guard FileManager.default.fileExists(atPath: fileUrl.path)
                else
            {
                preconditionFailure("File expected at \(fileUrl.absoluteString) is missing")
            }

            guard let filePointer: UnsafeMutablePointer<FILE> = fopen(fileUrl.path, "r")
                else
            {
                preconditionFailure("Could not open file at \(fileUrl.absoluteString)")
            }

            var lineByteArrayPointer: UnsafeMutablePointer<CChar>? = nil
            var lineCap: Int = 0

            getline(&lineByteArrayPointer, &lineCap, filePointer)
            apiKey = String(String(cString:lineByteArrayPointer!).dropLast())
            
            getline(&lineByteArrayPointer, &lineCap, filePointer)
            apiSecret = String(String(cString:lineByteArrayPointer!).dropLast())
            
            fclose(filePointer)
        }
    
        let authNonce = NonceProvider.sharedInstanse.nonce
        let authPayload = "AUTH\(authNonce)"
        
        let authenticationKey  = SymmetricKey(data: apiSecret.data(using: .ascii)!)
        let authenticationCode = HMAC<SHA384>.authenticationCode(for: authPayload.data(using: .ascii)!,
                                                                 using: authenticationKey
        )
        
        let authSig = authenticationCode.compactMap { String(format: "%02h", $0) }.joined()
        
        let payload: [String : Any] =
        [
            "event":       "auth",
            "apiKey" :     apiKey,
            "authSig":     authSig,
            "authPayload": authPayload,
            "authNonce":   authNonce
        ]

        return try JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed)
    }
    
    func connectionReady()
    {
        guard let url = URL(string: "wss://api.bitfinex.com/ws/2") else { return }
        
        socketConnection = URLSession.shared.webSocketTask(with: url)
        socketConnection?.resume()
                
        if let data = try? self.prepareWebSocket()
        {
            let message = URLSessionWebSocketTask.Message.data(data)
            
            socketConnection?.send(message)
            {
                error in
                
                print("ERROR: \(error?.localizedDescription)")"
            }
        }
    }
    
    func connectionFailed()
    {
        print("Connection Failed")
    }
    
    func receivedMessage(content: Data?, message: NWProtocolFramer.Message)
    {
        print(message)
    }
    
    func displayAdvertiseError(_ error: NWError)
    {
        self.presentError(error)
    }
    
}

final class BitfinexViewController : NSViewController
{
    var socketConnection: URLSessionWebSocketTask?
    
    override func viewDidLoad()
    {   
        BitfinexShared.connection = BitfinexConnection(delegate: self)
    }
    
    override func loadView()
    {
        var arrayWithObjects: NSArray?
        let nibIsLoaded = Bundle.main.loadNibNamed(NSNib.Name("BitfinexButtonView"),
                                                   owner: self,
                                                   topLevelObjects: &arrayWithObjects)

        if nibIsLoaded
        {
            view = arrayWithObjects?.first(where: { $0 is NSView }) as! NSView
        }
        return
    }
}

extension BitfinexViewController : NSViewControllerRepresentable
{
    func makeNSViewController(context: Context) -> NSViewController
    {
        return BitfinexViewController()
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context)
    {
        
    }
}
