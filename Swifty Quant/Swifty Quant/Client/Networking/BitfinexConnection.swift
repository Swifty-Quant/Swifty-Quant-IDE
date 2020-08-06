//
//  BitfinexConnection.swift
//  Swifty Quant
//
//  Created by Cameron de Bruyn on 2020/07/29.
//  Copyright © 2020 HINTON AI (PTY) LTD. All rights reserved.
//

import Foundation
import Network
import CryptoKit


class BitfinexConnection : NSObject, WebSocketConnection, URLSessionWebSocketDelegate
{
    weak var delegate: WebSocketConnectionDelegate?
    
    var webSocketTask: URLSessionWebSocketTask!
    var urlSession:    URLSession!
    
    let delegateQueue = OperationQueue()
    
    private var pingTimer: Timer?
    
    init(url: URL, autoConnect: Bool = false)
    {
        super.init()
        
        urlSession    = URLSession(configuration: .default, delegate: self, delegateQueue: delegateQueue)
        webSocketTask = urlSession.webSocketTask(with: url)
        
        if autoConnect
        {
            connect()
        }
    }
    
    func urlSession(
        _ session:                    URLSession,
        webSocketTask:                URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        delegate?.onConnected(connection: self)
    }
    
    func urlSession(
        _ session:              URLSession,
        webSocketTask:          URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason:                 Data?
    ) {
        delegate?.onDisconnected(connection: self, error: nil)
    }
    
    func connect()
    {
        webSocketTask.resume()
        try? initiateWebSocket()
        listen()
    }
    
    internal func initiateWebSocket() throws
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
    
        let authNonce   = NonceProvider.sharedInstanse.nonce
        let authPayload = "AUTH\(authNonce)"
        
        let authenticationKey  = SymmetricKey(data: apiSecret.data(using: .ascii)!)
        let authenticationCode = HMAC<SHA384>.authenticationCode(for: authPayload.data(using: .ascii)!,
                                                                 using: authenticationKey
        )
        
        let authSig = authenticationCode.compactMap { String(format: "%02hhx", $0) }.joined()
        
        let payload: [String : Any] =
        [
            "event":       "auth",
            "apiKey" :     apiKey,
            "authSig":     authSig,
            "authPayload": authPayload,
            "authNonce":   authNonce
        ]

        let data = try JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed)
        
        send(data: data)
    }
    
    func send(text: String)
    {
        let textMessage = URLSessionWebSocketTask.Message.string(text)
        
        webSocketTask.send(textMessage)
        {
            [weak self] error in
            
            guard let self = self else { return }
            
            if let error = error
            {
                self.delegate?.onError(connection: self, error: error)
            }
        }
    }
    
    func send(data: Data)
    {
        let dataMessage = URLSessionWebSocketTask.Message.data(data)
        
        webSocketTask.send(dataMessage)
        {
            [weak self] error in
            
            guard let self = self else { return }
            
            if let error = error
            {
                self.delegate?.onError(connection: self, error: error)
            }
        }
    }
    
    func listen()
    {
        webSocketTask.receive
        {
            [weak self] result in
            
            guard let self = self else { return }
            
            switch result
            {
            case .failure(let error):
                self.delegate?.onError(connection: self, error: error)
            
            case .success(let message):
                switch message
                {
                case .string(let text):
                    self.delegate?.onMessage(connection: self, text: text)
                
                case .data(let data):
                    self.delegate?.onMessage(connection: self, data: data)
                
                @unknown default:
                    fatalError()
                }
            }
            self.listen()
        }
    }
    
    func ping(with frequency: TimeInterval = 25.0)
    {
        pingTimer = Timer.scheduledTimer(withTimeInterval: frequency, repeats: true)
        {
            [weak self] _ in
            
            guard let self = self else { return }
            
            self.webSocketTask.sendPing
            {
                error in
                
                if let error = error
                {
                    self.delegate?.onError(connection: self, error: error)
                }
            }
        }
    }
    
    func disconnect()
    {
        webSocketTask.cancel(with: .normalClosure, reason: nil)
        pingTimer?.invalidate()
    }
}
