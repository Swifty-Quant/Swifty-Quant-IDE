//
//  BitfinexSecurity.swift
//  Swifty Quant
//
//  Created by Cameron de Bruyn on 2020/07/30.
//  Copyright © 2020 HINTON AI (PTY) LTD. All rights reserved.
//

import Foundation


public enum FoundationSecurityError: Error
{
    case invalidRequest
}

public class FoundationSecurity
{
    var allowSelfSigned = false
    
    public init(allowSelfSigned: Bool = false)
    {
        self.allowSelfSigned = allowSelfSigned
    }
}

extension FoundationSecurity: CertificatePinning
{
    public func evaluateTrust(trust: SecTrust, domain: String?, completion: ((PinningState) -> ()))
    {
        if allowSelfSigned
        {
            completion(.success)
            return
        }
        
        if let validateDomain = domain
        {
            SecTrustSetPolicies(trust, SecPolicyCreateSSL(true, validateDomain as NSString?))
        }
        
        handleSecurityTrust(trust: trust, completion: completion)
    }
    
    private func handleSecurityTrust(trust: SecTrust, completion: ((PinningState) -> ()))
    {
        if #available(iOS 12.0, OSX 10.14, watchOS 5.0, tvOS 12.0, *)
        {
            var error: CFError?
            if SecTrustEvaluateWithError(trust, &error)
            {
                completion(.success)
            }
            else
            {
                completion(.failed(error))
            }
        }
        else
        {
            handleOldSecurityTrust(trust: trust, completion: completion)
        }
    }
    
    private func handleOldSecurityTrust(trust: SecTrust, completion: ((PinningState) -> ()))
    {
        var result: SecTrustResultType = .unspecified
        SecTrustEvaluate(trust, &result)
    
        if result == .unspecified || result == .proceed
        {
            completion(.success)
        }
        else
        {
            let e = CFErrorCreate(kCFAllocatorDefault, "FoundationSecurityError" as NSString?, Int(result.rawValue), nil)
            completion(.failed(e))
        }
    }
}
