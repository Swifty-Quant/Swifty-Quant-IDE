//
//  WebSocketConnection.swift
//  Swifty Quant
//
//  Created by Cameron de Bruyn on 2020/08/06.
//  Copyright © 2020 HINTON AI (PTY) LTD. All rights reserved.
//

import Foundation


protocol WebSocketConnection
{
    func connect()
    func send(text: String)
    func send(data: Data)
    func listen()
    func ping(with: TimeInterval)
    func disconnect()
    
    var delegate: WebSocketConnectionDelegate? { get set }
}

protocol WebSocketConnectionDelegate : class
{
    func onConnected(connection: WebSocketConnection)
    func onDisconnected(connection: WebSocketConnection, error: Error?)
    func onError(connection: WebSocketConnection,        error: Error)
    func onMessage(connection: WebSocketConnection,      text: String)
    func onMessage(connection: WebSocketConnection,      data: Data)
}

extension WebSocketConnectionDelegate
{
    func onMessage(connection: WebSocketConnection, text: String) { }
    func onMessage(connection: WebSocketConnection, data: Data)   { }
}
