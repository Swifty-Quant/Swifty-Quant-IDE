//
//  NonceProvider.swift
//  Swifty Quant
//
//  Created by Cameron de Bruyn on 2020/07/30.
//  Copyright © 2020 HINTON AI (PTY) LTD. All rights reserved.
//

import Foundation


internal class NonceProvider
{
    static let sharedInstanse = NonceProvider()
    
    var timestamp: Int
    
    internal var nonce: String
    {
        get
        {
            return "\(self.timestamp += 1)"
        }
    }
    
    init()
    {
        var x = timeval()
        gettimeofday(&x, nil)
            
        let seconds: Int = x.tv_sec
        let millis: Int32 = x.tv_usec
            
        self.timestamp = Int("\(seconds)\(millis)000")!
    }
}
