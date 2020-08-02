//
//  Message+Bitfinex.swift
//  Swifty Quant
//
//  Created by Cameron de Bruyn on 2020/08/02.
//  Copyright © 2020 HINTON AI (PTY) LTD. All rights reserved.
//

import Network

private let requestKey = "bitfinex_request"
private let responseHeaderKey = "bitfinex_response_header"

extension NWProtocolFramer.Message
{
    convenience init(bitfinexRequest request: BitfinexRequest)
    {
        self.init(definition: BitfinexProtocol.definition)
        self[requestKey] = request
    }
    
    convenience init(bitfinexResponseHeader header: BitfinexResponseHeader)
    {
        self.init(definition: BitfinexProtocol.definition)
        self[responseHeaderKey] = header
    }
    
    var bitfinexRequest: BitfinexRequest?
    {
        self[requestKey] as? BitfinexRequest
    }
    
    var bitfinexResponseHeader: BitfinexResponseHeader?
    {
        self[responseHeaderKey] as? BitfinexResponseHeader
    }
    
}
