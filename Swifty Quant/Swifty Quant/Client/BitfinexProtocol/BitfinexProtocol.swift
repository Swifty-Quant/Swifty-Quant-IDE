//
//  BitfinexProtocol.swift
//  Swifty Quant
//
//  Created by Cameron de Bruyn on 2020/08/01.
//  Copyright © 2020 HINTON AI (PTY) LTD. All rights reserved.
//

import Foundation
import Network


class BitfinexProtocol : NWProtocolFramerImplementation
{
    static let definition = NWProtocolFramer.Definition(implementation: BitfinexProtocol.self)
    
    static var label: String { return "Bitfinex" }

    private var tempStatusCode: BitfinexResponseHeader.StatusCode?
    private var tempMeta:       String?
    
    required init(framer: NWProtocolFramer.Instance) { }
    
    func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult
    {
        return .ready
    }
    
    func wakeup(framer: NWProtocolFramer.Instance) { }
    
    func stop(framer: NWProtocolFramer.Instance) -> Bool
    {
        return true
    }
    
    func cleanup(framer: NWProtocolFramer.Instance) { }

    func handleInput(framer: NWProtocolFramer.Instance) -> Int
    {
        if tempStatusCode == nil
        {
            _ = framer.parseInput(minimumIncompleteLength: 3, maximumLength: 3)
            {
                (buffer, isComplete) -> Int in
                
                guard let buffer = buffer, buffer.count == 3 else { return 0 }

                self.tempStatusCode = BitfinexResponseHeader.StatusCode(buffer)
                
                return 3
            }
        }
        
        guard let statusCode = tempStatusCode
            else
        {
            return 3
        }
        
        var attemptedMetaLength: Int?
        if tempMeta == nil
        {
            // Minimum length is 2 bytes, spec does not say meta string is required
            _ = framer.parseInput(minimumIncompleteLength: 2, maximumLength: 1024 + 2)
            {
                (buffer, isComplete) -> Int in
                
                guard let buffer = buffer, buffer.count >= 2 else { return 0 }
                
                attemptedMetaLength = buffer.count
                
                let lastPossibleCRIndex = buffer.index(before: buffer.index(before: buffer.endIndex))
                
                var index = buffer.startIndex
                var found = false
                
                while index <= lastPossibleCRIndex
                {
                    // <CR><LF>
                    if buffer[index] == 13 && buffer[buffer.index(after: index)] == 10 {
                        found = true
                        break
                    }
                    index = buffer.index(after: index)
                }
                
                if !found {
                    if buffer.count < 1026 {
                        return 0
                    } else {
                        fatalError("Didn't find <CR><LF> in buffer. Meta string was longer than 1024 bytes")
                    }
                }
                
                self.tempMeta = String(bytes: buffer[..<index], encoding: .utf8)
                return buffer.startIndex.distance(to: index) + 2
            }
        }
        
        guard let meta = tempMeta
            else
        {
            if let attempted = attemptedMetaLength
            {
                return attempted + 1
            }
            else
            {
                return 2
            }
        }
        
        let header = BitfinexResponseHeader(status: statusCode, meta: meta)
        
        let message = NWProtocolFramer.Message(bitfinexResponseHeader: header)
        while true
        {
            if !framer.deliverInputNoCopy(length: .max, message: message, isComplete: true)
            {
                return 0
            }
        }
    }
    
    func handleOutput(
        framer:        NWProtocolFramer.Instance,
        message:       NWProtocolFramer.Message,
        messageLength: Int,
        isComplete:    Bool
    ) {
        guard let request = message.apiKey
            else
        {
            preconditionFailure("BitfinexProtocol can't send message that doesn't have an associated BitfinexRequest API key")
        }
        framer.writeOutput(data: request.data)
    }
	
}
