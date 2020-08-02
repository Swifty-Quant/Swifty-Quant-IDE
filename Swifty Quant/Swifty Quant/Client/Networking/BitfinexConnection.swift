//
//  BitfinexConnection.swift
//  Swifty Quant
//
//  Created by Cameron de Bruyn on 2020/07/29.
//  Copyright © 2020 HINTON AI (PTY) LTD. All rights reserved.
//

import Foundation
import Network


protocol BitfinexConnectionDelegate : class
{
    func connectionReady()
    func connectionFailed()
    func receivedMessage(content: Data?, message: NWProtocolFramer.Message)
    func displayAdvertiseError(_ error: NWError)
}

class BitfinexConnection
{
    weak var delegate: BitfinexConnectionDelegate?
    
    private let queue = DispatchQueue(label: "ai.hinton.bitfinex.networkstream", attributes: [])
    
    var connection:          NWConnection?
    var initiatedConnection: Bool
    
    /**
        Initializes a new BitfinexConnection when the user supplies their API Key and Secret Key.

        - parameter endpoint:  The endpoint of the channel
        - parameter interface: The interface that this channel is relevant to
        - parameter passcode:  A passcode the user enters to secure the Bitfinex API key.

        - returns: A new BitfinexConnection instance
    */
    init(delegate: BitfinexConnectionDelegate)
    {
        self.delegate            = delegate
        self.initiatedConnection = false

        let host = "api.bitfinex.com"
        
        let options = NWProtocolTCP.Options()
        options.connectionTimeout = 15
        
        let tlsOptions = NWProtocolTLS.Options()
        sec_protocol_options_set_verify_block(
            tlsOptions.securityProtocolOptions,
            {
                (sec_protocol_metadata, sec_trust, sec_protocol_verify_complete) in
                
                let trust = sec_trust_copy_ref(sec_trust).takeRetainedValue()
                
                let pinner = FoundationSecurity()
                
                pinner.evaluateTrust(trust: trust, domain: host, completion:
                {
                    (state) in
                    
                    switch state
                    {
                    case .success:
                        sec_protocol_verify_complete(true)
                    case .failed(_):
                        sec_protocol_verify_complete(false)
                    }
                })
            }, queue
        )
        
        let endpoint = NWEndpoint.hostPort(host: "api.bitfinex.com", port: 443)
        
        let parameters = NWParameters(tls: tlsOptions, tcp: options)
        let conn = NWConnection(to: endpoint, using: parameters)
        self.connection = conn
        
        startConnection()
    }
    
    // Handle an inbound connection when the user receives a game request.
    init(connection: NWConnection, delegate: BitfinexConnectionDelegate)
    {
        self.delegate            = delegate
        self.connection          = connection
        self.initiatedConnection = false

        startConnection()
    }

    /**
        Handle starting the peer-to-peer connection for outbound(client) connections.

        - returns: A new BitfinexConnection instance
    */
    func startConnection()
    {
        guard let connection = connection
            else
        {
            return
        }

        connection.stateUpdateHandler = { newState in
            switch newState
            {
            case .setup:
                print("setup")
            case .ready:
                print("\(connection) established")
                
                if !self.initiatedConnection
                {
                    self.initiatedConnection = true
                }
                
                // When the connection is ready, start receiving messages.
                self.receiveNextMessage()

                // Notify your delegate that the connection is ready.
                if let delegate = self.delegate
                {
                    delegate.connectionReady()
                }
                
            case .failed(let error):
                print("\(connection) failed with \(error)")

                // Cancel the connection upon a failure.
                connection.cancel()

                // Notify your delegate that the connection failed.
                if let delegate = self.delegate
                {
                    delegate.connectionFailed()
                }
            default:
                break
            }
        }
        
        connection.start(queue: .main)
    }

    // Receive a message, deliver it to your delegate, and continue receiving more messages.
    func receiveNextMessage()
    {
        guard let connection = connection
            else
        {
            return
        }

        connection.receiveMessage
        {
            (content, context, isComplete, error) in
            
            if let content = content,
                let message = String(data: content, encoding: .utf8),
                let delegate = self.delegate
            {
                delegate.receivedMessage(content: content,
                                         message: message)
            }
            
            if error == nil
            {
                // Continue to receive more messages until you receive and error.
                self.receiveNextMessage()
            }
        }
    }

}
